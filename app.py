from flask import Flask, jsonify, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import datetime
import logging
import pytz
import time
import psutil
import requests
from google.cloud import monitoring_v3

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Setup rate limiting
limiter = Limiter(key_func=get_remote_address)
limiter.init_app(app)

nigeria_tz = pytz.timezone("Africa/Lagos")

# Initialize Google Cloud Monitoring client
client = monitoring_v3.MetricServiceClient()


def get_gcp_metric(metric_type, minutes=5):
    project_id = os.environ.get("GCP_PROJECT_ID", "time-api-gke-project-434215")
    project_name = f"projects/{project_id}"

    now = time.time()
    seconds = int(now)
    nanos = int((now - seconds) * 10**9)
    interval = monitoring_v3.TimeInterval(
        {
            "end_time": {"seconds": seconds, "nanos": nanos},
            "start_time": {"seconds": (seconds - minutes * 60), "nanos": nanos},
        }
    )

    try:
        results = client.list_time_series(
            request={
                "name": project_name,
                "filter": f'metric.type = "{metric_type}"',
                "interval": interval,
                "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
            }
        )

        values = [
            point.value.double_value for result in results for point in result.points
        ]
        if values:
            return sum(values) / len(values)  # Return average
        else:
            logger.warning(f"No data points found for metric: {metric_type}")
            return None
    except Exception as e:
        logger.error(f"Error fetching metric {metric_type}: {str(e)}")
        return None


@app.route("/time", methods=["GET"])
@limiter.limit("20 per minute")
def get_current_time():
    start_time = time.time()
    try:
        current_time = datetime.datetime.now(nigeria_tz)
        formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S %Z%z")

        response = {
            "current_time": formatted_time,
            "email": "chuqunonso@gmail.com",
            "timezone": str(current_time.tzinfo),
            "day_of_week": current_time.strftime("%A"),
            "week_number": current_time.isocalendar()[1],
            "is_dst": current_time.dst() != datetime.timedelta(0),
        }

        logger.info(f"Time requested. Returning: {response}")
        return jsonify(response), 200
    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        return (
            jsonify({"error": "An error occurred while processing your request"}),
            500,
        )
    finally:
        logger.info(f"Request processed in {time.time() - start_time:.4f} seconds")


@app.route("/health", methods=["GET"])
def health_check():
    health_status = {
        "status": "healthy",
        "timestamp": datetime.datetime.now(nigeria_tz).isoformat(),
        "local_metrics": {
            "cpu_usage": psutil.cpu_percent(),
            "memory_usage": psutil.virtual_memory().percent,
            "disk_usage": psutil.disk_usage("/").percent,
        },
        "gcp_metrics": {},
    }

    # Check GCP metrics
    gcp_metrics = [
        ("kubernetes.io/container/cpu/allocatable_utilization", "cpu_utilization"),
        ("kubernetes.io/container/memory/used_bytes", "memory_usage_bytes"),
        (
            "kubernetes.io/container/network/received_bytes_count",
            "network_ingress_bytes_per_second",
        ),
        (
            "kubernetes.io/container/network/sent_bytes_count",
            "network_egress_bytes_per_second",
        ),
        ("kubernetes.io/container/request_count", "requests_per_minute"),
        ("kubernetes.io/container/uptime", "uptime_hours"),
    ]

    for metric_type, metric_name in gcp_metrics:
        value = get_gcp_metric(metric_type)
        if value is not None:
            if metric_name in [
                "network_ingress_bytes_per_second",
                "network_egress_bytes_per_second",
            ]:
                value /= 300  # Convert to per second
            elif metric_name == "requests_per_minute":
                value *= 12  # Convert to per minute
            elif metric_name == "uptime_hours":
                value /= 3600  # Convert to hours
            health_status["gcp_metrics"][metric_name] = value
        else:
            health_status["gcp_metrics"][metric_name] = "N/A"

    # Perform a self-check by calling the /time endpoint
    try:
        response = requests.get("http://localhost:8080/time")
        if response.status_code == 200:
            health_status["time_endpoint_check"] = "passed"
        else:
            health_status["time_endpoint_check"] = (
                f"failed (status code: {response.status_code})"
            )
            health_status["status"] = "unhealthy"
    except requests.RequestException as e:
        health_status["time_endpoint_check"] = f"failed (error: {str(e)})"
        health_status["status"] = "unhealthy"

    return jsonify(health_status), 200 if health_status["status"] == "healthy" else 503


@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify(error="Rate limit exceeded", description=str(e.description)), 429


@app.before_request
def log_request_info():
    logger.info(f"Request: {request.method} {request.url}")


@app.after_request
def log_response_info(response):
    logger.info(f"Response: {response.status}")
    return response


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

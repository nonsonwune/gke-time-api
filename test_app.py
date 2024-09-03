import unittest
import json
import datetime
from unittest.mock import patch, MagicMock
from app import app, limiter
import pytz
import requests
import time


class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.api_url = "http://34.69.20.46/time"
        self.nigeria_tz = pytz.timezone("Africa/Lagos")
        self.reset_limiter()

    def reset_limiter(self):
        limiter.reset()

    def test_get_time_local(self):
        response = self.client.get("/time")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn("current_time", data)
        self.assertIn("email", data)
        self.assertIn("timezone", data)
        self.assertIn("day_of_week", data)
        self.assertIn("week_number", data)
        self.assertIn("is_dst", data)
        self.assertEqual(data["email"], "chuqunonso@gmail.com")
        self.assertEqual(data["timezone"], "Africa/Lagos")
        try:
            datetime.datetime.strptime(data["current_time"], "%Y-%m-%d %H:%M:%S %Z%z")
        except ValueError:
            self.fail("Time is not in the expected format.")

    def test_time_is_current_local(self):
        before_request = datetime.datetime.now(self.nigeria_tz)
        response = self.client.get("/time")
        after_request = datetime.datetime.now(self.nigeria_tz)

        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        returned_time_str = data["current_time"]

        # Parse the returned time string
        returned_time = datetime.datetime.strptime(
            returned_time_str, "%Y-%m-%d %H:%M:%S %Z%z"
        )

        # Convert all times to UTC for comparison
        before_request_utc = before_request.astimezone(pytz.UTC)
        after_request_utc = after_request.astimezone(pytz.UTC)
        returned_time_utc = returned_time.astimezone(pytz.UTC)

        # Allow for a 2-second window to account for any delays
        self.assertGreaterEqual(
            returned_time_utc, before_request_utc - datetime.timedelta(seconds=2)
        )
        self.assertLessEqual(
            returned_time_utc, after_request_utc + datetime.timedelta(seconds=2)
        )

    @patch("requests.get")
    def test_get_time_deployed(self, mock_get):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "current_time": "2024-09-02 12:00:00 WAT+0100",
            "email": "chuqunonso@gmail.com",
            "timezone": "Africa/Lagos",
            "day_of_week": "Monday",
            "week_number": 36,
            "is_dst": False,
        }
        mock_get.return_value = mock_response

        response = requests.get(self.api_url)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("current_time", data)
        self.assertIn("email", data)
        self.assertIn("timezone", data)
        self.assertIn("day_of_week", data)
        self.assertIn("week_number", data)
        self.assertIn("is_dst", data)
        self.assertEqual(data["email"], "chuqunonso@gmail.com")
        self.assertEqual(data["timezone"], "Africa/Lagos")
        try:
            datetime.datetime.strptime(data["current_time"], "%Y-%m-%d %H:%M:%S %Z%z")
        except ValueError:
            self.fail("Time is not in the expected format")

    @patch("requests.get")
    def test_api_accessibility(self, mock_get):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response

        response = requests.get(self.api_url)
        self.assertEqual(response.status_code, 200)

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    @patch("app.get_gcp_metric")
    @patch("requests.get")
    def test_health_check(
        self, mock_get, mock_gcp_metric, mock_disk, mock_memory, mock_cpu
    ):
        mock_cpu.return_value = 50.0
        mock_memory.return_value.percent = 60.0
        mock_disk.return_value.percent = 70.0
        mock_gcp_metric.side_effect = [0.4, 1000000, 1000, 2000, 100, 3600]

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response

        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)

        self.assertIn("status", data)
        self.assertIn("timestamp", data)
        self.assertIn("local_metrics", data)
        self.assertIn("gcp_metrics", data)
        self.assertIn("time_endpoint_check", data)

        local_metrics = data["local_metrics"]
        self.assertIn("cpu_usage", local_metrics)
        self.assertIn("memory_usage", local_metrics)
        self.assertIn("disk_usage", local_metrics)

        gcp_metrics = data["gcp_metrics"]
        for metric in [
            "cpu_utilization",
            "memory_usage_bytes",
            "network_ingress_bytes_per_second",
            "network_egress_bytes_per_second",
            "requests_per_minute",
            "uptime_hours",
        ]:
            self.assertIn(metric, gcp_metrics)
            self.assertTrue(
                isinstance(gcp_metrics[metric], (float, int))
                or gcp_metrics[metric] == "N/A"
            )

        self.assertEqual(data["status"], "healthy")
        self.assertEqual(local_metrics["cpu_usage"], 50.0)
        self.assertEqual(local_metrics["memory_usage"], 60.0)
        self.assertEqual(local_metrics["disk_usage"], 70.0)
        self.assertEqual(data["time_endpoint_check"], "passed")

    def test_rate_limiting(self):
        for _ in range(10):
            response = self.client.get("/time")
            self.assertEqual(response.status_code, 200)

        # The 11th request should be rate limited
        response = self.client.get("/time")
        self.assertEqual(response.status_code, 429)
        data = json.loads(response.data)
        self.assertIn("error", data)
        self.assertEqual(data["error"], "Rate limit exceeded")

    @patch("app.datetime")
    def test_error_handling(self, mock_datetime):
        mock_datetime.datetime.now.side_effect = Exception("Test error")
        response = self.client.get("/time")
        self.assertEqual(response.status_code, 500)
        data = json.loads(response.data)
        self.assertIn("error", data)
        self.assertEqual(
            data["error"], "An error occurred while processing your request"
        )


if __name__ == "__main__":
    unittest.main()

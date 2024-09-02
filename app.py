from flask import Flask, jsonify
import datetime
import logging
import pytz

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

nigeria_tz = pytz.timezone("Africa/Lagos")


@app.route("/time", methods=["GET"])
def get_current_time():
    current_time = datetime.datetime.now(nigeria_tz)
    app.logger.info(f"Time requested. Returning: {current_time}")
    return jsonify(
        {
            "current_time": current_time.isoformat(),
            "email": "chuqunonso@gmail.com",
            "timezone": str(current_time.tzinfo),
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

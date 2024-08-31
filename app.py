from flask import Flask, jsonify
import datetime
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)


@app.route("/time", methods=["GET"])
def get_current_time():
    current_time = datetime.datetime.now().isoformat()
    app.logger.info(f"Time requested. Returning: {current_time}")
    return jsonify({"current_time": current_time})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

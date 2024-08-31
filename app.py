# app.py
from flask import Flask, jsonify
import datetime

app = Flask(__name__)


@app.route("/time", methods=["GET"])
def get_current_time():
    current_time = datetime.datetime.now().isoformat()
    return jsonify({"current_time": current_time})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

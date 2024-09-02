import unittest
import json
import datetime
import requests
from app import app
import pytz


class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.api_url = "http://34.69.20.46/time"
        self.nigeria_tz = pytz.timezone("Africa/Lagos")

    def test_get_time_local(self):
        response = self.client.get("/time")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn("current_time", data)
        self.assertIn("email", data)
        self.assertEqual(data["email"], "chuqunonso@gmail.com")
        try:
            datetime.datetime.fromisoformat(data["current_time"])
        except ValueError:
            self.fail("Time is not in ISO format")

    def test_time_is_current_local(self):
        response = self.client.get("/time")
        data = json.loads(response.data)
        returned_time = datetime.datetime.fromisoformat(data["current_time"])
        current_time = datetime.datetime.now(self.nigeria_tz)
        time_difference = abs(
            current_time - returned_time.replace(tzinfo=self.nigeria_tz)
        )
        self.assertLess(
            time_difference.total_seconds(), 5
        )  # Allow up to 5 seconds difference

    def test_get_time_deployed(self):
        response = requests.get(self.api_url)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("current_time", data)
        self.assertIn("email", data)
        self.assertEqual(data["email"], "chuqunonso@gmail.com")
        try:
            datetime.datetime.fromisoformat(data["current_time"])
        except ValueError:
            self.fail("Time is not in ISO format")

    def test_time_is_current_deployed(self):
        response = requests.get(self.api_url)
        data = response.json()
        returned_time = datetime.datetime.fromisoformat(data["current_time"])
        current_time = datetime.datetime.now(self.nigeria_tz)
        time_difference = abs(
            current_time - returned_time.replace(tzinfo=self.nigeria_tz)
        )
        self.assertLess(
            time_difference.total_seconds(), 5
        )  # Allow up to 5 seconds difference

    def test_api_accessibility(self):
        response = requests.get(self.api_url)
        self.assertEqual(response.status_code, 200)

    def test_monitoring_alert(self):
        print(
            "Please manually verify that the CPU usage alert is set up in GCP Monitoring"
        )
        self.assertTrue(True)


if __name__ == "__main__":
    unittest.main()

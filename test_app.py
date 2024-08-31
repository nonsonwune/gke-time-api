import unittest
import json
import datetime
from app import app


class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_get_time(self):
        response = self.client.get("/time")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn("current_time", data)
        # Check if the returned time is in ISO format
        try:
            datetime.datetime.fromisoformat(data["current_time"])
        except ValueError:
            self.fail("Time is not in ISO format")

    def test_time_is_current(self):
        response = self.client.get("/time")
        data = json.loads(response.data)
        returned_time = datetime.datetime.fromisoformat(data["current_time"])
        current_time = datetime.datetime.now()
        time_difference = current_time - returned_time
        self.assertLess(
            time_difference.total_seconds(), 1
        )  # Ensure time difference is less than 1 second


if __name__ == "__main__":
    unittest.main()

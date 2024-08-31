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


if __name__ == "__main__":
    unittest.main()

import unittest
from unittest.mock import MagicMock

class StatsTestCase(unittest.TestCase):
    def setUp(self):
        # Set up the necessary mocks and test data
        self.request = MagicMock()
        self.request.form = {'username': 'testuser'}
        self.cursor = MagicMock()
        self.cursor.fetchall.return_value = [('jpg', 10), ('png', 5)]
        self.cursor.execute.side_effect = [
            None, None, None, None, None, None, None, None, None, None
        ]
        self.shutil = MagicMock()
        self.shutil.disk_usage.return_value = (100, 50, 50)

    def test_stats(self):
        # Import the function to be tested
        from app import stats

        # Set up the necessary dependencies
        stats.request = self.request
        stats.cursor = self.cursor
        stats.shutil = self.shutil

        # Call the function
        result = stats()

        # Assert the expected output
        expected_result = {
            "asset_counts": [('jpg', 10), ('png', 5)],
            "yearly_counts": [],
            "top_albums": [],
            "top_locations": [],
        }
        self.assertEqual(result, expected_result)

        # Assert that the necessary methods were called
        self.cursor.execute.assert_called_with("SELECT format, COUNT(*) AS count FROM assets GROUP BY format")
        self.cursor.fetchall.assert_called()
        self.shutil.disk_usage.assert_called_with('/path/to/storage')

if __name__ == '__main__':
    unittest.main()
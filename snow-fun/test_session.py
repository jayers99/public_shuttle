import unittest
import os
import requests
from unittest.mock import patch
from snow_fun.session import login_to_servicenow

class TestServiceNowLogin(unittest.TestCase):

    @patch.dict(os.environ, {
        'SERVICENOW_INSTANCE_URL': 'https://yourinstance.service-now.com',
        'SERVICENOW_USERNAME': 'username',
        'SERVICENOW_PASSWORD': 'password'
    })
    @patch('requests.Session.post')
    def test_login_successful(self, mock_post):
        # Arrange
        mock_response = requests.Response()
        mock_response.status_code = 200
        mock_post.return_value = mock_response

        # Act
        session = login_to_servicenow()

        # Assert
        self.assertIsInstance(session, requests.Session)
        self.assertEqual(session.auth.username, 'username')
        self.assertEqual(session.auth.password, 'password')

    @patch.dict(os.environ, {
        'SERVICENOW_INSTANCE_URL': 'https://yourinstance.service-now.com',
        'SERVICENOW_USERNAME': 'username',
        'SERVICENOW_PASSWORD': 'password'
    })
    @patch('requests.Session.post')
    def test_login_failed(self, mock_post):
        # Arrange
        mock_response = requests.Response()
        mock_response.status_code = 401
        mock_post.return_value = mock_response

        # Act/Assert
        with self.assertRaises(ValueError):
            login_to_servicenow()

    @patch.dict(os.environ, {})
    def test_missing_env_vars(self):
        # Act/Assert
        with self.assertRaises(ValueError):
            login_to_servicenow()

if __name__ == '__main__':
    unittest.main()

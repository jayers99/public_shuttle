import os
import requests
from requests.auth import HTTPBasicAuth

def login_to_servicenow():
    instance_url = os.getenv('SERVICENOW_INSTANCE_URL')
    username = os.getenv('SERVICENOW_USERNAME')
    password = os.getenv('SERVICENOW_PASSWORD')

    if not instance_url or not username or not password:
        raise ValueError("Missing required environment variables: SERVICENOW_INSTANCE_URL, SERVICENOW_USERNAME, SERVICENOW_PASSWORD")

    session = requests.Session()
    session.auth = HTTPBasicAuth(username, password)
    
    response = session.post(f'{instance_url}/api/now/v2/table/incident')  # Example endpoint

    if response.status_code == 200:
        return session
    else:
        raise ValueError("Login failed with status code: {}".format(response.status_code))

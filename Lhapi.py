from datetime import datetime, timedelta
import json
import os
import requests


class Lhapi:

    lh_api_url = "https://api.lufthansa.com/v1"

    def __init__(self):
        self.token = Lhapi.get_token()
        # self.uri = uri
        # self.output_file = output_file

    

    @classmethod
    def get_token(cls):
        """
        Class method used to retrieve authentication token and check its validity.
        Source: https://developer.lufthansa.com/docs/read/api_basics/Getting_Started
        """
        access_path = "config/lh_api_access.json"

        # Check if file exists
        if not os.path.exists(access_path):
            print(f"{access_path} not found, check it")
            return
        # Check if file is not empty
        try:
            with open(access_path, 'r') as access:
                auth_data = json.load(access)
        except json.JSONDecodeError:
            print(f"{access_path} looks empty, check it")
            return

        # Check if token expired
        date_now = datetime.now().replace(microsecond=0)
        if auth_data:
            expiration_date = auth_data.get('token', {}).get('expiration_date')
            if expiration_date:
                expiration_date = datetime.strptime(expiration_date, "%Y-%m-%d %H:%M:%S")
            else:
                expiration_date = datetime.min
            if date_now < expiration_date:
                return

        # If token does not exists or expired, create a new one
        headers = {'content-type': 'application/x-www-form-urlencoded'}
        payload = {
            'client_id': auth_data['ID'],
            'client_secret': auth_data['secret'],
            'grant_type': 'client_credentials'
        }
        req = requests.post(f'{cls.lh_api_url}/oauth/token', headers=headers, data=payload)
        if req.status_code == 200:
            req = req.json()
            auth_data['token'] = {
                'value': req['access_token'],
                'expiration_date': (date_now + timedelta(seconds=req['expires_in'])).strftime("%Y-%m-%d %H:%M:%S")
            }
            with open(access_path, 'w') as access:
                json.dump(auth_data, access, indent=2)
        else:
            print(f"Error when requesting token: {req.status_code}")
        



    def request_api(self, uri):
        """
        Execute request and get json object
        return data as json
        """
        url = self.lh_api_url + uri
        headers = {"Authorization: Bearer " + self.token}
        timeout = 60
        try:
            req = requests.get(url, headers=headers, timeout=timeout)
            if req.status_code == 200:
                # logger.info(f"{req.status_code} {url}")
                return json.dumps(req.json(), indent=2)
            else:
                print(f"{req.status_code} {url}")
                # logger.error(f"{req.status_code} {url}")
                # logger.error(f"{req.text}")
        except Exception as e:
                # logger.error(f"Error when reaching {url} : {e}")
                print(f"Error when reaching {url} : {e}")
        return

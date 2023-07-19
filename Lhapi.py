from datetime import datetime, timedelta
import json
import logging
import os
import requests



# Initiate logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')

file_handler = logging.handlers.TimedRotatingFileHandler('logs/lh_requests.log', when='midnight', interval=1, backupCount=7)
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


class Lhapi:

    lh_api_url = "https://api.lufthansa.com/"

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
            logger.error(f"{access_path} not found, check it")
            return
        # Check if file is not empty
        try:
            with open(access_path, 'r') as access:
                auth_data = json.load(access)
        except json.JSONDecodeError:
            logging.error(f"{access_path} looks empty, check it")
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
                return auth_data.get('token').get('value')

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
            logging.error(f"Error when requesting token: {req.status_code}")
        
        return auth_data['token']['value']
        



    def request_api(self, api_version, uri, limit=100):
        """
        Execute request and get json object
        return data as json
        """
        url = f"{self.lh_api_url}{api_version}{uri}?limit={limit}"
        headers = {"Authorization": "Bearer " + self.token}
        timeout = 60
        try:
            req = requests.get(url, headers=headers, timeout=timeout)
            if req.status_code == 200:
                logger.info(f"{req.status_code} {url}")
                return json.dumps(req.json(), indent=2)
            else:
                logger.error(f"{req.status_code} {url}")
                logger.error(f"{req.text}")
        except Exception as e:
                logger.error(f"Error when reaching {url} : {e}")
        return

    def request_file(self, filename, api_version, uri, limit=100):
        """
        Call request_api
        Execute request and get json object
        Create a json file in files folder
        """
        content = self.request_api(api_version, uri, limit)
        with open("files/" + filename, 'w') as file:
            file.write(content)
    

    # def get_partner_token(self):
    #     access_path = "config/lh_api_access.json"
    #     try:
    #         with open(access_path, 'r') as access:
    #             auth_data = json.load(access)
    #     except json.JSONDecodeError:
    #         logging.error(f"{access_path} looks empty, check it")
    #         return
        
    #     headers = {'content-type': 'application/x-www-form-urlencoded'}
    #     payload = {
    #         'client_id': auth_data['ID'],
    #         'client_secret': auth_data['secret'],
    #         'grant_type': 'client_credentials'
    #     }

    #     url = f'{self.lh_api_url}v1/partners/oauth/token'
    #     req = requests.post(url, headers=headers, data=payload)

    #     if req.status_code == 200:
    #         req = req.json()
    #         print(req)
    #     else:
    #         logging.error(f"Error when requesting token: {req.status_code} {url}")

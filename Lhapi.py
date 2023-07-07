import requests
import json

class Lhapi:

    lh_api_url = "https://api.lufthansa.com/v1"

    @classmethod
    def get_token(cls):
        """
        Class method use to retrieve authentication token and check its validity
        source: https://developer.lufthansa.com/docs/read/api_basics/Getting_Started
        """
        with open("config/lh_api_access.json", r) as access:
            auth_data = json.load(access)
        
        # If token does not exist, as one
        if not auth_data['token']:
            headers = {'content-type': 'application/x-www-form-urlencoded'}
            payload = {'client_id': auth_data['ID'], 'client_secret': auth_data['secret'], 'grant_type': 'client_credentials'}
            req = requests.post(f'{cls.lh_api_url}/oauth/token', headers=headers, data=payload)
        return
    
    def __init__(self):
        pass
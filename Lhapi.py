from datetime import datetime, timedelta
import json
import logging
import os
import re
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
    access_path = "config/lh_api_access.json"

    def __init__(self):
        self.config = self.get_access_file()
        # self.token = self.__get_token()
        # self.proxies = self.__get_proxies()



    def read_access_file(self):
        # Check if file exists
        if not os.path.exists(Lhapi.access_path):
            logger.error(f"{Lhapi.access_path} not found, check it")
            return
        # Check if file is not empty
        try:
            with open(Lhapi.access_path, 'r') as access:
                data = json.load(access)
        except json.JSONDecodeError:
            logging.error(f"{Lhapi.access_path} looks empty, check it")
            return
        else:
            return data
    

    def get_access_file(self):
        conf = self.read_access_file()
        conf = self.get_proxies(conf)
        conf = self.get_token(conf)
        with open(Lhapi.access_path, 'w') as conf_file:
            json.dump(conf, conf_file, indent=2)
        return self.read_access_file()

        

    def get_proxies(self, conf):
        if "proxies" not in conf:
            conf['proxies'] = {"http": "", "https": ""}
        return conf



    def get_token(self, conf):
        """
        Private method used to retrieve authentication token and check its validity.
        Source: https://developer.lufthansa.com/docs/read/api_basics/Getting_Started
        """
        # Check if token expired
        date_now = datetime.now().replace(microsecond=0)
        if 'token' in conf:
            expiration_date = conf.get('token', {}).get('expiration_date')
            if expiration_date:
                expiration_date = datetime.strptime(expiration_date, "%Y-%m-%d %H:%M:%S")
            else:
                expiration_date = datetime.min
            if date_now < expiration_date:
                logger.info("Date du token OK")
                # return auth_data.get('token').get('value')
                return conf
            else:
                logger.info("Date du token NOOK")

        # If token does not exists or expired, create a new one
        headers = {'content-type': 'application/x-www-form-urlencoded'}
        payload = {
            'client_id': conf['ID'],
            'client_secret': conf['secret'],
            'grant_type': 'client_credentials'
        }
        url = f'{Lhapi.lh_api_url}v1/oauth/token'
        req = requests.post(url, headers=headers, data=payload, proxies=conf['proxies'])
        if req.status_code == 200:
            logger.info(f"token request 200 {url}")
            req = req.json()
            conf['token'] = {
                'value': req['access_token'],
                'expiration_date': (date_now + timedelta(seconds=req['expires_in'])).strftime("%Y-%m-%d %H:%M:%S")
            }
        else:
            logging.error(f"Error when requesting token: {req.status_code} {url}")
        #return self.config['token']['value']
        return conf



    def request_api(self, api_version, uri):
        """
        Execute request and get json object
        return data as json
        """
        # Jour avec les liens "@Href" lorsque "@Rel": "next" existe et concaténer le résultat (option full)
        # url = f"{self.lh_api_url}{api_version}{uri}?limit={limit}"
        # next = True
        # while next:
        url = f"{self.lh_api_url}{api_version}{uri}"
        headers = {"Authorization": "Bearer " + self.config['token']['value']}
        timeout = 60
        try:
            req = requests.get(url, headers=headers, timeout=timeout, proxies=self.config['proxies'])
            if req.status_code == 200:
                logger.info(f"{req.status_code} {url}")
                return json.dumps(req.json(), indent=2)
            else:
                logger.error(f"{req.status_code} {url}")
                logger.error(f"{req.text}")
        except Exception as e:
                logger.error(f"Error when reaching {url} : {e}")
        return



    # pattern = r'"@Href": "([^"]+)",\s+"@Rel": "next"'



    def request_file(self, filename, api_version, uri, element_name, full=False, count=None):
        """
        Call request_api
        Execute request and get json object
        Create a json file in files folder
        """
        # Attention il semble que l'offset génère 1 doublon à chaque fois
        while True:
            content = self.request_api(api_version, uri)

            with open("files/" + filename, 'w') as file:
                file.write(content)

            next_link = None
            pattern = r'{"@Href":.*,"@Rel":"next"}'
            match = re.search(pattern, content)
            if match:
                res = '[' + match.group() +']'
                res = json.loads(res)
                for meta in res:
                    if meta["@Rel"] == "next":
                        next_link = meta['@Href']
            if full and next_link:
                uri = next_link.split(Lhapi.lh_api_url + api_version)[-1]
                self.request_file(filename, api_version, uri, element_name, full=False)

            else:
                break

    

    # def get_partner_token(self):
    #     Lhapi.access_path = "config/lh_api_access.json"
    #     try:
    #         with open(Lhapi.access_path, 'r') as access:
    #             auth_data = json.load(access)
    #     except json.JSONDecodeError:
    #         logging.error(f"{Lhapi.access_path} looks empty, check it")
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

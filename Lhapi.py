from datetime import datetime, timedelta
import json
import logging
import os
import re
import requests
import time



# Initiate logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
logs_dir = 'logs'
if not os.path.exists(logs_dir):
    os.mkdir(logs_dir)
file_handler = logging.handlers.TimedRotatingFileHandler(os.path.join(logs_dir, 'lh_requests.log'), when='midnight', interval=1, backupCount=7)
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
                logger.info("Token validity OK")
                # return auth_data.get('token').get('value')
                return conf
            else:
                logger.warning("DToken validity NOOK")

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


    def request_api(self, url, retry=0):
        """
        Execute request and get json object
        return data as json
        """
        headers = {"Authorization": "Bearer " + self.config['token']['value']}
        timeout = 60
        try:
            req = requests.get(url, headers=headers, timeout=timeout, proxies=self.config['proxies'])
            req.raise_for_status()
            logger.info(f"{req.status_code} {url}")
        except Exception as e:
                logger.error(f"Error when reaching {url} : {e}")
                logger.error(f"{req.status_code} {url}")
                logger.error(f"{req.text}")
                # to counter: The service being accessed is overloaded. Restricted access only
                if retry <= 6:
                    time.sleep(10)
                    retry += 1
                else:
                    if "flightstatus" in url and req.status_code == 404:
                        return
                    raise Exception(f"Error {req.status_code} when requesting {url} with {retry} retries")
                return self.request_api(url, retry)
        else:
            return json.dumps(req.json(), indent=2)
        finally:
            time.sleep(1)
        return


    def gen_dates_range(self, start_date, end_date):
        start_date = datetime.strptime(start_date, "%d%b%y")
        end_date = datetime.strptime(end_date, "%d%b%y")

        date_range = []
 
        # Génération des dates entre les deux dates en entrées
        while start_date <= end_date:
            date_range.append(start_date.strftime('%d%b%y').upper())
            start_date += timedelta(days=1)
        return date_range


    def get_meta(self, content):
        # Get data content as string
        # print(type(content))
        # content = json.dumps(content)
        pattern = re.compile(r'"Meta":.*"Link":.*\].*?\}', re.DOTALL)
        meta = re.findall(pattern, content)
        # Transform string result in json
        if meta:
            meta = meta[0]
            meta = json.loads('{' + meta + '}')
        return meta
    

    def get_next_link(self, meta):
        next_link = None
        if meta:
            for item in meta['Meta']['Link']:
                if item['@Rel'] == 'next':
                    # Vous avez trouvé le dictionnaire avec '@Rel' égal à 'next'
                    next_link = item['@Href']
                    break
        return next_link

    

    def request_full_files(self, url, resource_name):
        # Attention il semble que l'offset génère 1 doublon à chaque fois, à vérifier
        request_counter = 1
        req_date = datetime.now().date().strftime("%Y-%m-%d")

        while url:
            content = self.request_api(url)
            filename = f"{req_date}_{resource_name}_{request_counter}.json"
            self.write_file(content, filename)
            url = self.get_next_link(self.get_meta(content))
            request_counter += 1

        return


    def request_file(self, url, filename):
        """
        Call request_api
        Execute request and get json object
        Create a json file in files folder
        """
        content = self.request_api(url)
        self.write_file(content, filename)

        return
    

    def write_file(self, content, filename):
        try:
            with open("files/" + filename, 'w') as file:
                file.write(content)
            return
        except TypeError:
            print("TypeError: Empty content")

    

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

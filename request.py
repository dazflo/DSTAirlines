import requests
import json
import logging
import sys
sys.path.append('config')
import lh_access as API




# Initiate logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')

file_handler = logging.handlers.TimedRotatingFileHandler('logs/lh_requests.log', when='midnight', interval=1, backupCount=7)
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


headers = {"Authorization": API.BEARER}
timeout = 60


def get(url):
    """
    Execute request and get json object
    return data as json variable
    """
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
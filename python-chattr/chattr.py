import requests
import json

url = "http://localhost:11434/api/generate"

headers = {
    "Content-Type": "application/json"
}

data = {'model': 'llama2', 'prompt' :'hello', 'stream': False}

response = requests.post(url, data = json.dumps(data), headers = headers)

response

json_resp = response.json()


json_resp.get("response")

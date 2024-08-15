import requests
import json
import sys

url = "http://localhost:11434/api/generate"

headers = {
    "Content-Type": "application/json"
}

data = {
    'model': 'llama2',
    'prompt' :'hello', 
    'stream': True
    }

response = requests.post(url, data = json.dumps(data), headers = headers)

for line in response.iter_lines():
    body = json.loads(line)
    sys.stdout.write(body.get("response"))

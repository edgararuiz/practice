import requests
import json
import sys

prompt = "what is the tallest mountain?"

url = "http://localhost:11434/api/generate"

headers = {
    "Content-Type": "application/json"
}

data = {
    'model': 'llama2',
    'prompt' : prompt, 
    'stream': True
    }

response = requests.post(url, data = json.dumps(data), headers = headers)

for line in response.iter_lines():
    body = json.loads(line)
    resp = body.get("response")
    sys.stdout.write(resp)
    


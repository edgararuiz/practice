import requests

url = "http://localhost:11434/api/generate"

req = {'model': 'llama2', 'prompt' :'hello', 'stream': 'false'}

req

response = requests.post(url, json = req)

response

response.json()

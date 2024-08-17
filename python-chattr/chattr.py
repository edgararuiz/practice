import requests
import json
import sys

def ch_submit_ollama(prompt, stream = True):
    url = "http://localhost:11434/api/chat"

    headers = {
        "Content-Type": "application/json"
    }

    data = {
        'model': 'llama2',
        'messages' :  [
            {
            "role": "user",
            "content": prompt
            }
        ], 
        'stream': stream
        }
    response = requests.post(url, data = json.dumps(data), headers = headers, stream = stream)
    for line in response.iter_lines():
        body = json.loads(line)
        resp = body.get("message")
        content = resp.get("content")
        sys.stdout.write(content)

def chattr(prompt, stream = True):
    return(ch_submit_ollama(prompt = prompt, stream = stream))

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--prompt", default = '')
parser.add_argument("--stream", type = bool, default = True)

args = parser.parse_args()

if args.prompt != '':
    chattr(args.prompt, args.stream)

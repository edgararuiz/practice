import requests
import json
import sys

def ch_submit_ollama(prompt, stream = True, history = [], preview = False):
    url = "http://localhost:11434/api/chat"

    headers = {
        "Content-Type": "application/json"
    }

    messages = []
    messages.append(dict(
        role =  "system", 
        content = "You are a helpful coding assistant that uses Python for data analysis. Keep comments to a."
        ))
    messages.append(dict(
        role =  "user", 
        content = prompt
        ))

    data = {
        'model': 'llama2',
        'messages' :  messages, 
        'stream': stream
        }

    if preview:    
        print(data)
        return()

    response = requests.post(url, data = json.dumps(data), headers = headers, stream = stream)
    for line in response.iter_lines():
        body = json.loads(line)
        resp = body.get("message")
        content = resp.get("content")
        sys.stdout.write(content)

def chattr(prompt, stream = True, history = [], preview = False):
    return(
        ch_submit_ollama(
            prompt = prompt, 
            stream = stream,
            history = history,
            preview = preview
            )
        )

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--prompt", default = '')
parser.add_argument("--stream", type = bool, default = True)

args = parser.parse_args()

if args.prompt != '':
    chattr(args.prompt, args.stream)

import subprocess
proc = subprocess.Popen(['python','python-chattr/chattr.py', "--prompt='hello'"],stdout=subprocess.PIPE)

times = 0
while True:
  out = proc.stdout.read(1)
  times = times + 1
  print(str(out.decode()))
  if not out:
    break

print(times)


item1 = {
      "role": "user",
      "content": "hello"
  }

d1 = dict(role = "user", content = "hello")
d2 = dict(role = "system", content = "helpful thing")
dall = []
dall
dall.append(d1)
dall.append(d2)
dall

str_dall = str(dall)
import json
x = json.dumps(str_dall)
x.__class__
json.load(str_dall)
json.loads(str_all)
eval(str_all)

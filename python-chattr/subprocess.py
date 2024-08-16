import subprocess
proc = subprocess.Popen(['python','python-chattr/chattr.py', "--prompt='hello'"],stdout=subprocess.PIPE)

while True:
  line = proc.stdout.read()
  print(line)
  if not line:
    break

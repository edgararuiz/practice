import subprocess
proc = subprocess.Popen(['python','python-chattr/chattr.py', "--prompt='hello'"],stdout=subprocess.PIPE)

times = 0
while True:
  line = proc.stdout.read(1)
  times = times + 1
  print(line)
  if not line:
    break

print(times)
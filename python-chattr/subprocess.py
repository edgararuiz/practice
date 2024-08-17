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



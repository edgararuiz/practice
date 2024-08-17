import chattr
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--prompt", default = '')
parser.add_argument("--stream", type = bool, default = True)

args = parser.parse_args()

if args.prompt != '':
    chattr(args.prompt, args.stream)

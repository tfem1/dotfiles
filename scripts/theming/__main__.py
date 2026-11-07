"""Entry point: python3 -m theming [options] (called by scripts/generate.sh)."""
import os
import sys

from .generate import main

try:
    code = main(sys.argv[1:])
    sys.stdout.flush()
except BrokenPipeError:
    # Output closed by the reader (e.g. `| head`): stop without a Python traceback.
    os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
    code = 1
sys.exit(code)

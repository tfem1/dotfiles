"""Point d'entrée : python3 -m theming [options] (appelé par scripts/generate.sh)."""
import os
import sys

from .generate import main

try:
    code = main(sys.argv[1:])
    sys.stdout.flush()
except BrokenPipeError:
    # Sortie coupée par le lecteur (ex. « | head ») : on s'arrête sans trace Python.
    os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
    code = 1
sys.exit(code)

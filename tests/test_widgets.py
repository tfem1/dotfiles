"""Desktop widgets: the cava config the audio widget ships, run with the real
cava when it is installed (fed a tone through a fifo, no sound server)."""
import contextlib
import math
import os
import shutil
import struct
import subprocess
import tempfile
import threading
import time
import unittest
from pathlib import Path

from helpers import REPO

CAVA = shutil.which("cava")


@unittest.skipUnless(CAVA, "cava not installed")
class CavaTest(unittest.TestCase):
    def test_the_shipped_config_gives_24_bars_from_0_to_100_per_line(self):
        with tempfile.TemporaryDirectory() as temp:
            fifo = Path(temp) / "audio.fifo"
            os.mkfifo(fifo)
            config = Path(temp) / "cava.conf"
            # The shipped config, with a fifo in place of the sound server.
            config.write_text((REPO / "quickshell/widgets/cava.conf").read_text()
                              + f"\n[input]\nmethod = fifo\nsource = {fifo}\n")

            def tone():   # 3 seconds of 440 Hz, in real time, until cava is stopped
                rate, step = 44100, 2205
                with contextlib.suppress(BrokenPipeError), fifo.open("wb") as out:
                    for start in range(0, 3 * rate, step):
                        out.write(b"".join(struct.pack("<hh", value, value) for value in (
                            int(12000 * math.sin(2 * math.pi * 440 * i / rate)) for i in range(start, start + step))))
                        out.flush()
                        time.sleep(step / rate)

            threading.Thread(target=tone, daemon=True).start()
            process = subprocess.Popen([CAVA, "-p", str(config)], stdout=subprocess.PIPE,
                                       stderr=subprocess.DEVNULL, text=True)
            guard = threading.Timer(10, process.kill)   # never wait forever on its output
            guard.start()
            try:
                lines = []   # until the tone shows, at most 2 seconds of frames
                while len(lines) < 60:
                    line = process.stdout.readline()
                    if not line:
                        break
                    lines.append(line)
                    if any(value not in ("", "0") for value in line.strip().split(";")):
                        break
            finally:
                guard.cancel()
                process.kill()
                process.wait()
            frames = [line.rstrip("\n").rstrip(";").split(";") for line in lines if line.strip()]
            self.assertTrue(frames)
            for frame in frames:
                self.assertEqual(len(frame), 24)
                self.assertTrue(all(0 <= int(value) <= 100 for value in frame))
            self.assertTrue(any(int(value) > 0 for frame in frames for value in frame))  # the tone shows


if __name__ == "__main__":
    unittest.main()

"""`tfem record`: the first call starts wf-recorder on the screen in focus,
the second stops it (SIGINT) and the file stays (fake wf-recorder, hyprctl
and qs: they log what they are asked)."""
import os
import subprocess
import sys
import time
import unittest

from helpers import REPO, SandboxTest

FAKES = {
    # Writes the file named after -f once it gets SIGINT, like the real one
    # (which sets its own handler: a background job starts with SIGINT ignored).
    "wf-recorder": 'exec python3 - "$@" <<"PY"\n'
                   'import os, signal, sys, time\n'
                   'open(os.environ["LOG"], "a").write("wf-recorder " + " ".join(sys.argv[1:]) + "\\n")\n'
                   'out = sys.argv[sys.argv.index("-f") + 1]\n'
                   'def stop(*_):\n'
                   '    open(out, "w").write("video\\n"); sys.exit(0)\n'
                   'signal.signal(signal.SIGINT, stop)\n'
                   'while True: time.sleep(0.1)\n'
                   'PY',
    "hyprctl": 'echo \'[{"name": "DP-2", "focused": false}, {"name": "HDMI-A-1", "focused": true}]\'',
    "qs": 'echo "qs $*" >> "$LOG"',
    "pactl": 'echo alsa_output.pci-0000_00_1f.3.analog-stereo',
}


class RecordTest(SandboxTest):
    def setUp(self):
        super().setUp()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        for name, body in FAKES.items():
            (self.bin / name).write_text(f"#!/bin/sh\n{body}\n")
            (self.bin / name).chmod(0o755)
        self.log = self.home / "calls.log"
        self.runtime = self.home / "run"
        self.runtime.mkdir()

    def record(self, *args):
        env = {"HOME": str(self.home), "PATH": f"{self.bin}:/usr/bin:/bin", "LOG": str(self.log),
               "XDG_RUNTIME_DIR": str(self.runtime)}
        return subprocess.run(["bash", str(REPO / "scripts/record.sh"), *args], env=env,
                              capture_output=True, text=True, timeout=20)

    def test_start_then_stop_saves_the_video_of_the_focused_screen(self):
        self.assertEqual(self.record().returncode, 0)
        time.sleep(0.3)
        calls = self.log.read_text()
        self.assertIn("-o HDMI-A-1", calls)
        self.assertIn("qs ipc -c desktop call recording started", calls)
        self.assertTrue((self.runtime / "tfem-recording.pid").exists())
        self.assertEqual(self.record().returncode, 0)
        videos = list((self.home / "Videos/Screencasts").glob("*.mp4"))
        self.assertEqual([v.read_text() for v in videos], ["video\n"])
        self.assertIn("call recording stopped", self.log.read_text())
        self.assertFalse((self.runtime / "tfem-recording.pid").exists())

    def sound(self, choice):
        config = self.home / ".config/tfem/config.json"
        config.parent.mkdir(parents=True, exist_ok=True)
        config.write_text('{"schema": 1, "record": {"audio": "%s"}}' % choice)
        self.assertEqual(self.record().returncode, 0)
        time.sleep(0.3)
        self.record()
        return next(line for line in self.log.read_text().splitlines() if line.startswith("wf-recorder"))

    def test_the_computer_sound_by_default(self):
        self.assertEqual(self.record().returncode, 0)
        time.sleep(0.3)
        self.record()
        self.assertIn("--audio=alsa_output.pci-0000_00_1f.3.analog-stereo.monitor", self.log.read_text())

    def test_the_microphone_or_no_sound_when_chosen(self):
        self.assertRegex(self.sound("microphone"), r"--audio( |$)")
        self.log.unlink()
        self.assertNotIn("--audio", self.sound("none"))

    def test_bad_arguments_are_refused(self):
        self.assertEqual(self.record("everything").returncode, 64)


if __name__ == "__main__":
    unittest.main(argv=sys.argv)

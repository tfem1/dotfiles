"""`tfem fonts fetch`: Monocraft from a local server, checked against its
SHA-256, installed once with its license."""
import contextlib
import hashlib
import http.server
import io
import sys
import threading
import zipfile
import unittest
from functools import partial
from pathlib import Path
from unittest import mock

from helpers import SandboxTest

import fonts  # noqa: E402


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


class FetchTest(SandboxTest):
    def setUp(self):
        super().setUp()
        served = self.home / "served"
        served.mkdir()
        (served / "Monocraft.ttc").write_bytes(b"pixel font")
        (served / "LICENSE").write_text("SIL Open Font License 1.1\n")
        (served / "OFL.txt").write_text("SIL Open Font License 1.1\n")
        with zipfile.ZipFile(served / "flex.zip", "w") as bundle:
            bundle.writestr("GoogleSansFlex[wght].ttf", b"flex font")
        self.flex_sha = hashlib.sha256((served / "flex.zip").read_bytes()).hexdigest()
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), partial(Quiet, directory=str(served)))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.shutdown)
        base = f"http://127.0.0.1:{server.server_address[1]}"
        self.urls = {"BASE": base, "LICENSE_URL": f"{base}/LICENSE", "FLEX_URL": f"{base}/flex.zip",
                     "FLEX_LICENSE_URL": f"{base}/OFL.txt"}
        self.fonts = self.home / ".local/share/fonts"

    def fetch(self, sha256=hashlib.sha256(b"pixel font").hexdigest()):
        out = io.StringIO()
        env = {**self.env, "PATH": "/nonexistent"}   # no fc-cache: nothing else touched
        with mock.patch.multiple(fonts, SHA256=sha256, FLEX_SHA256=self.flex_sha, **self.urls), \
                contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            return fonts.main(["fetch"], env=env), out.getvalue()

    def test_installs_the_font_and_its_license_once(self):
        code, output = self.fetch()
        self.assertEqual(code, 0, output)
        self.assertEqual((self.fonts / "Monocraft/Monocraft.ttc").read_bytes(), b"pixel font")
        self.assertIn("Open Font License", (self.fonts / "Monocraft/LICENSE").read_text())
        self.assertEqual((self.fonts / "GoogleSansFlex/GoogleSansFlex.ttf").read_bytes(), b"flex font")
        self.assertIn("Open Font License", (self.fonts / "GoogleSansFlex/OFL.txt").read_text())
        code, output = self.fetch()
        self.assertEqual(code, 0)
        self.assertIn("already", output)

    def test_a_download_that_does_not_match_is_refused(self):
        code, output = self.fetch("0" * 64)
        self.assertEqual(code, 2)
        self.assertIn("checksum", output)
        self.assertFalse((self.fonts / "Monocraft/Monocraft.ttc").exists())
        self.assertEqual([p.name for p in (self.fonts / "Monocraft").iterdir()], [])


if __name__ == "__main__":
    unittest.main(argv=sys.argv)

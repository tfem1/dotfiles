"""`tfem cursors fetch`: Pling's OCS answer read for the link and md5, the
archive checked, its cursor folder installed as FossaCursors (served here
by a local web server, no network)."""
import functools
import hashlib
import http.server
import io
import os
import subprocess
import sys
import tarfile
import tempfile
import threading
import unittest
from pathlib import Path

from helpers import REPO


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def archive() -> bytes:
    out = io.BytesIO()
    with tarfile.open(fileobj=out, mode="w:gz") as tar:
        for name, data in (("Fossa/cursors/left_ptr", b"XCUR"), ("Fossa/index.theme", b"[Icon Theme]\nName=Fossa\n")):
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
    return out.getvalue()


class CursorsTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.served = self.root / "served"
        self.served.mkdir()
        handler = functools.partial(Quiet, directory=str(self.served))
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self._tmp.cleanup()

    def fetch(self, data: bytes, md5: str):
        base = f"http://127.0.0.1:{self.server.server_port}"
        (self.served / "FossaCursors.tar.gz").write_bytes(data)
        (self.served / "api.xml").write_text(f"<ocs><data><content><downloadlink1>{base}/FossaCursors.tar.gz"
                                             f"</downloadlink1><downloadmd5sum1>{md5}</downloadmd5sum1></content></data></ocs>")
        env = {**os.environ, "TFEM_FOSSA_API": f"{base}/api.xml", "NO_PROXY": "127.0.0.1", "no_proxy": "127.0.0.1"}
        return subprocess.run([sys.executable, str(REPO / "scripts/cursors.py"), "fetch", "--icons", str(self.root / "icons")],
                              env=env, capture_output=True, text=True, timeout=60)

    def test_the_cursor_folder_is_installed_as_fossacursors(self):
        data = archive()
        done = self.fetch(data, hashlib.md5(data).hexdigest())
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual((self.root / "icons/FossaCursors/cursors/left_ptr").read_bytes(), b"XCUR")
        self.assertEqual(self.fetch(data, hashlib.md5(data).hexdigest()).returncode, 0)   # again: replaced

    def test_a_wrong_md5_installs_nothing(self):
        done = self.fetch(archive(), "0" * 32)
        self.assertEqual(done.returncode, 1)
        self.assertIn("md5", done.stderr)
        self.assertFalse((self.root / "icons/FossaCursors").exists())


if __name__ == "__main__":
    unittest.main()

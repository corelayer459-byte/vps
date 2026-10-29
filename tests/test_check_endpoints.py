import importlib.util
import pathlib
import socket
import threading
import unittest

MODULE_PATH = pathlib.Path(__file__).parents[1] / "tools" / "check_endpoints.py"
spec = importlib.util.spec_from_file_location("check_endpoints", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class EndpointCheckTests(unittest.TestCase):
    def test_invalid_http_url_fails_cleanly(self):
        ok, message = module.check_http("ftp://example.com")
        self.assertFalse(ok)
        self.assertIn("Invalid", message)

    def test_tcp_reachable_local_socket(self):
        listener = socket.socket()
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        port = listener.getsockname()[1]

        def accept_once():
            conn, _ = listener.accept()
            conn.close()
            listener.close()

        threading.Thread(target=accept_once, daemon=True).start()
        ok, message = module.check_tcp("127.0.0.1", port, timeout=1.0)
        self.assertTrue(ok, message)

    def test_tcp_unreachable_port_fails(self):
        sock = socket.socket()
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
        sock.close()
        ok, message = module.check_tcp("127.0.0.1", port, timeout=1.0)
        self.assertFalse(ok)
        self.assertIn("failed", message.lower())


if __name__ == "__main__":
    unittest.main()

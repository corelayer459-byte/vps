#!/usr/bin/env python3
"""Dependency-free reachability checks for Pterodactyl and Minecraft endpoints."""
import argparse
import socket
import sys
import urllib.error
import urllib.request
from urllib.parse import urlparse


def check_tcp(host: str, port: int, timeout: float = 4.0) -> tuple[bool, str]:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, f"TCP connection succeeded: {host}:{port}"
    except (OSError, TimeoutError) as exc:
        return False, f"TCP connection failed: {host}:{port} ({exc})"


def check_http(url: str, timeout: float = 5.0) -> tuple[bool, str]:
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        return False, f"Invalid HTTP(S) URL: {url}"
    req = urllib.request.Request(url, headers={"User-Agent": "ptero-mc-control-kit/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            code = response.status
            ok = 200 <= code < 400
            return ok, f"HTTP {code}: {url}"
    except urllib.error.HTTPError as exc:
        return False, f"HTTP {exc.code}: {url} (service responded; check access/path)"
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        return False, f"HTTP request failed: {url} ({exc})"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--panel", help="Panel base URL, e.g. https://panel.example.com")
    parser.add_argument("--wings", help="Optional Wings endpoint URL, if intentionally reachable")
    parser.add_argument("--mc-host", help="Minecraft server hostname or IP")
    parser.add_argument("--mc-port", type=int, default=25565, help="Minecraft TCP port (default: 25565)")
    args = parser.parse_args()
    if not any((args.panel, args.wings, args.mc_host)):
        parser.error("provide at least one of --panel, --wings, or --mc-host")
    if not 1 <= args.mc_port <= 65535:
        parser.error("--mc-port must be between 1 and 65535")
    checks = []
    if args.panel:
        checks.append(("Panel", check_http(args.panel.rstrip("/"))))
    if args.wings:
        checks.append(("Wings", check_http(args.wings.rstrip("/"))))
    if args.mc_host:
        checks.append(("Minecraft", check_tcp(args.mc_host, args.mc_port)))
    failed = False
    for name, (ok, message) in checks:
        print(f"[{'PASS' if ok else 'FAIL'}] {name}: {message}")
        failed |= not ok
    print(f"\nResult: {sum(ok for _, (ok, _) in checks)}/{len(checks)} checks passed.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

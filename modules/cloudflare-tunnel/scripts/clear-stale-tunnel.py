#!/usr/bin/env python3
"""Delete leftover cloudflared tunnels that would block Terraform create (Cloudflare 1013).

Azure destroy does not always remove the Cloudflare tunnel. A later apply then
POSTs the same name and gets 409. Inactive/down leftovers are deleted; a
healthy tunnel with connections is left alone so this is safe to run against
an already-managed stack.

Env:
  CF_API_TOKEN    Cloudflare API token
  CF_ACCOUNT_ID   Cloudflare account ID
  CF_TUNNEL_NAME  Tunnel name this module is about to create
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.cloudflare.com/client/v4"
# Cloudflare marks unused leftovers inactive/down after the connectors die.
STALE_STATUSES = {"inactive", "down", "degraded", ""}


def die(msg: str, code: int = 1) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def req(method: str, url: str, token: str) -> dict:
    request = urllib.request.Request(
        url,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as err:
        body = err.read().decode("utf-8", errors="replace")
        die(f"{method} {url} -> HTTP {err.code}: {body}")


def list_tunnels(account_id: str, name: str, token: str) -> list[dict]:
    tunnels: list[dict] = []
    page = 1
    while True:
        query = urllib.parse.urlencode(
            {
                "name": name,
                "is_deleted": "false",
                "per_page": 100,
                "page": page,
            }
        )
        data = req("GET", f"{API}/accounts/{account_id}/cfd_tunnel?{query}", token)
        tunnels.extend(data.get("result") or [])
        info = data.get("result_info") or {}
        if page >= int(info.get("total_pages") or 1):
            break
        page += 1
    return tunnels


def main() -> None:
    token = os.environ.get("CF_API_TOKEN", "").strip()
    account_id = os.environ.get("CF_ACCOUNT_ID", "").strip()
    name = os.environ.get("CF_TUNNEL_NAME", "").strip()
    if not token or not account_id or not name:
        die("CF_API_TOKEN, CF_ACCOUNT_ID, and CF_TUNNEL_NAME are required")

    matches = [t for t in list_tunnels(account_id, name, token) if t.get("name") == name]
    if not matches:
        print(f"no existing tunnel named {name}")
        return

    for tunnel in matches:
        tunnel_id = tunnel.get("id")
        status = (tunnel.get("status") or "").lower()
        connections = tunnel.get("connections") or []
        if status not in STALE_STATUSES and connections:
            die(
                f"refusing to delete healthy tunnel {name} id={tunnel_id} "
                f"status={status} connections={len(connections)}. "
                "Delete it in Cloudflare Zero Trust or pick a different name."
            )
        data = req(
            "DELETE",
            f"{API}/accounts/{account_id}/cfd_tunnel/{tunnel_id}?cascade=true",
            token,
        )
        print(
            f"deleted stale tunnel {name} id={tunnel_id} status={status} "
            f"success={data.get('success')}"
        )


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Delete A/AAAA/CNAME records that would block Terraform tunnel CNAMEs (Cloudflare 81053).

Keeps a record only when it is already a CNAME to CF_KEEP_CONTENT (this tunnel).
Does not touch TXT records.

Env:
  CF_API_TOKEN     Cloudflare API token
  CF_ZONE_ID       Zone ID
  CF_RECORD_NAMES  Newline-separated FQDNs (apex, wildcard, extras)
  CF_KEEP_CONTENT  <tunnel-id>.cfargotunnel.com
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.cloudflare.com/client/v4"


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


def list_records(zone_id: str, name: str, token: str) -> list[dict]:
    records: list[dict] = []
    page = 1
    while True:
        query = urllib.parse.urlencode({"name": name, "per_page": 100, "page": page})
        data = req("GET", f"{API}/zones/{zone_id}/dns_records?{query}", token)
        records.extend(data.get("result") or [])
        info = data.get("result_info") or {}
        if page >= int(info.get("total_pages") or 1):
            break
        page += 1
    return records


def main() -> None:
    token = os.environ.get("CF_API_TOKEN", "").strip()
    zone_id = os.environ.get("CF_ZONE_ID", "").strip()
    keep = os.environ.get("CF_KEEP_CONTENT", "").strip()
    names = [n.strip() for n in os.environ.get("CF_RECORD_NAMES", "").splitlines() if n.strip()]
    if not token or not zone_id or not keep or not names:
        die("CF_API_TOKEN, CF_ZONE_ID, CF_KEEP_CONTENT, and CF_RECORD_NAMES are required")

    for name in names:
        for rec in list_records(zone_id, name, token):
            rec_type = rec.get("type")
            content = rec.get("content") or ""
            rec_id = rec.get("id")
            if rec_type not in ("A", "AAAA", "CNAME"):
                continue
            if rec_type == "CNAME" and content.rstrip(".") == keep.rstrip("."):
                print(f"keep {rec_type} {name} -> {content}")
                continue
            data = req("DELETE", f"{API}/zones/{zone_id}/dns_records/{rec_id}", token)
            print(f"deleted {rec_type} {name} id={rec_id} success={data.get('success')}")


if __name__ == "__main__":
    main()

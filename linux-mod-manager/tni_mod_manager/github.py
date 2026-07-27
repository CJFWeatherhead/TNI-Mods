"""GitHub releases API and file downloads."""

from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .paths import GITHUB_API_BASE, USER_AGENT

ProgressCallback = Callable[[int], None]

_TAG_PATTERN = re.compile(r"^(.+)-v(\d+\.\d+\.\d+)$")


def compare_semver(v1: str, v2: str) -> int:
    """Compare two semantic versions. Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal."""
    try:
        p1 = [int(x) for x in v1.split(".")]
        p2 = [int(x) for x in v2.split(".")]
        for i in range(3):
            a = p1[i] if i < len(p1) else 0
            b = p2[i] if i < len(p2) else 0
            if a > b:
                return 1
            if a < b:
                return -1
        return 0
    except (ValueError, AttributeError):
        return 0


def _http_get_json(url: str, timeout: float = 30.0) -> Any:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": USER_AGENT,
        },
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_mod_releases(
    progress_cb: ProgressCallback | None = None,
) -> dict[str, dict[str, Any]]:
    """
    Paginate GitHub releases (max 5 pages × 100) and return latest release per mod_id.

    Tag pattern: <mod-id>-v<semver>. Keeps the highest version per mod_id.
    """
    mod_releases: dict[str, dict[str, Any]] = {}
    per_page = 100
    max_pages = 5

    for page in range(1, max_pages + 1):
        if progress_cb:
            progress_cb(int((page - 1) / max_pages * 100))

        uri = f"{GITHUB_API_BASE}/releases?per_page={per_page}&page={page}"
        try:
            response = _http_get_json(uri)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError):
            break

        if not isinstance(response, list) or len(response) == 0:
            break

        for release in response:
            tag_name = release.get("tag_name") or ""
            m = _TAG_PATTERN.match(tag_name)
            if not m:
                continue

            mod_id = m.group(1)
            version = m.group(2)

            assets = release.get("assets") or []
            asset = next(
                (a for a in assets if str(a.get("name", "")).lower().endswith(".zip")),
                None,
            )
            if not asset:
                continue

            release_info: dict[str, Any] = {
                "mod_id": mod_id,
                "version": version,
                "tag_name": tag_name,
                "download_url": asset.get("browser_download_url"),
                "asset_name": asset.get("name"),
                "size": asset.get("size"),
                "published_at": release.get("published_at"),
                "release_notes": release.get("body") or "",
                "html_url": release.get("html_url"),
            }

            existing = mod_releases.get(mod_id)
            if existing is None or compare_semver(version, existing["version"]) > 0:
                mod_releases[mod_id] = release_info

        if len(response) < per_page:
            break

    if progress_cb:
        progress_cb(100)

    return mod_releases


def download_file(
    url: str,
    dest_path: str | Path,
    progress_cb: ProgressCallback | None = None,
) -> None:
    """
    Download url to dest_path.

    progress_cb receives percent 0–100, or -1 when total size is unknown.
    """
    dest = Path(dest_path)
    dest.parent.mkdir(parents=True, exist_ok=True)

    req = urllib.request.Request(
        url,
        headers={"User-Agent": USER_AGENT},
        method="GET",
    )

    with urllib.request.urlopen(req, timeout=120) as resp:
        total = resp.headers.get("Content-Length")
        total_bytes = int(total) if total and total.isdigit() else 0
        downloaded = 0
        last_pct = -1

        with open(dest, "wb") as out:
            while True:
                chunk = resp.read(8192)
                if not chunk:
                    break
                out.write(chunk)
                downloaded += len(chunk)

                if progress_cb:
                    if total_bytes > 0:
                        pct = min(100, int(downloaded * 100 / total_bytes))
                        if pct != last_pct:
                            last_pct = pct
                            progress_cb(pct)
                    else:
                        progress_cb(-1)

    if progress_cb and total_bytes > 0:
        progress_cb(100)

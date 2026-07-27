"""Read/write local config = { ... } blocks inside entry.lua."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

_CONFIG_RE = re.compile(
    r"(?s)-- ===== MOD CONFIGURATION START =====.*?local config = \{(.*?)\}"
    r".*?-- ===== MOD CONFIGURATION END ====="
)
_SAVE_RE = re.compile(
    r"(?s)(.*?-- ===== MOD CONFIGURATION START =====.*?local config = \{)"
    r"(.*?)"
    r"(\}.*?-- ===== MOD CONFIGURATION END =====.*)"
)
_KV_RE = re.compile(r"^\s*(\w+)\s*=\s*(.+?),?\s*(--.*)?$")


def get_mod_config(entry_lua_path: str | Path) -> dict[str, Any]:
    """Parse key/value pairs from the MOD CONFIGURATION block in entry.lua."""
    path = Path(entry_lua_path)
    if not path.is_file():
        return {}

    try:
        content = path.read_text(encoding="utf-8")
    except OSError:
        return {}

    m = _CONFIG_RE.search(content)
    if not m:
        return {}

    config: dict[str, Any] = {}
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("--"):
            continue
        km = _KV_RE.match(line)
        if not km:
            continue
        key = km.group(1)
        value = km.group(2).rstrip(",").strip()
        value = re.sub(r"\s*--.*$", "", value).strip().rstrip(",")

        if value == "true":
            config[key] = True
        elif value == "false":
            config[key] = False
        elif re.match(r"^-?\d+$", value):
            config[key] = int(value)
        elif re.match(r"^-?\d+\.?\d*$", value):
            config[key] = float(value)
        elif (qm := re.match(r'^"(.*)"$', value)):
            config[key] = qm.group(1)
        else:
            config[key] = value.strip('"')

    return config


def _format_lua_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, float):
        # Match PowerShell: ToString('0.0#####')
        formatted = f"{value:.6f}".rstrip("0")
        if formatted.endswith("."):
            formatted += "0"
        return formatted
    return f'"{value}"'


def save_mod_config(entry_lua_path: str | Path, config: dict[str, Any]) -> bool:
    """Rewrite the local config = { ... } block; preserve surrounding file content."""
    path = Path(entry_lua_path)
    if not path.is_file():
        return False

    try:
        content = path.read_text(encoding="utf-8")
    except OSError:
        return False

    m = _SAVE_RE.match(content)
    if not m:
        return False

    prefix, _old, suffix = m.group(1), m.group(2), m.group(3)
    lines: list[str] = []
    for key in sorted(config.keys()):
        lines.append(f"    {key} = {_format_lua_value(config[key])},")

    new_block = "\n" + "\n".join(lines) + "\n"
    new_content = prefix + new_block + suffix

    try:
        path.write_text(new_content, encoding="utf-8")
        return True
    except OSError:
        return False

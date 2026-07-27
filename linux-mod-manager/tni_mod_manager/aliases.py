"""Command aliases in settings.json (cmd_alias) and alias analysis."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .paths import SETTINGS_PATH

_VAR_RE = re.compile(r"\$(\d+)")


def analyze_alias(command: str) -> dict[str, Any]:
    """Port of Get-AliasInfo — classify alias command structure."""
    info: dict[str, Any] = {
        "Type": "Plain",
        "Variables": [],
        "HasOn": False,
        "HasUsing": False,
        "HasTryThen": False,
        "HasElse": False,
        "HasTryElse": False,
        "IsCompound": False,
        "Commands": [],
        "MaxVariable": 0,
    }

    if not command or not command.strip():
        return info

    variables: list[int] = []
    max_var = 0
    for m in _VAR_RE.finditer(command):
        var_num = int(m.group(1))
        if var_num not in variables:
            variables.append(var_num)
        if var_num > max_var:
            max_var = var_num
    info["Variables"] = variables
    info["MaxVariable"] = max_var

    info["HasOn"] = bool(re.search(r"\bon\s+\$?\d*", command))
    info["HasUsing"] = bool(re.search(r"\busing\s+\$?\d*", command))
    info["HasTryThen"] = bool(re.search(r"\btry\b.*\bthen\b", command, re.DOTALL))
    info["HasElse"] = bool(re.search(r"\belse\b", command))
    info["HasTryElse"] = bool(re.search(r"\btry\b.*\belse\b", command, re.DOTALL))

    info["IsCompound"] = ";" in command
    if info["IsCompound"]:
        info["Commands"] = [c.strip() for c in command.split(";") if c.strip()]
    else:
        info["Commands"] = [command]

    has_conditional = info["HasTryThen"] or info["HasTryElse"]
    if has_conditional and info["IsCompound"]:
        info["Type"] = "Complex"
    elif has_conditional:
        info["Type"] = "Conditional"
    elif info["IsCompound"]:
        info["Type"] = "Compound"
    elif variables:
        info["Type"] = "Variable"
    else:
        info["Type"] = "Plain"

    return info


def load_settings() -> dict[str, Any]:
    """Load game settings.json; return empty dict if missing/invalid."""
    if not SETTINGS_PATH.is_file():
        return {}
    try:
        data = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def save_settings(settings: dict[str, Any]) -> bool:
    """Write settings.json (UTF-8)."""
    try:
        SETTINGS_PATH.parent.mkdir(parents=True, exist_ok=True)
        SETTINGS_PATH.write_text(
            json.dumps(settings, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return True
    except OSError:
        return False


def get_cmd_aliases(settings: dict[str, Any] | None = None) -> dict[str, str]:
    """Return cmd_alias map from settings (or load from disk)."""
    if settings is None:
        settings = load_settings()
    raw = settings.get("cmd_alias") or {}
    if not isinstance(raw, dict):
        return {}
    return {str(k): str(v) for k, v in raw.items()}


def set_cmd_aliases(aliases: dict[str, str]) -> bool:
    """Load settings, replace cmd_alias, save (preserve other keys)."""
    settings = load_settings()
    settings["cmd_alias"] = dict(aliases)
    return save_settings(settings)


def build_alias_preview(name: str, command: str) -> dict[str, Any]:
    """Structured preview data for the alias editor (GUI-agnostic)."""
    info = analyze_alias(command)

    if not command or not command.strip():
        return {
            "type": info["Type"],
            "invocation": "",
            "args_summary": "",
            "suffix_warning": "",
            "usage_example": "",
        }

    # Invocation line
    if name:
        invocation = name
        if info["MaxVariable"] > 0:
            for i in range(1, info["MaxVariable"] + 1):
                invocation += f" <arg{i}>"
        suffix_hints: list[str] = []
        if not info["HasOn"]:
            suffix_hints.append("{on <device>}")
        if not info["HasUsing"]:
            suffix_hints.append("{using <debugger>}")
        if suffix_hints:
            invocation += " " + " ".join(suffix_hints)
        invocation = f"> {invocation}"
    else:
        invocation = "> <alias_name>"

    # Args summary
    args_summary = ""
    if info["Variables"]:
        sorted_vars = sorted(info["Variables"])
        args_text = " ".join(f"${v}" for v in sorted_vars)
        args_summary = (
            f"This alias requires {len(info['Variables'])} argument(s): {args_text}"
        )

    # Suffix warning
    suffix_warning = ""
    if not info["HasOn"] or not info["HasUsing"]:
        warning_parts: list[str] = []
        if not info["HasOn"]:
            warning_parts.append("'on <device address>'")
        if not info["HasUsing"]:
            warning_parts.append("'using <debugger address>'")
        joined = " and ".join(warning_parts)
        suffix_warning = (
            f"Commands require {joined} suffix unless 'always on' or "
            f"'always using' is set by the player."
        )

    # Usage example
    example_parts: list[str] = [name if name else "<alias>"]
    example_samples = {
        1: "192.168.1.1",
        2: "10.0.0.2",
        3: "backup.conf",
        4: "archive.bak",
    }
    for i in range(1, info["MaxVariable"] + 1):
        example_parts.append(example_samples.get(i, f"arg{i}"))
    if not info["HasOn"]:
        example_parts.append("on 192.168.1.100")
    if not info["HasUsing"]:
        example_parts.append("using 192.168.1.50")

    return {
        "type": info["Type"],
        "invocation": invocation,
        "args_summary": args_summary,
        "suffix_warning": suffix_warning,
        "usage_example": " ".join(example_parts),
    }

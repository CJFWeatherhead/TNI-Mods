"""Mod metadata parsers: mod.jsonc and simple metadata.yaml."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


def parse_mod_jsonc(content: str) -> dict[str, Any] | None:
    """
    Parse mod.jsonc (JSON with // comments) into manager metadata dict.
    Returns None on parse failure.
    """
    lines_out: list[str] = []
    for line in content.splitlines():
        # Strip full-line // comments and trailing // outside strings (simple heuristic)
        line = re.sub(r"^\s*//.*$", "", line)
        line = re.sub(r'(?<!")//(?!.*").*$', "", line)
        lines_out.append(line)
    json_content = "\n".join(lines_out)

    try:
        data = json.loads(json_content)
    except (json.JSONDecodeError, TypeError):
        return None

    authors = data.get("authors") or []
    if isinstance(authors, list):
        author = ", ".join(str(a) for a in authors) if authors else "Unknown"
    else:
        author = str(authors) if authors else "Unknown"

    description = data.get("description")
    if isinstance(description, list):
        description = "\n".join(str(x) for x in description)

    metadata: dict[str, Any] = {
        "ID": data.get("id"),
        "Name": data.get("name"),
        "Author": author,
        "Version": data.get("version"),
        "Description": description,
        "Development Status": "Active Development",
        "Game Version Supported": "stable",
        "Last Updated": "",
        "Website": "",
        "Dependencies": [],
        "Image": "",
        "Notes": "",
    }

    links = data.get("links") or {}
    if isinstance(links, dict) and links.get("github"):
        metadata["Website"] = links["github"]

    deps_raw = data.get("dependencies") or {}
    if isinstance(deps_raw, dict):
        metadata["Dependencies"] = [
            name for name in deps_raw if name != "tower-networking-inc"
        ]

    metadata["_jsonc"] = data
    return metadata


def _coerce_scalar(value: str) -> Any:
    value = value.strip()
    m = re.match(r'^"(.*)"$', value)
    if m:
        value = m.group(1)

    if value == "true":
        return True
    if value == "false":
        return False
    if re.match(r"^\d+$", value):
        return int(value)
    if re.match(r"^\d+\.\d+$", value):
        return float(value)
    if value in ("[]", ""):
        return []
    m = re.match(r"^\[(.*)\]$", value)
    if m:
        inner = m.group(1)
        if not inner.strip():
            return []
        return [p.strip().strip('"') for p in re.split(r",\s*", inner)]
    return value


def parse_simple_yaml(content: str) -> dict[str, Any]:
    """Port of ConvertFrom-SimpleYaml including Parameters list."""
    result: dict[str, Any] = {}
    lines = content.splitlines()

    current_key: str | None = None
    multiline_value: list[str] = []
    in_multiline = False
    in_parameters = False
    parameters: list[dict[str, Any]] = []
    current_param: dict[str, Any] | None = None
    param_multiline_key: str | None = None
    param_multiline_value: list[str] = []
    in_param_multiline = False

    def _finish_param_multiline() -> None:
        nonlocal in_param_multiline, param_multiline_key, param_multiline_value, current_param
        if in_param_multiline and param_multiline_key and current_param is not None:
            current_param[param_multiline_key] = "\n".join(param_multiline_value)
        in_param_multiline = False
        param_multiline_key = None
        param_multiline_value = []

    for line in lines:
        if not line.strip() or line.strip().startswith("#"):
            continue

        m = re.match(r"^(\w+(?:\s+\w+)*):\s*\|", line)
        if m:
            current_key = m.group(1)
            in_multiline = True
            multiline_value = []
            continue

        if in_multiline:
            m = re.match(r"^\s{2,}(.+)", line)
            if m:
                multiline_value.append(m.group(1))
                continue
            if current_key is not None:
                result[current_key] = "\n".join(multiline_value)
            in_multiline = False
            current_key = None
            # fall through to process this line further

        if re.match(r"^Parameters:\s*$", line):
            in_parameters = True
            continue

        if in_parameters and (m := re.match(r"^\s{2}-\s+Name:\s*(.+)", line)):
            if current_param is not None:
                _finish_param_multiline()
                parameters.append(current_param)
            current_param = {"Name": m.group(1).strip()}
            in_param_multiline = False
            continue

        if in_parameters and current_param is not None and (
            m := re.match(r"^\s{4}(\w+):\s*\|", line)
        ):
            _finish_param_multiline()
            param_multiline_key = m.group(1)
            in_param_multiline = True
            param_multiline_value = []
            continue

        if in_param_multiline and (m := re.match(r"^\s{6,}(.+)", line)):
            param_multiline_value.append(m.group(1))
            continue

        if in_param_multiline and (m := re.match(r"^\s{4}(\w+):\s*(.*)", line)):
            assert current_param is not None
            if param_multiline_key:
                current_param[param_multiline_key] = "\n".join(param_multiline_value)
            in_param_multiline = False
            param_multiline_key = None
            param_multiline_value = []
            current_param[m.group(1)] = _coerce_scalar(m.group(2))
            continue

        if in_parameters and current_param is not None and (
            m := re.match(r"^\s{4}(\w+):\s*(.*)", line)
        ):
            current_param[m.group(1)] = _coerce_scalar(m.group(2))
            continue

        m = re.match(r"^(\w+(?:\s+\w+)*):\s*(.*)", line)
        if m:
            key = m.group(1)
            value = m.group(2).strip()
            result[key] = _coerce_scalar(value)

    if current_param is not None:
        _finish_param_multiline()
        parameters.append(current_param)

    if in_multiline and current_key is not None:
        result[current_key] = "\n".join(multiline_value)

    if parameters:
        result["Parameters"] = parameters

    return result


_YAML_OVERLAY_KEYS = (
    "Parameters",
    "Notes",
    "Development Status",
    "Last Updated",
    "Creation Date",
    "Game Version Supported",
    "Image",
)


def load_mod_metadata(folder_path: str | Path) -> dict[str, Any] | None:
    """
    Load metadata from mod.jsonc (preferred) then metadata.yaml.
    Merge Parameters and other yaml-only fields when both exist.
    """
    folder = Path(folder_path)
    jsonc_path = folder / "mod.jsonc"
    yaml_path = folder / "metadata.yaml"

    metadata: dict[str, Any] | None = None
    metadata_source: str | None = None

    if jsonc_path.is_file():
        try:
            content = jsonc_path.read_text(encoding="utf-8")
            metadata = parse_mod_jsonc(content)
            if metadata:
                metadata_source = "mod.jsonc"
        except OSError:
            metadata = None

    if metadata is None and yaml_path.is_file():
        try:
            content = yaml_path.read_text(encoding="utf-8")
            metadata = parse_simple_yaml(content)
            metadata_source = "metadata.yaml"
        except OSError:
            return None

    if metadata is None:
        return None

    if metadata_source == "mod.jsonc" and yaml_path.is_file():
        try:
            yaml_data = parse_simple_yaml(yaml_path.read_text(encoding="utf-8"))
            for key in _YAML_OVERLAY_KEYS:
                if key not in yaml_data:
                    continue
                existing = metadata.get(key)
                if existing is None or existing == "" or existing == []:
                    metadata[key] = yaml_data[key]
        except OSError:
            pass

    metadata["MetadataSource"] = metadata_source
    return metadata

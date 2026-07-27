"""Installed/available mod discovery, download, enable/disable, LuaJIT."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from collections.abc import Callable

from . import github
from .metadata import load_mod_metadata
from .paths import (
    DISABLED_MODS_DIR,
    LUAJIT_DIR,
    LUAJIT_ELF,
    LUAJIT_ELF_ALT,
    LUAJIT_ZIP_URL,
    MANAGED_MARKER,
    MOD_CACHE_PATH,
    MOD_MANAGER_VERSION,
    MODS_DIR,
    STEAM_APP_ID,
    ensure_dirs,
)

ProgressCallback = Callable[[int], None]

SOURCE_DOWNLOADED = "Downloaded"
SOURCE_MANUAL = "Manual"
SOURCE_AVAILABLE = "Available"

# In-memory cache (mirrors PowerShell $script:ModCache)
_mod_cache: dict[str, dict[str, Any]] = {}


def load_mod_cache() -> dict[str, dict[str, Any]]:
    """Load mod_cache.json tracking downloaded vs manual mods."""
    global _mod_cache
    if not MOD_CACHE_PATH.is_file():
        _mod_cache = {}
        return _mod_cache
    try:
        raw = json.loads(MOD_CACHE_PATH.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            _mod_cache = {}
            return _mod_cache
        cache: dict[str, dict[str, Any]] = {}
        for key, value in raw.items():
            if isinstance(value, dict):
                cache[str(key)] = {
                    "Source": value.get("Source"),
                    "Version": value.get("Version"),
                    "InstalledAt": value.get("InstalledAt"),
                }
        _mod_cache = cache
        return _mod_cache
    except (OSError, json.JSONDecodeError):
        _mod_cache = {}
        return _mod_cache


def save_mod_cache(cache: dict[str, dict[str, Any]] | None = None) -> bool:
    """Persist mod cache to disk. Uses in-memory cache if cache is omitted."""
    global _mod_cache
    if cache is not None:
        _mod_cache = cache
    try:
        MOD_CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
        MOD_CACHE_PATH.write_text(
            json.dumps(_mod_cache, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return True
    except OSError:
        return False

def is_luajit_installed() -> bool:
    """True if entry.elf or luajit-support.elf exists under mods/luajit-support/."""
    return LUAJIT_ELF.is_file() or LUAJIT_ELF_ALT.is_file()


def _write_managed_marker(
    mod_folder: Path,
    *,
    folder_id: str | None = None,
    installed_version: str,
) -> None:
    data: dict[str, Any] = {
        "managedBy": "TNI-ModManager",
        "modManagerVersion": MOD_MANAGER_VERSION,
        "installedVersion": installed_version,
        "installedAt": datetime.now(timezone.utc).isoformat(),
    }
    if folder_id is not None:
        data["folderId"] = folder_id
    (mod_folder / MANAGED_MARKER).write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def install_luajit(progress_cb: ProgressCallback | None = None) -> bool:
    """Download luajit-support.zip and extract into mods/."""
    ensure_dirs()
    try:
        with tempfile.TemporaryDirectory(prefix="tni-luajit-") as tmp:
            zip_path = Path(tmp) / "luajit-support.zip"
            github.download_file(LUAJIT_ZIP_URL, zip_path, progress_cb=progress_cb)

            if LUAJIT_DIR.exists():
                shutil.rmtree(LUAJIT_DIR)

            import zipfile

            with zipfile.ZipFile(zip_path, "r") as zf:
                zf.extractall(MODS_DIR)

            if not is_luajit_installed():
                return False

            _write_managed_marker(LUAJIT_DIR, installed_version="luajit")
            return True
    except Exception:
        return False


def _apply_source_from_marker_or_cache(
    metadata: dict[str, Any],
    folder: Path,
    mod_cache: dict[str, dict[str, Any]],
) -> None:
    marker_path = folder / MANAGED_MARKER
    if marker_path.is_file():
        metadata["Source"] = SOURCE_DOWNLOADED
        try:
            marker_data = json.loads(marker_path.read_text(encoding="utf-8"))
            metadata["InstalledVersion"] = (
                marker_data.get("installedVersion") or metadata.get("Version")
            )
        except (OSError, json.JSONDecodeError):
            metadata["InstalledVersion"] = metadata.get("Version")
        return

    mod_id = metadata.get("ID")
    folder_name = folder.name
    cache_entry = None
    if mod_id and mod_id in mod_cache:
        cache_entry = mod_cache[mod_id]
    elif folder_name in mod_cache:
        cache_entry = mod_cache[folder_name]

    if cache_entry:
        metadata["Source"] = cache_entry.get("Source") or SOURCE_MANUAL
        metadata["InstalledVersion"] = (
            cache_entry.get("Version") or metadata.get("Version")
        )
    else:
        metadata["Source"] = SOURCE_MANUAL
        metadata["InstalledVersion"] = metadata.get("Version")


def _scan_mod_folder(
    folder: Path,
    *,
    enabled: bool,
    mod_cache: dict[str, dict[str, Any]],
) -> dict[str, Any] | None:
    metadata = load_mod_metadata(folder)
    if not metadata:
        return None
    metadata["Folder"] = folder.name
    metadata["Enabled"] = enabled
    _apply_source_from_marker_or_cache(metadata, folder, mod_cache)
    return metadata


def get_installed_mods(mod_cache: dict[str, dict[str, Any]] | None = None) -> list[dict[str, Any]]:
    """Scan mods/ and mods_disabled/ for installed mods."""
    if mod_cache is None:
        mod_cache = load_mod_cache()

    mods: list[dict[str, Any]] = []

    if MODS_DIR.is_dir():
        for folder in sorted(MODS_DIR.iterdir()):
            if not folder.is_dir():
                continue
            entry = _scan_mod_folder(folder, enabled=True, mod_cache=mod_cache)
            if entry:
                mods.append(entry)

    if DISABLED_MODS_DIR.is_dir():
        for folder in sorted(DISABLED_MODS_DIR.iterdir()):
            if not folder.is_dir():
                continue
            entry = _scan_mod_folder(folder, enabled=False, mod_cache=mod_cache)
            if entry:
                mods.append(entry)

    return mods


def _title_from_mod_id(mod_id: str) -> str:
    pretty = mod_id.replace("-", " ")
    if not pretty:
        return mod_id
    return pretty[0].upper() + pretty[1:]


def get_all_mods(
    installed: list[dict[str, Any]],
    releases: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Merge installed mods with available GitHub releases."""
    all_mods: list[dict[str, Any]] = []
    installed_ids = {m.get("ID") for m in installed}

    for mod in installed:
        entry = dict(mod)
        mod_id = mod.get("ID")
        if mod_id and mod_id in releases:
            release = releases[mod_id]
            entry["LatestVersion"] = release.get("version")
            entry["DownloadUrl"] = release.get("download_url")
            entry["ReleaseInfo"] = release
            installed_ver = mod.get("InstalledVersion")
            if installed_ver and release.get("version"):
                entry["UpdateAvailable"] = (
                    github.compare_semver(str(release["version"]), str(installed_ver)) > 0
                )
        all_mods.append(entry)

    for mod_id, release in releases.items():
        if mod_id in installed_ids:
            continue
        all_mods.append(
            {
                "ID": mod_id,
                "Name": _title_from_mod_id(mod_id),
                "Folder": mod_id,
                "Enabled": False,
                "Source": SOURCE_AVAILABLE,
                "Version": release.get("version"),
                "LatestVersion": release.get("version"),
                "DownloadUrl": release.get("download_url"),
                "ReleaseInfo": release,
                "Author": "Unknown",
                "Development Status": "Active Development",
                "Game Version Supported": "stable",
                "Description": f"Available for download. Published: {release.get('published_at')}",
                "Last Updated": release.get("published_at"),
            }
        )

    return all_mods


def download_mod(
    release_info: dict[str, Any],
    progress_cb: ProgressCallback | None = None,
    mod_cache: dict[str, dict[str, Any]] | None = None,
) -> bool:
    """
    Download and install a mod zip.

    Handles layouts: mods/<id>/, <id>/, or flat files at zip root.
    Writes mod.managed and updates mod_cache.
    """
    import zipfile

    mod_id = release_info.get("mod_id") or release_info.get("ModId")
    download_url = release_info.get("download_url") or release_info.get("DownloadUrl")
    version = release_info.get("version") or release_info.get("Version")
    if not mod_id or not download_url:
        return False

    ensure_dirs()
    if mod_cache is None:
        mod_cache = load_mod_cache()

    mod_target = MODS_DIR / mod_id

    try:
        with tempfile.TemporaryDirectory(prefix=f"tni-mod-{mod_id}-") as tmp:
            tmp_path = Path(tmp)
            zip_path = tmp_path / f"{mod_id}-{version}.zip"
            github.download_file(str(download_url), zip_path, progress_cb=progress_cb)

            extract_path = tmp_path / "extract"
            extract_path.mkdir()
            with zipfile.ZipFile(zip_path, "r") as zf:
                zf.extractall(extract_path)

            inner_mods = extract_path / "mods" / mod_id
            inner_direct = extract_path / mod_id

            if mod_target.exists():
                shutil.rmtree(mod_target)

            if inner_mods.is_dir():
                shutil.move(str(inner_mods), str(mod_target))
            elif inner_direct.is_dir():
                shutil.move(str(inner_direct), str(mod_target))
            else:
                shutil.move(str(extract_path), str(mod_target))

        _write_managed_marker(
            mod_target,
            folder_id=mod_id,
            installed_version=str(version or ""),
        )

        mod_cache[mod_id] = {
            "Source": SOURCE_DOWNLOADED,
            "Version": version,
            "InstalledAt": datetime.now(timezone.utc).isoformat(),
        }
        save_mod_cache(mod_cache)
        return True
    except Exception:
        return False


def remove_downloaded_mod(
    mod_id: str,
    mod_cache: dict[str, dict[str, Any]] | None = None,
) -> bool:
    """Remove a downloaded mod folder and its cache entry."""
    if mod_cache is None:
        mod_cache = load_mod_cache()

    try:
        mod_path = MODS_DIR / mod_id
        if mod_path.exists():
            shutil.rmtree(mod_path)

        # Also remove from disabled if present
        disabled = DISABLED_MODS_DIR / mod_id
        if disabled.exists():
            shutil.rmtree(disabled)

        if mod_id in mod_cache:
            del mod_cache[mod_id]
            save_mod_cache(mod_cache)
        return True
    except OSError:
        return False


def set_mod_enabled(mod: dict[str, Any], enabled: bool) -> bool:
    """
    Enable/disable a mod.

    Downloaded: disable = remove entirely.
    Manual: move between mods/ and mods_disabled/.
    """
    try:
        mod_folder = mod.get("Folder")
        source = mod.get("Source")
        if not mod_folder:
            return False

        if source == SOURCE_DOWNLOADED:
            if not enabled:
                return remove_downloaded_mod(str(mod_folder))
            return True

        ensure_dirs()
        enabled_path = MODS_DIR / mod_folder
        disabled_path = DISABLED_MODS_DIR / mod_folder

        if enabled:
            if disabled_path.exists():
                if enabled_path.exists():
                    shutil.rmtree(enabled_path)
                shutil.move(str(disabled_path), str(enabled_path))
        else:
            if enabled_path.exists():
                if disabled_path.exists():
                    shutil.rmtree(disabled_path)
                shutil.move(str(enabled_path), str(disabled_path))
        return True
    except OSError:
        return False


def get_mod_parameters(
    mod: dict[str, Any],
    current_config: dict[str, Any] | None = None,
) -> list[Any]:
    """Return Parameters from metadata only (Linux skips ui-config.ps1)."""
    _ = current_config  # reserved for GUI parity / future use
    if not mod:
        return []
    params = mod.get("Parameters")
    if isinstance(params, list) and params:
        return params
    return []


def get_entry_lua(mod_folder: str | Path) -> Path:
    """Path to entry.lua for a mod folder name or path under mods/."""
    folder = Path(mod_folder)
    if folder.is_absolute() or (folder.exists() and folder.is_dir()):
        return folder / "entry.lua"
    # Prefer enabled location
    enabled = MODS_DIR / folder
    if (enabled / "entry.lua").is_file():
        return enabled / "entry.lua"
    disabled = DISABLED_MODS_DIR / folder
    if (disabled / "entry.lua").is_file():
        return disabled / "entry.lua"
    return enabled / "entry.lua"


def launch_game() -> bool:
    """Launch Tower Networking Inc via Steam (steam:// or xdg-open)."""
    uri = f"steam://rungameid/{STEAM_APP_ID}"
    try:
        # Prefer steam CLI when available
        steam = shutil.which("steam")
        if steam:
            subprocess.Popen(
                [steam, uri],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return True
        subprocess.Popen(
            ["xdg-open", uri],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        return True
    except OSError:
        return False

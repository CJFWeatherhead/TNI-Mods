"""Game data paths and constants for Linux / Steam Deck."""

from __future__ import annotations

from pathlib import Path

GAME_DATA_DIR: Path = (
    Path.home() / ".local" / "share" / "godot" / "app_userdata" / "Tower Networking Inc"
)
MODS_DIR: Path = GAME_DATA_DIR / "mods"
DISABLED_MODS_DIR: Path = GAME_DATA_DIR / "mods_disabled"
SETTINGS_PATH: Path = GAME_DATA_DIR / "settings.json"
MOD_CACHE_PATH: Path = GAME_DATA_DIR / "mod_cache.json"

LUAJIT_DIR: Path = MODS_DIR / "luajit-support"
# Primary: entry.elf; some builds ship luajit-support.elf at the same level.
LUAJIT_ELF: Path = LUAJIT_DIR / "entry.elf"
LUAJIT_ELF_ALT: Path = LUAJIT_DIR / "luajit-support.elf"

STEAM_APP_ID: str = "2939600"
MOD_MANAGER_VERSION: str = "3.7.12-linux"
MANAGED_MARKER: str = "mod.managed"

GITHUB_REPO: str = "CJFWeatherhead/TNI-Mods"
LUAJIT_ZIP_URL: str = (
    "https://github.com/CJFWeatherhead/TNI-Mods/releases/download/"
    "continuous-gnu-main/luajit-support.zip"
)

USER_AGENT: str = "TNI-ModManager-Linux/3.7.12"
GITHUB_API_BASE: str = f"https://api.github.com/repos/{GITHUB_REPO}"


def ensure_dirs() -> None:
    """Create mods/ and mods_disabled/ under the game data directory."""
    MODS_DIR.mkdir(parents=True, exist_ok=True)
    DISABLED_MODS_DIR.mkdir(parents=True, exist_ok=True)

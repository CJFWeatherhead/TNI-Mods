# Linux / Steam Deck

## English

The official Mod Manager in this repository is the **Windows WPF** app (`ModManager.bat` / `ModManagerGUI.ps1`). It does not run on Linux.

For Steam Deck and Linux there is a **companion** port (separate from WPF, not a replacement):

→ **[linux-mod-manager/](linux-mod-manager/)**

### Requirements

- Python 3
- tkinter (stdlib; on Debian/Ubuntu: `python3-tk`)

### Launch

From the repository root (same level as `ModManager.bat`):

```bash
chmod +x ModManager.sh   # once
./ModManager.sh
```

Alternative from the companion directory: [linux-mod-manager/launch.sh](linux-mod-manager/launch.sh) (thin wrapper to the root script).

### Mod paths (userdata)

| What | Path |
|------|------|
| Game data | `~/.local/share/godot/app_userdata/Tower Networking Inc/` |
| Mods (**lowercase required**) | `…/mods/` |
| Disabled mods | `…/mods_disabled/` |
| Settings | `…/settings.json` |
| Cache | `…/mod_cache.json` |

Linux filesystems are case-sensitive — use **`mods/`**, not `Mods/`.

### Companion vs Windows

| Platform | Entry point |
|----------|-------------|
| Windows | `ModManager.bat` → WPF (`ModManagerGUI.ps1`) |
| Linux / Steam Deck | `./ModManager.sh` → Python + tkinter companion |

More details: [linux-mod-manager/README.md](linux-mod-manager/README.md).

---

## Русский

Официальный Mod Manager в этом репозитории — **Windows WPF** (`ModManager.bat` / `ModManagerGUI.ps1`). На Linux он не запускается.

Для Steam Deck и Linux есть **companion** (отдельный порт, не замена WPF):

→ **[linux-mod-manager/](linux-mod-manager/)**

### Требования

- Python 3
- tkinter (stdlib; в Debian/Ubuntu: `python3-tk`)

### Запуск

Из корня репозитория (рядом с `ModManager.bat`):

```bash
chmod +x ModManager.sh   # один раз
./ModManager.sh
```

Альтернатива из каталога companion: [linux-mod-manager/launch.sh](linux-mod-manager/launch.sh) (обёртка к корневому скрипту).

### Пути (userdata)

| Что | Путь |
|-----|------|
| Данные игры | `~/.local/share/godot/app_userdata/Tower Networking Inc/` |
| Моды (**обязательно lowercase**) | `…/mods/` |
| Отключённые моды | `…/mods_disabled/` |
| Настройки | `…/settings.json` |
| Кэш | `…/mod_cache.json` |

На Linux файловая система чувствительна к регистру — используйте **`mods/`**, не `Mods/`.

### Companion и Windows

| Платформа | Точка входа |
|-----------|-------------|
| Windows | `ModManager.bat` → WPF (`ModManagerGUI.ps1`) |
| Linux / Steam Deck | `./ModManager.sh` → Python + tkinter companion |

Подробности: [linux-mod-manager/README.md](linux-mod-manager/README.md).

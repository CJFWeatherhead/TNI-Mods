# TNI Mod Manager (Linux) — companion

## English

Companion for **Steam Deck / Linux** to the official Windows WPF Mod Manager.  
**Not a replacement** for `ModManagerGUI.ps1` / `ModManager.bat` — a separate port for platforms where WPF is unavailable.

Version: `3.7.12-linux` (parity with Windows Mod Manager `3.7.12`).  
Stack: Python 3 + tkinter (stdlib), no pip dependencies.

### Run

**Preferred** — from the repository root:

```bash
./ModManager.sh
```

Or from this directory (thin wrapper to the root launcher):

```bash
./launch.sh
```

Equivalent manual invocation from the repo root:

```bash
PYTHONPATH=linux-mod-manager python3 -m tni_mod_manager
```

Import check (no GUI):

```bash
cd linux-mod-manager
PYTHONPATH=. python3 -c "from tni_mod_manager.gui import main; print('ok')"
```

GUI tabs: **Mods** (list / download / config) and **Aliases** (`settings.json` → `cmd_alias`).

### Paths

| What | Path |
|------|------|
| Game data | `~/.local/share/godot/app_userdata/Tower Networking Inc/` |
| Mods (**lowercase required**) | `…/mods/` |
| Disabled | `…/mods_disabled/` |
| Settings | `…/settings.json` (`cmd_alias`) |
| Cache | `…/mod_cache.json` |

Use **`mods/`**, not `Mods/` — Linux is case-sensitive.

Steam App ID: `2939600` · mod releases: `CJFWeatherhead/TNI-Mods`

### Package layout

```
linux-mod-manager/
  launch.sh          # wrapper → ../ModManager.sh
  README.md
  tni_mod_manager/
    paths.py github.py mods.py metadata.py
    config_lua.py aliases.py gui.py
    __main__.py …
```

### Windows vs Linux

| Platform | Entry point |
|----------|-------------|
| Windows | `ModManager.bat` → WPF |
| Linux / Steam Deck | `../ModManager.sh` or `./launch.sh` |

See also root [LINUX.md](../LINUX.md).

---

## Русский

Companion для **Steam Deck / Linux** к официальному Windows WPF Mod Manager.  
**Не замена** `ModManagerGUI.ps1` / `ModManager.bat` — отдельный порт для платформ, где WPF недоступен.

Версия: `3.7.12-linux` (паритет с Windows Mod Manager `3.7.12`).  
Стек: Python 3 + tkinter (stdlib), без pip-зависимостей.

### Запуск

**Предпочтительно** — из корня репозитория:

```bash
./ModManager.sh
```

Или из этого каталога (обёртка к корневому launcher):

```bash
./launch.sh
```

Эквивалент вручную из корня репозитория:

```bash
PYTHONPATH=linux-mod-manager python3 -m tni_mod_manager
```

Проверка импорта (без GUI):

```bash
cd linux-mod-manager
PYTHONPATH=. python3 -c "from tni_mod_manager.gui import main; print('ok')"
```

GUI: вкладки **Моды** (список / скачивание / конфиг) и **Алиасы** (`settings.json` → `cmd_alias`).

### Пути

| Что | Путь |
|-----|------|
| Данные игры | `~/.local/share/godot/app_userdata/Tower Networking Inc/` |
| Моды (**обязательно lowercase**) | `…/mods/` |
| Отключённые | `…/mods_disabled/` |
| Настройки | `…/settings.json` (`cmd_alias`) |
| Кэш | `…/mod_cache.json` |

Используйте **`mods/`**, не `Mods/` — на Linux важен регистр.

Steam App ID: `2939600` · релизы модов: `CJFWeatherhead/TNI-Mods`

### Структура пакета

```
linux-mod-manager/
  launch.sh          # обёртка → ../ModManager.sh
  README.md
  tni_mod_manager/
    paths.py github.py mods.py metadata.py
    config_lua.py aliases.py gui.py
    __main__.py …
```

### Windows и Linux

| Платформа | Точка входа |
|-----------|-------------|
| Windows | `ModManager.bat` → WPF |
| Linux / Steam Deck | `../ModManager.sh` или `./launch.sh` |

См. также корневой [LINUX.md](../LINUX.md).

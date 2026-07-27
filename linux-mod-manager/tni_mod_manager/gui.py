"""Tkinter GUI for TNI Mod Manager (Linux / Steam Deck)."""

from __future__ import annotations

import re
import threading
import tkinter as tk
from tkinter import messagebox, ttk
from tkinter.scrolledtext import ScrolledText
from typing import Any

from . import aliases, config_lua, github, mods
from .paths import MOD_MANAGER_VERSION, ensure_dirs


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _source_tag(source: str | None) -> str:
    mapping = {
        mods.SOURCE_DOWNLOADED: "[скачан]",
        mods.SOURCE_MANUAL: "[ручной]",
        mods.SOURCE_AVAILABLE: "[доступен]",
    }
    return mapping.get(source or "", f"[{source}]" if source else "")


def _list_label(mod: dict[str, Any]) -> str:
    name = mod.get("Name") or mod.get("ID") or "?"
    tag = _source_tag(mod.get("Source"))
    badge = " ⬆" if mod.get("UpdateAvailable") else ""
    return f"{name}  {tag}{badge}"


def _release_info(mod: dict[str, Any]) -> dict[str, Any] | None:
    rel = mod.get("ReleaseInfo") or mod.get("Release")
    return rel if isinstance(rel, dict) else None


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

class ModManagerApp:
    """Main window: Mods + Aliases tabs."""

    def __init__(self) -> None:
        self.root = tk.Tk()
        self.root.title(f"TNI Mod Manager {MOD_MANAGER_VERSION}")
        self.root.geometry("1000x700")
        self.root.minsize(800, 500)

        self._all_mods: list[dict[str, Any]] = []
        self._filter = tk.StringVar(value="all")
        self._selected_mod: dict[str, Any] | None = None
        self._param_widgets: dict[str, tuple[str, Any]] = {}
        self._busy = False
        self._aliases: dict[str, str] = {}
        self._alias_editing: str | None = None
        self._ignore_alias_select = False

        self._build_ui()
        self.root.after(100, self._startup)

    # -- UI construction ----------------------------------------------------

    def _build_ui(self) -> None:
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=6, pady=(6, 0))

        self.mods_tab = ttk.Frame(self.notebook)
        self.aliases_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.mods_tab, text="Моды")
        self.notebook.add(self.aliases_tab, text="Алиасы")

        self._build_mods_tab()
        self._build_aliases_tab()
        self._build_status_bar()

        self.notebook.bind("<<NotebookTabChanged>>", self._on_tab_changed)

    def _build_status_bar(self) -> None:
        bar = ttk.Frame(self.root)
        bar.pack(fill=tk.X, side=tk.BOTTOM, padx=6, pady=4)

        self.status_var = tk.StringVar(value="Готово")
        ttk.Label(bar, textvariable=self.status_var, anchor=tk.W).pack(
            side=tk.LEFT, fill=tk.X, expand=True
        )
        self.progress = ttk.Progressbar(bar, mode="determinate", length=200, maximum=100)
        self.progress.pack(side=tk.RIGHT)

    def _build_mods_tab(self) -> None:
        toolbar = ttk.Frame(self.mods_tab)
        toolbar.pack(fill=tk.X, padx=4, pady=4)
        ttk.Button(toolbar, text="Обновить", command=self._refresh_mods).pack(
            side=tk.LEFT, padx=(0, 4)
        )
        ttk.Button(toolbar, text="Запустить игру", command=self._launch_game).pack(
            side=tk.LEFT
        )

        body = ttk.Panedwindow(self.mods_tab, orient=tk.HORIZONTAL)
        body.pack(fill=tk.BOTH, expand=True, padx=4, pady=(0, 4))

        left = ttk.Frame(body)
        right = ttk.Frame(body)
        body.add(left, weight=1)
        body.add(right, weight=2)

        filter_row = ttk.Frame(left)
        filter_row.pack(fill=tk.X, pady=(0, 4))
        for value, label in (
            ("all", "Все"),
            ("installed", "Установленные"),
            ("available", "Доступные"),
        ):
            ttk.Radiobutton(
                filter_row,
                text=label,
                value=value,
                variable=self._filter,
                command=self._repopulate_mod_list,
            ).pack(side=tk.LEFT, padx=(0, 6))

        list_frame = ttk.Frame(left)
        list_frame.pack(fill=tk.BOTH, expand=True)
        self.mod_list = tk.Listbox(list_frame, exportselection=False, activestyle="dotbox")
        scroll = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.mod_list.yview)
        self.mod_list.configure(yscrollcommand=scroll.set)
        self.mod_list.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.mod_list.bind("<<ListboxSelect>>", self._on_mod_select)

        # Detail panel
        self.name_var = tk.StringVar()
        self.version_var = tk.StringVar()
        self.author_var = tk.StringVar()
        self.source_var = tk.StringVar()

        ttk.Label(right, textvariable=self.name_var, font=("", 14, "bold")).pack(
            anchor=tk.W, pady=(0, 4)
        )
        meta = ttk.Frame(right)
        meta.pack(fill=tk.X)
        ttk.Label(meta, text="Версия:").grid(row=0, column=0, sticky=tk.W)
        ttk.Label(meta, textvariable=self.version_var).grid(
            row=0, column=1, sticky=tk.W, padx=(4, 16)
        )
        ttk.Label(meta, text="Автор:").grid(row=0, column=2, sticky=tk.W)
        ttk.Label(meta, textvariable=self.author_var).grid(
            row=0, column=3, sticky=tk.W, padx=(4, 16)
        )
        ttk.Label(meta, text="Источник:").grid(row=1, column=0, sticky=tk.W, pady=(2, 0))
        ttk.Label(meta, textvariable=self.source_var).grid(
            row=1, column=1, sticky=tk.W, padx=(4, 0), pady=(2, 0)
        )

        ttk.Label(right, text="Описание:").pack(anchor=tk.W, pady=(8, 2))
        self.desc_text = ScrolledText(right, height=8, wrap=tk.WORD, state=tk.DISABLED)
        self.desc_text.pack(fill=tk.BOTH, expand=False)

        actions = ttk.Frame(right)
        actions.pack(fill=tk.X, pady=6)
        self.btn_download = ttk.Button(actions, text="Скачать", command=self._download_selected)
        self.btn_update = ttk.Button(actions, text="Обновить", command=self._update_selected)
        self.btn_remove = ttk.Button(actions, text="Удалить", command=self._remove_selected)
        self.btn_enable = ttk.Button(actions, text="Включить", command=self._enable_selected)
        self.btn_disable = ttk.Button(actions, text="Отключить", command=self._disable_selected)
        self.btn_save_cfg = ttk.Button(
            actions, text="Сохранить конфиг", command=self._save_mod_config
        )
        for btn in (
            self.btn_download,
            self.btn_update,
            self.btn_remove,
            self.btn_enable,
            self.btn_disable,
            self.btn_save_cfg,
        ):
            btn.pack(side=tk.LEFT, padx=(0, 4))
            btn.pack_forget()

        ttk.Label(right, text="Параметры:").pack(anchor=tk.W, pady=(4, 2))
        params_outer = ttk.Frame(right)
        params_outer.pack(fill=tk.BOTH, expand=True)
        self.params_canvas = tk.Canvas(params_outer, highlightthickness=0)
        params_scroll = ttk.Scrollbar(
            params_outer, orient=tk.VERTICAL, command=self.params_canvas.yview
        )
        self.params_frame = ttk.Frame(self.params_canvas)
        self.params_frame.bind(
            "<Configure>",
            lambda e: self.params_canvas.configure(scrollregion=self.params_canvas.bbox("all")),
        )
        self._params_window = self.params_canvas.create_window(
            (0, 0), window=self.params_frame, anchor=tk.NW
        )
        self.params_canvas.configure(yscrollcommand=params_scroll.set)
        self.params_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        params_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.params_canvas.bind(
            "<Configure>",
            lambda e: self.params_canvas.itemconfigure(self._params_window, width=e.width),
        )

    def _build_aliases_tab(self) -> None:
        body = ttk.Panedwindow(self.aliases_tab, orient=tk.HORIZONTAL)
        body.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        left = ttk.Frame(body)
        right = ttk.Frame(body)
        body.add(left, weight=1)
        body.add(right, weight=2)

        ttk.Label(left, text="Алиасы").pack(anchor=tk.W)
        list_frame = ttk.Frame(left)
        list_frame.pack(fill=tk.BOTH, expand=True)
        self.alias_list = tk.Listbox(list_frame, exportselection=False, activestyle="dotbox")
        ascroll = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.alias_list.yview)
        self.alias_list.configure(yscrollcommand=ascroll.set)
        self.alias_list.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        ascroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.alias_list.bind("<<ListboxSelect>>", self._on_alias_select)

        ttk.Label(right, text="Имя:").pack(anchor=tk.W)
        self.alias_name_var = tk.StringVar()
        ttk.Entry(right, textvariable=self.alias_name_var).pack(fill=tk.X, pady=(0, 6))
        self.alias_name_var.trace_add("write", lambda *_: self._update_alias_preview())

        ttk.Label(right, text="Команда:").pack(anchor=tk.W)
        self.alias_cmd = tk.Text(right, height=6, wrap=tk.WORD, undo=True)
        self.alias_cmd.pack(fill=tk.X, pady=(0, 4))
        self.alias_cmd.bind("<KeyRelease>", self._on_alias_cmd_key)
        self._configure_alias_tags()

        preview = ttk.LabelFrame(right, text="Превью", padding=6)
        preview.pack(fill=tk.X, pady=4)
        self.preview_type = tk.StringVar()
        self.preview_invocation = tk.StringVar()
        self.preview_args = tk.StringVar()
        self.preview_warning = tk.StringVar()
        self.preview_example = tk.StringVar()
        self.preview_info = tk.StringVar()
        for label, var in (
            ("Тип:", self.preview_type),
            ("Вызов:", self.preview_invocation),
            ("Аргументы:", self.preview_args),
            ("Предупреждение:", self.preview_warning),
            ("Пример:", self.preview_example),
            ("Инфо:", self.preview_info),
        ):
            row = ttk.Frame(preview)
            row.pack(fill=tk.X, pady=1)
            ttk.Label(row, text=label, width=16).pack(side=tk.LEFT, anchor=tk.NW)
            ttk.Label(row, textvariable=var, wraplength=420, justify=tk.LEFT).pack(
                side=tk.LEFT, fill=tk.X, expand=True
            )

        btns = ttk.Frame(right)
        btns.pack(fill=tk.X, pady=8)
        ttk.Button(btns, text="Новый", command=self._alias_new).pack(side=tk.LEFT, padx=(0, 4))
        ttk.Button(btns, text="Сохранить", command=self._alias_save).pack(
            side=tk.LEFT, padx=(0, 4)
        )
        ttk.Button(btns, text="Удалить", command=self._alias_delete).pack(side=tk.LEFT)

    def _configure_alias_tags(self) -> None:
        self.alias_cmd.tag_configure("var", foreground="#0066cc", font=("", 10, "bold"))
        self.alias_cmd.tag_configure("kw_try", foreground="#a15c00", font=("", 10, "bold"))
        self.alias_cmd.tag_configure("kw_then", foreground="#a15c00", font=("", 10, "bold"))
        self.alias_cmd.tag_configure("kw_else", foreground="#a15c00", font=("", 10, "bold"))
        self.alias_cmd.tag_configure("kw_on", foreground="#0a7a3c", font=("", 10, "bold"))
        self.alias_cmd.tag_configure("kw_using", foreground="#0a7a3c", font=("", 10, "bold"))

    # -- Status / threading -------------------------------------------------

    def _set_status(self, text: str, progress: int | None = None) -> None:
        self.status_var.set(text)
        if progress is not None:
            if progress < 0:
                self.progress.configure(mode="indeterminate")
                self.progress.start(12)
            else:
                if str(self.progress.cget("mode")) != "determinate":
                    self.progress.stop()
                    self.progress.configure(mode="determinate")
                self.progress["value"] = max(0, min(100, progress))

    def _ui(self, fn: Any, *args: Any, **kwargs: Any) -> None:
        self.root.after(0, lambda: fn(*args, **kwargs))

    def _run_bg(self, target: Any, *, on_done: Any | None = None) -> None:
        if self._busy:
            messagebox.showinfo("Занято", "Дождитесь завершения текущей операции.")
            return

        def worker() -> None:
            self._busy = True
            err: Exception | None = None
            result: Any = None
            try:
                result = target()
            except Exception as exc:  # noqa: BLE001 — surface to UI
                err = exc
            finally:
                self._busy = False

            def finish() -> None:
                if err is not None:
                    self._set_status(f"Ошибка: {err}", 0)
                    messagebox.showerror("Ошибка", str(err))
                elif on_done:
                    on_done(result)

            self._ui(finish)

        threading.Thread(target=worker, daemon=True).start()

    # -- Startup ------------------------------------------------------------

    def _startup(self) -> None:
        ensure_dirs()
        if not mods.is_luajit_installed():
            install = messagebox.askyesno(
                "LuaJIT",
                "LuaJIT support не установлен.\n"
                "Он нужен для работы модов.\n\n"
                "Скачать и установить сейчас?",
            )
            if install:
                self._install_luajit_then_refresh()
                return
        self._refresh_mods()
        self._load_aliases()

    def _install_luajit_then_refresh(self) -> None:
        def work() -> bool:
            def progress(pct: int) -> None:
                self._ui(self._set_status, f"Установка LuaJIT… {pct}%", pct)

            self._ui(self._set_status, "Установка LuaJIT…", 0)
            return mods.install_luajit(progress_cb=progress)

        def done(ok: bool) -> None:
            if ok:
                self._set_status("LuaJIT установлен", 100)
            else:
                self._set_status("Не удалось установить LuaJIT", 0)
                messagebox.showwarning("LuaJIT", "Установка LuaJIT не удалась.")
            self._refresh_mods()
            self._load_aliases()

        self._run_bg(work, on_done=done)

    # -- Mods tab -----------------------------------------------------------

    def _on_tab_changed(self, _event: Any = None) -> None:
        try:
            current = self.notebook.select()
            if current == str(self.aliases_tab):
                self._load_aliases()
        except tk.TclError:
            pass

    def _refresh_mods(self) -> None:
        def work() -> list[dict[str, Any]]:
            def progress(pct: int) -> None:
                self._ui(self._set_status, f"Загрузка релизов с GitHub… {pct}%", pct)

            self._ui(self._set_status, "Загрузка релизов…", 0)
            mods.load_mod_cache()
            releases = github.fetch_mod_releases(progress_cb=progress)
            installed = mods.get_installed_mods()
            return mods.get_all_mods(installed, releases)

        def done(all_mods: list[dict[str, Any]]) -> None:
            self._all_mods = all_mods
            self._repopulate_mod_list()
            n_inst = sum(
                1 for m in all_mods if m.get("Source") != mods.SOURCE_AVAILABLE
            )
            n_avail = sum(
                1 for m in all_mods if m.get("Source") == mods.SOURCE_AVAILABLE
            )
            self._set_status(
                f"Моды: {n_inst} установлено, {n_avail} доступно", 100
            )

        self._run_bg(work, on_done=done)

    def _filtered_mods(self) -> list[dict[str, Any]]:
        mode = self._filter.get()
        result: list[dict[str, Any]] = []
        for mod in self._all_mods:
            source = mod.get("Source")
            if mode == "installed" and source == mods.SOURCE_AVAILABLE:
                continue
            if mode == "available" and source != mods.SOURCE_AVAILABLE:
                continue
            result.append(mod)
        return result

    def _repopulate_mod_list(self) -> None:
        prev_id = None
        if self._selected_mod:
            prev_id = self._selected_mod.get("ID") or self._selected_mod.get("Folder")

        self.mod_list.delete(0, tk.END)
        filtered = self._filtered_mods()
        select_idx = 0
        for i, mod in enumerate(filtered):
            self.mod_list.insert(tk.END, _list_label(mod))
            mid = mod.get("ID") or mod.get("Folder")
            if prev_id and mid == prev_id:
                select_idx = i

        if filtered:
            self.mod_list.selection_clear(0, tk.END)
            self.mod_list.selection_set(select_idx)
            self.mod_list.activate(select_idx)
            self.mod_list.see(select_idx)
            self._show_mod_details(filtered[select_idx])
        else:
            self._clear_mod_details()

    def _on_mod_select(self, _event: Any = None) -> None:
        sel = self.mod_list.curselection()
        if not sel:
            return
        filtered = self._filtered_mods()
        idx = int(sel[0])
        if 0 <= idx < len(filtered):
            self._show_mod_details(filtered[idx])

    def _clear_mod_details(self) -> None:
        self._selected_mod = None
        self.name_var.set("")
        self.version_var.set("")
        self.author_var.set("")
        self.source_var.set("")
        self.desc_text.configure(state=tk.NORMAL)
        self.desc_text.delete("1.0", tk.END)
        self.desc_text.configure(state=tk.DISABLED)
        self._hide_action_buttons()
        self._clear_params()

    def _hide_action_buttons(self) -> None:
        for btn in (
            self.btn_download,
            self.btn_update,
            self.btn_remove,
            self.btn_enable,
            self.btn_disable,
            self.btn_save_cfg,
        ):
            btn.pack_forget()

    def _show_mod_details(self, mod: dict[str, Any]) -> None:
        self._selected_mod = mod
        self.name_var.set(str(mod.get("Name") or mod.get("ID") or ""))
        ver = mod.get("InstalledVersion") or mod.get("Version") or "—"
        latest = mod.get("LatestVersion")
        if mod.get("UpdateAvailable") and latest:
            ver = f"{ver} → {latest}"
        self.version_var.set(str(ver))
        self.author_var.set(str(mod.get("Author") or "—"))
        self.source_var.set(str(mod.get("Source") or "—"))

        self.desc_text.configure(state=tk.NORMAL)
        self.desc_text.delete("1.0", tk.END)
        self.desc_text.insert(tk.END, str(mod.get("Description") or ""))
        self.desc_text.configure(state=tk.DISABLED)

        self._hide_action_buttons()
        source = mod.get("Source")
        if source == mods.SOURCE_AVAILABLE:
            self.btn_download.pack(side=tk.LEFT, padx=(0, 4))
        elif source == mods.SOURCE_DOWNLOADED:
            if mod.get("UpdateAvailable"):
                self.btn_update.pack(side=tk.LEFT, padx=(0, 4))
            self.btn_remove.pack(side=tk.LEFT, padx=(0, 4))
            self.btn_save_cfg.pack(side=tk.LEFT, padx=(0, 4))
        elif source == mods.SOURCE_MANUAL:
            if mod.get("Enabled"):
                self.btn_disable.pack(side=tk.LEFT, padx=(0, 4))
            else:
                self.btn_enable.pack(side=tk.LEFT, padx=(0, 4))
            self.btn_save_cfg.pack(side=tk.LEFT, padx=(0, 4))

        self._rebuild_params(mod)

    def _clear_params(self) -> None:
        self._param_widgets.clear()
        for child in self.params_frame.winfo_children():
            child.destroy()

    def _rebuild_params(self, mod: dict[str, Any]) -> None:
        self._clear_params()
        source = mod.get("Source")
        if source == mods.SOURCE_AVAILABLE:
            ttk.Label(self.params_frame, text="Скачайте мод, чтобы настроить параметры.").pack(
                anchor=tk.W
            )
            return

        folder = mod.get("Folder") or mod.get("ID")
        current: dict[str, Any] = {}
        if folder:
            current = config_lua.get_mod_config(mods.get_entry_lua(folder))

        params = mods.get_mod_parameters(mod, current)
        if not params:
            ttk.Label(self.params_frame, text="Нет настраиваемых параметров.").pack(anchor=tk.W)
            return

        for param in params:
            if not isinstance(param, dict):
                continue
            if param.get("Visible") is False:
                continue
            ptype = str(param.get("Type") or "").lower()
            if ptype in ("info", "warning", "section"):
                if ptype == "section":
                    ttk.Label(
                        self.params_frame,
                        text=str(param.get("Label") or ""),
                        font=("", 10, "bold"),
                    ).pack(anchor=tk.W, pady=(8, 2))
                continue

            name = param.get("Name")
            if not name:
                continue
            label = param.get("Label") or name
            value = current.get(name, param.get("Default"))

            block = ttk.Frame(self.params_frame)
            block.pack(fill=tk.X, pady=4)
            ttk.Label(block, text=str(label), font=("", 9, "bold")).pack(anchor=tk.W)
            if param.get("Description"):
                ttk.Label(
                    block,
                    text=str(param["Description"]),
                    wraplength=420,
                    foreground="#555555",
                ).pack(anchor=tk.W)

            widget: Any
            if ptype == "boolean":
                var = tk.BooleanVar(value=bool(value))
                widget = ttk.Checkbutton(
                    block, text="Включено", variable=var
                )
                widget.pack(anchor=tk.W)
                self._param_widgets[str(name)] = ("boolean", var)
            elif ptype == "select":
                options = list(param.get("Options") or [])
                var = tk.StringVar(value=str(value) if value is not None else "")
                widget = ttk.Combobox(
                    block, textvariable=var, values=options, state="readonly"
                )
                if value is not None and str(value) in options:
                    widget.set(str(value))
                elif options:
                    widget.current(0)
                widget.pack(fill=tk.X)
                self._param_widgets[str(name)] = ("select", var)
            elif ptype in ("integer", "number"):
                has_range = param.get("Min") is not None and param.get("Max") is not None
                if has_range and ptype == "integer":
                    try:
                        vmin = float(param["Min"])
                        vmax = float(param["Max"])
                        vcur = float(value if value is not None else vmin)
                    except (TypeError, ValueError):
                        vmin, vmax, vcur = 0.0, 100.0, 0.0
                    var = tk.DoubleVar(value=vcur)
                    row = ttk.Frame(block)
                    row.pack(fill=tk.X)
                    scale = ttk.Scale(
                        row, from_=vmin, to=vmax, variable=var, orient=tk.HORIZONTAL
                    )
                    scale.pack(side=tk.LEFT, fill=tk.X, expand=True)
                    entry = ttk.Entry(row, width=8)
                    entry.insert(0, str(int(vcur)))
                    entry.pack(side=tk.LEFT, padx=(4, 0))

                    def on_scale(_e: Any = None, e=entry, v=var) -> None:
                        e.delete(0, tk.END)
                        e.insert(0, str(int(round(v.get()))))

                    def on_entry(_e: Any = None, e=entry, v=var, lo=vmin, hi=vmax) -> None:
                        try:
                            n = int(float(e.get()))
                            n = max(int(lo), min(int(hi), n))
                            v.set(float(n))
                            e.delete(0, tk.END)
                            e.insert(0, str(n))
                        except ValueError:
                            pass

                    scale.configure(command=lambda _v: on_scale())
                    entry.bind("<FocusOut>", on_entry)
                    entry.bind("<Return>", on_entry)
                    self._param_widgets[str(name)] = ("integer_scale", (var, entry))
                else:
                    entry = ttk.Entry(block)
                    entry.insert(0, "" if value is None else str(value))
                    entry.pack(fill=tk.X)
                    self._param_widgets[str(name)] = (ptype, entry)
            else:
                entry = ttk.Entry(block)
                entry.insert(0, "" if value is None else str(value))
                entry.pack(fill=tk.X)
                self._param_widgets[str(name)] = ("string", entry)

    def _collect_param_values(self) -> dict[str, Any]:
        config: dict[str, Any] = {}
        for name, (ptype, widget) in self._param_widgets.items():
            if ptype == "boolean":
                config[name] = bool(widget.get())
            elif ptype == "select":
                config[name] = widget.get()
            elif ptype == "integer_scale":
                var, entry = widget
                try:
                    config[name] = int(float(entry.get()))
                except ValueError:
                    config[name] = int(round(var.get()))
            elif ptype == "integer":
                raw = widget.get().strip()
                try:
                    config[name] = int(float(raw))
                except ValueError:
                    config[name] = raw
            elif ptype == "number":
                raw = widget.get().strip()
                try:
                    config[name] = float(raw)
                except ValueError:
                    config[name] = raw
            else:
                config[name] = widget.get()
        return config

    def _save_mod_config(self) -> None:
        mod = self._selected_mod
        if not mod:
            return
        folder = mod.get("Folder") or mod.get("ID")
        if not folder:
            return
        path = mods.get_entry_lua(folder)
        config = self._collect_param_values()
        # Preserve keys from file that are not in the form
        existing = config_lua.get_mod_config(path)
        existing.update(config)
        if config_lua.save_mod_config(path, existing):
            self._set_status(f"Конфиг сохранён: {folder}")
            messagebox.showinfo("Конфиг", "Параметры сохранены в entry.lua.")
        else:
            messagebox.showerror(
                "Конфиг",
                "Не удалось сохранить конфиг.\n"
                "Проверьте блок MOD CONFIGURATION в entry.lua.",
            )

    def _download_selected(self) -> None:
        mod = self._selected_mod
        if not mod:
            return
        release = _release_info(mod)
        if not release:
            messagebox.showerror("Скачивание", "Нет данных релиза для скачивания.")
            return
        self._download_release(release, label=str(mod.get("Name") or release.get("mod_id")))

    def _update_selected(self) -> None:
        mod = self._selected_mod
        if not mod:
            return
        release = _release_info(mod)
        if not release:
            messagebox.showerror("Обновление", "Нет данных релиза для обновления.")
            return
        self._download_release(
            release, label=f"Обновление {mod.get('Name') or release.get('mod_id')}"
        )

    def _download_release(self, release: dict[str, Any], *, label: str) -> None:
        def work() -> bool:
            def progress(pct: int) -> None:
                msg = f"{label}: {pct}%" if pct >= 0 else f"{label}…"
                self._ui(self._set_status, msg, pct)

            self._ui(self._set_status, f"{label}…", 0)
            return mods.download_mod(release, progress_cb=progress)

        def done(ok: bool) -> None:
            if ok:
                self._set_status(f"Установлено: {label}", 100)
            else:
                self._set_status(f"Ошибка установки: {label}", 0)
                messagebox.showerror("Скачивание", f"Не удалось установить:\n{label}")
            self._refresh_mods()

        self._run_bg(work, on_done=done)

    def _remove_selected(self) -> None:
        mod = self._selected_mod
        if not mod:
            return
        mod_id = str(mod.get("Folder") or mod.get("ID") or "")
        name = mod.get("Name") or mod_id
        if not messagebox.askyesno("Удалить", f"Удалить мод «{name}»?"):
            return
        if mods.remove_downloaded_mod(mod_id):
            self._set_status(f"Удалён: {name}")
            self._refresh_mods()
        else:
            messagebox.showerror("Удаление", f"Не удалось удалить «{name}».")

    def _enable_selected(self) -> None:
        mod = self._selected_mod
        if not mod:
            return
        if mods.set_mod_enabled(mod, True):
            self._set_status(f"Включён: {mod.get('Name')}")
            self._refresh_mods()
        else:
            messagebox.showerror("Моды", "Не удалось включить мод.")

    def _disable_selected(self) -> None:
        mod = self._selected_mod
        if not mod:
            return
        if mods.set_mod_enabled(mod, False):
            self._set_status(f"Отключён: {mod.get('Name')}")
            self._refresh_mods()
        else:
            messagebox.showerror("Моды", "Не удалось отключить мод.")

    def _launch_game(self) -> None:
        if mods.launch_game():
            self._set_status("Запуск игры через Steam…")
        else:
            messagebox.showerror("Запуск", "Не удалось запустить игру через Steam.")

    # -- Aliases tab --------------------------------------------------------

    def _load_aliases(self) -> None:
        self._aliases = aliases.get_cmd_aliases()
        self._repopulate_alias_list()

    def _repopulate_alias_list(self) -> None:
        prev = self._alias_editing
        self._ignore_alias_select = True
        self.alias_list.delete(0, tk.END)
        names = sorted(self._aliases.keys(), key=str.lower)
        select_idx = -1
        for i, name in enumerate(names):
            self.alias_list.insert(tk.END, name)
            if prev and name == prev:
                select_idx = i
        self._ignore_alias_select = False
        if select_idx >= 0:
            self.alias_list.selection_set(select_idx)
            self.alias_list.activate(select_idx)
            self._load_alias_into_editor(names[select_idx])
        elif not names:
            self._alias_new()

    def _on_alias_select(self, _event: Any = None) -> None:
        if self._ignore_alias_select:
            return
        sel = self.alias_list.curselection()
        if not sel:
            return
        name = self.alias_list.get(sel[0])
        self._load_alias_into_editor(name)

    def _load_alias_into_editor(self, name: str) -> None:
        self._alias_editing = name
        self.alias_name_var.set(name)
        cmd = self._aliases.get(name, "")
        self.alias_cmd.delete("1.0", tk.END)
        self.alias_cmd.insert("1.0", cmd)
        self._highlight_alias_command()
        self._update_alias_preview()

    def _alias_new(self) -> None:
        self._alias_editing = None
        self.alias_list.selection_clear(0, tk.END)
        self.alias_name_var.set("")
        self.alias_cmd.delete("1.0", tk.END)
        self._update_alias_preview()

    def _alias_save(self) -> None:
        name = self.alias_name_var.get().strip()
        cmd = self.alias_cmd.get("1.0", tk.END).rstrip("\n")
        if not name:
            messagebox.showwarning("Алиасы", "Укажите имя алиаса.")
            return
        if not cmd.strip():
            messagebox.showwarning("Алиасы", "Укажите команду.")
            return

        data = dict(self._aliases)
        if self._alias_editing and self._alias_editing != name and self._alias_editing in data:
            del data[self._alias_editing]
        data[name] = cmd
        if aliases.set_cmd_aliases(data):
            self._aliases = data
            self._alias_editing = name
            self._repopulate_alias_list()
            self._set_status(f"Алиас сохранён: {name}")
        else:
            messagebox.showerror("Алиасы", "Не удалось записать settings.json.")

    def _alias_delete(self) -> None:
        name = self.alias_name_var.get().strip() or self._alias_editing
        if not name:
            return
        if name not in self._aliases:
            self._alias_new()
            return
        if not messagebox.askyesno("Алиасы", f"Удалить алиас «{name}»?"):
            return
        data = dict(self._aliases)
        del data[name]
        if aliases.set_cmd_aliases(data):
            self._aliases = data
            self._alias_editing = None
            self._repopulate_alias_list()
            self._set_status(f"Алиас удалён: {name}")
        else:
            messagebox.showerror("Алиасы", "Не удалось записать settings.json.")

    def _on_alias_cmd_key(self, _event: Any = None) -> None:
        self._highlight_alias_command()
        self._update_alias_preview()

    def _highlight_alias_command(self) -> None:
        text = self.alias_cmd
        for tag in ("var", "kw_try", "kw_then", "kw_else", "kw_on", "kw_using"):
            text.tag_remove(tag, "1.0", tk.END)

        content = text.get("1.0", tk.END)
        patterns = (
            (r"\$\d+", "var"),
            (r"\btry\b", "kw_try"),
            (r"\bthen\b", "kw_then"),
            (r"\belse\b", "kw_else"),
            (r"\bon\b", "kw_on"),
            (r"\busing\b", "kw_using"),
        )
        for pattern, tag in patterns:
            for m in re.finditer(pattern, content, flags=re.IGNORECASE):
                start = f"1.0+{m.start()}c"
                end = f"1.0+{m.end()}c"
                text.tag_add(tag, start, end)

    def _update_alias_preview(self) -> None:
        name = self.alias_name_var.get().strip()
        cmd = self.alias_cmd.get("1.0", tk.END).rstrip("\n")
        preview = aliases.build_alias_preview(name, cmd)
        info = aliases.analyze_alias(cmd)
        self.preview_type.set(str(preview.get("type") or info.get("Type") or ""))
        self.preview_invocation.set(str(preview.get("invocation") or ""))
        self.preview_args.set(str(preview.get("args_summary") or ""))
        self.preview_warning.set(str(preview.get("suffix_warning") or ""))
        self.preview_example.set(str(preview.get("usage_example") or ""))
        info_bits = []
        if info.get("Variables"):
            info_bits.append(f"$vars: {info['Variables']}")
        if info.get("IsCompound"):
            info_bits.append(f"команд: {len(info.get('Commands') or [])}")
        self.preview_info.set(
            str(preview.get("info") or "; ".join(info_bits) or "")
        )

    # -- Run ----------------------------------------------------------------

    def run(self) -> None:
        self.root.mainloop()


def main() -> None:
    app = ModManagerApp()
    app.run()

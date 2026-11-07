#!/usr/bin/env python3
"""remarkable — a calm little terminal app for your reMarkable cloud.

    remarkable                  browse (interactive)
    remarkable ls [folder]      list a folder
    remarkable get <doc> [-o]   download a document as PDF
    remarkable put <file>... [-t folder]   send files to the tablet

Built on top of rmapi (https://github.com/ddvk/rmapi).
"""
from __future__ import annotations

import argparse
import io
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

logging.disable(logging.WARNING)  # rmscene is chatty about newer formats

HOME = Path.home()
RMAPI = shutil.which("rmapi") or str(HOME / ".local/bin/rmapi")
CACHE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "remarkable"
DOWNLOADS = HOME / "Downloads" / "remarkable"
TYPES_FILE = CACHE / "types.json"
UPLOADABLE = {".pdf", ".epub"}

ICONS = {
    "folder": "󰉋",
    "trash": "󰩺",
    "notebook": "󰠮",
    "pdf": "󰈦",
    "epub": "󰂺",
    "doc": "󰈙",
}


# ───────────────────────────── rmapi layer ──────────────────────────────


class RmError(Exception):
    pass


def _clean_error(text: str) -> str:
    for line in reversed(text.strip().splitlines()):
        if "ERROR" in line or "Error" in line:
            line = re.sub(r"^ERROR:\s*\S+ \S+ \S+:\s*", "", line)
            line = re.sub(r"^Error:\s*", "", line)
            return line.strip()
    return text.strip().splitlines()[-1] if text.strip() else "rmapi failed"


def rmapi(*args: str, cwd: Path | None = None) -> str:
    if not Path(RMAPI).exists():
        raise RmError("rmapi isn't installed (expected it in ~/.local/bin)")
    p = subprocess.run(
        [RMAPI, *args], capture_output=True, text=True, cwd=cwd, stdin=subprocess.DEVNULL
    )
    out = p.stdout + p.stderr
    if p.returncode != 0 or re.search(r"^ERROR", out, re.M):
        raise RmError(_clean_error(out))
    return p.stdout


def join(folder: str, name: str) -> str:
    return f"{folder}/{name}" if folder else name


@dataclass
class Entry:
    name: str
    folder: str
    is_dir: bool
    modified: datetime | None = None

    @property
    def path(self) -> str:
        return join(self.folder, self.name)

    @property
    def is_trash(self) -> bool:
        return self.is_dir and self.path == "trash"

    @property
    def kind(self) -> str:
        if self.is_trash:
            return "trash"
        if self.is_dir:
            return "folder"
        return load_types().get(self.path, "doc")

    @property
    def icon(self) -> str:
        return ICONS.get(self.kind, ICONS["doc"])


_LS = re.compile(r"^(\w{3})\s+(\d{1,2})\s+(\d{4})\s+(\d\d:\d\d)\s\s(.+)$")


def list_folder(folder: str = "") -> list[Entry]:
    out = rmapi("ls", "-l", folder) if folder else rmapi("ls", "-l")
    entries: list[Entry] = []
    for line in out.splitlines():
        m = _LS.match(line)
        if not m:
            continue
        mon, day, year, hm, name = m.groups()
        is_dir = name.endswith("/")
        name = name.rstrip("/")
        try:
            when = datetime.strptime(f"{mon} {day} {year} {hm}", "%b %d %Y %H:%M")
        except ValueError:
            when = None
        entries.append(Entry(name, folder, is_dir, when))
    folders = sorted((e for e in entries if e.is_dir and not e.is_trash), key=lambda e: e.name.lower())
    docs = sorted(
        (e for e in entries if not e.is_dir),
        key=lambda e: e.modified or datetime.min,
        reverse=True,
    )
    trash = [e for e in entries if e.is_trash]
    return folders + docs + trash


def find_all() -> list[Entry]:
    """Every folder and document outside the trash."""
    out = rmapi("find", ".")
    entries = []
    for line in out.splitlines():
        m = re.match(r"^\[(d|f)\] /(.*)$", line)
        if not m or not m.group(2):
            continue
        path = m.group(2)
        if path == "trash" or path.startswith("trash/"):
            continue
        folder, _, name = path.rpartition("/")
        entries.append(Entry(name, folder, m.group(1) == "d"))
    return entries


def stat(path: str) -> dict:
    try:
        return json.loads(rmapi("stat", path))
    except (RmError, json.JSONDecodeError):
        return {}


# ─────────────────────────── types memory ───────────────────────────────

_types: dict[str, str] | None = None


def load_types() -> dict[str, str]:
    global _types
    if _types is None:
        try:
            _types = json.loads(TYPES_FILE.read_text())
        except (OSError, json.JSONDecodeError):
            _types = {}
    return _types


def remember_type(path: str, kind: str) -> None:
    types = load_types()
    if types.get(path) != kind:
        types[path] = kind
        CACHE.mkdir(parents=True, exist_ok=True)
        TYPES_FILE.write_text(json.dumps(types))


# ───────────────────────── documents & rendering ────────────────────────


@dataclass
class Doc:
    """A downloaded document, unpacked into a cache directory."""

    path: str
    root: Path
    uid: str
    kind: str  # notebook / pdf / epub
    pages: list[str]
    content: dict

    def page_rm(self, page_id: str) -> Path | None:
        p = self.root / self.uid / f"{page_id}.rm"
        return p if p.exists() else None

    @property
    def original(self) -> Path | None:
        for ext in ("pdf", "epub"):
            p = self.root / f"{self.uid}.{ext}"
            if p.exists():
                return p
        return None


def fetch(path: str) -> Doc:
    """Download a document (cached by id + modification time) and unpack it."""
    info = stat(path)
    uid = info.get("ID", "")
    stamp = re.sub(r"\W", "", info.get("ModifiedClient", "")) or "x"
    root = CACHE / "docs" / f"{uid or re.sub(r'\W', '_', path)}-{stamp}"
    if not (root / ".ok").exists():
        shutil.rmtree(root, ignore_errors=True)
        root.mkdir(parents=True)
        with tempfile.TemporaryDirectory() as tmp:
            rmapi("get", path, cwd=Path(tmp))
            files = list(Path(tmp).iterdir())
            if not files:
                raise RmError("download came back empty")
            with zipfile.ZipFile(files[0]) as z:
                z.extractall(root)
        (root / ".ok").touch()
    contents = list(root.glob("*.content"))
    if not contents:
        raise RmError("unexpected download format")
    uid = contents[0].stem
    content = json.loads(contents[0].read_text() or "{}")
    kind = content.get("fileType") or "notebook"
    if kind not in ("pdf", "epub"):
        kind = "notebook"
    if "cPages" in content:
        pages = [p["id"] for p in content["cPages"].get("pages", []) if not p.get("deleted")]
    else:
        pages = list(content.get("pages") or [])
    remember_type(path, kind)
    return Doc(path, root, uid, kind, pages, content)


def _page_svg(rm_file: Path) -> bytes:
    from rmc.exporters.svg import rm_to_svg

    out = rm_file.with_suffix(".svg")
    if not out.exists():
        rm_to_svg(str(rm_file), str(out))
    return out.read_bytes()


PAGE_W, PAGE_H = 445, 594  # points — matches the tablet's 3:4 screen


def to_pdf(doc: Doc, dest: Path) -> Path:
    """Write the document as a PDF (or the original EPUB) into dest."""
    dest.mkdir(parents=True, exist_ok=True)
    safe = re.sub(r'[/\\:*?"<>|]', "_", doc.path.rpartition("/")[2]) or "document"

    if doc.kind == "epub" and doc.original:
        out = dest / f"{safe}.epub"
        shutil.copy(doc.original, out)
        return out

    if doc.kind == "pdf" and doc.original:
        # Try rmapi's own annotated export first; fall back to the clean original.
        with tempfile.TemporaryDirectory() as tmp:
            try:
                rmapi("geta", doc.path, cwd=Path(tmp))
                made = [p for p in Path(tmp).iterdir() if p.suffix == ".pdf"]
                if made:
                    out = dest / f"{safe}.pdf"
                    shutil.move(made[0], out)
                    return out
            except RmError:
                pass
        out = dest / f"{safe}.pdf"
        shutil.copy(doc.original, out)
        return out

    import cairosvg
    from pypdf import PdfReader, PdfWriter

    writer = PdfWriter()
    for page_id in doc.pages or []:
        rm_file = doc.page_rm(page_id)
        if rm_file is None:
            writer.add_blank_page(width=PAGE_W, height=PAGE_H)
            continue
        pdf_bytes = cairosvg.svg2pdf(bytestring=_page_svg(rm_file))
        for page in PdfReader(io.BytesIO(pdf_bytes)).pages:
            writer.add_page(page)
    if not writer.pages:
        writer.add_blank_page(width=PAGE_W, height=PAGE_H)
    out = dest / f"{safe}.pdf"
    with out.open("wb") as f:
        writer.write(f)
    return out


def preview_png(doc: Doc, page: int = 0) -> Path | None:
    """A PNG of one page, for the preview pane."""
    out = doc.root / f"preview-{page}.png"
    if out.exists():
        return out
    if doc.kind == "notebook":
        if not doc.pages:
            return None
        rm_file = doc.page_rm(doc.pages[min(page, len(doc.pages) - 1)])
        if rm_file is None:
            return None
        import cairosvg

        cairosvg.svg2png(
            bytestring=_page_svg(rm_file), write_to=str(out),
            background_color="white", output_width=700,
        )
        return out
    if doc.kind == "pdf" and doc.original and shutil.which("pdftoppm"):
        n = str(page + 1)
        subprocess.run(
            ["pdftoppm", "-f", n, "-l", n, "-png", "-scale-to", "700", "-singlefile",
             str(doc.original), str(out.with_suffix(""))],
            capture_output=True,
        )
        return out if out.exists() else None
    return None


# ───────────────────────────── formatting ───────────────────────────────


def when(dt: datetime | None) -> str:
    if dt is None:
        return ""
    now = datetime.now()
    if dt.date() == now.date():
        return dt.strftime("%H:%M")
    if dt.date() == (now - timedelta(days=1)).date():
        return "yesterday"
    if now - dt < timedelta(days=6):
        return dt.strftime("%A")
    if dt.year == now.year:
        return f"{dt.day} {dt:%b}"
    return f"{dt.day} {dt:%b %Y}"


def rice_theme() -> str:
    try:
        return (HOME / ".config/rice/theme").read_text().strip()
    except OSError:
        return "bw"


# ──────────────────────────── plain CLI mode ────────────────────────────


def cli(argv: list[str]) -> int:
    from rich.console import Console
    from rich.table import Table
    from rich.text import Text

    con = Console(highlight=False)
    dim = "grey50"

    ap = argparse.ArgumentParser(prog="remarkable", description="Your reMarkable, in the terminal.")
    sub = ap.add_subparsers(dest="cmd")
    p_ls = sub.add_parser("ls", help="list a folder")
    p_ls.add_argument("folder", nargs="?", default="")
    p_get = sub.add_parser("get", help="download a document as PDF")
    p_get.add_argument("doc")
    p_get.add_argument("-o", "--out", default=str(DOWNLOADS), help="where to save (default ~/Downloads/remarkable)")
    p_put = sub.add_parser("put", help="send PDFs / EPUBs to the tablet")
    p_put.add_argument("files", nargs="+")
    p_put.add_argument("-t", "--to", default="", help="destination folder (default: top level)")
    args = ap.parse_args(argv)

    def fail(msg: str) -> int:
        con.print(f"  [bold red]✗[/] {msg}")
        return 1

    try:
        if args.cmd == "ls":
            folder = args.folder.strip("/")
            entries = list_folder(folder)
            title = Text("  ◆ ", style=dim).append("reMarkable", style="bold")
            for part in folder.split("/") if folder else []:
                title.append("  ›  ", style=dim).append(part)
            con.print()
            con.print(title)
            con.print()
            t = Table.grid(padding=(0, 2))
            t.add_column(width=2)
            t.add_column()
            t.add_column(justify="right", style=dim)
            for e in entries:
                t.add_row(
                    Text(e.icon, style="bold" if e.is_dir else dim),
                    Text(e.name + ("/" if e.is_dir else ""), style="bold" if e.is_dir else ""),
                    when(e.modified),
                )
            from rich.padding import Padding

            con.print(Padding(t, (0, 0, 0, 2)))
            n = len(entries)
            con.print(Text(f"\n  {n} item{'s' if n != 1 else ''}", style=dim))
            con.print()
            return 0

        if args.cmd == "get":
            with con.status(f"[{dim}]fetching {args.doc}…", spinner="dots"):
                doc = fetch(args.doc.strip("/"))
                out = to_pdf(doc, Path(args.out).expanduser())
            con.print(f"  [bold]✓[/] {str(out).replace(str(HOME), '~', 1)}", soft_wrap=True)
            return 0

        if args.cmd == "put":
            folder = args.to.strip("/")
            for f in args.files:
                p = Path(f).expanduser()
                if not p.is_file():
                    fail(f"{f} isn't a file")
                    continue
                with con.status(f"[{dim}]sending {p.name}…", spinner="dots"):
                    try:
                        rmapi("put", str(p), *([folder] if folder else []))
                    except RmError as e:
                        fail(f"{p.name}: {e}")
                        continue
                con.print(f"  [bold]✓[/] {p.name} [{dim}]→ /{folder}")
            return 0
    except RmError as e:
        return fail(str(e))
    except KeyboardInterrupt:
        return 130
    ap.print_help()
    return 0


# ────────────────────────────── the app ─────────────────────────────────


def run_app() -> None:
    from textual import on, work
    from textual.app import App, ComposeResult
    from textual.binding import Binding
    from textual.containers import Horizontal, Vertical
    from textual.screen import ModalScreen
    from textual.theme import Theme
    from textual.widgets import Footer, Input, Label, ListItem, ListView, LoadingIndicator, OptionList, Static
    from textual.widgets.option_list import Option
    from rich.text import Text

    try:
        from textual_image.widget import Image as PageImage
    except Exception:  # pragma: no cover - preview is a nicety
        PageImage = None

    THEMES = {
        "bw": Theme(
            name="ink", dark=True,
            primary="#FFFFFF", secondary="#AAAAAA", accent="#FFFFFF",
            foreground="#E8E8E8", background="#000000", surface="#000000", panel="#111111",
            success="#FFFFFF", warning="#CCCCCC", error="#FFFFFF",
            variables={"block-cursor-foreground": "#000000", "footer-key-foreground": "#FFFFFF",
                       "input-selection-background": "#555555"},
        ),
        "invert": Theme(
            name="paper", dark=False,
            primary="#000000", secondary="#555555", accent="#000000",
            foreground="#111111", background="#FFFFFF", surface="#FFFFFF", panel="#EEEEEE",
            success="#000000", warning="#333333", error="#000000",
            variables={"block-cursor-foreground": "#FFFFFF", "footer-key-foreground": "#000000"},
        ),
    }

    class Row(ListItem):
        def __init__(self, entry: Entry, show_folder: bool = False) -> None:
            super().__init__()
            self.entry = entry
            self.show_folder = show_folder

        def compose(self) -> ComposeResult:
            e = self.entry
            yield Label(e.icon, classes="icon")
            name = Text(e.name, style="bold" if e.is_dir and not e.is_trash else "")
            if self.show_folder and e.folder:
                name.append(f"   {e.folder}", style="dim")
            yield Label(name, classes="name")
            yield Label(when(e.modified), classes="date")

    class Confirm(ModalScreen[bool]):
        BINDINGS = [("y", "answer(True)", "yes"), ("n,escape", "answer(False)", "no")]

        def __init__(self, title: str, detail: str = "") -> None:
            super().__init__()
            self.title_text, self.detail = title, detail

        def compose(self) -> ComposeResult:
            with Vertical(classes="dialog"):
                yield Label(self.title_text, classes="dialog-title")
                if self.detail:
                    yield Label(self.detail, classes="dialog-detail")
                yield Label(Text.assemble(("y", "bold"), " yes    ", ("n", "bold"), " no"), classes="dialog-hint")

        def action_answer(self, yes: bool) -> None:
            self.dismiss(yes)

    class Prompt(ModalScreen[str | None]):
        BINDINGS = [("escape", "cancel", "cancel")]

        def __init__(self, title: str, value: str = "", placeholder: str = "") -> None:
            super().__init__()
            self.title_text, self.value, self.placeholder = title, value, placeholder

        def compose(self) -> ComposeResult:
            with Vertical(classes="dialog"):
                yield Label(self.title_text, classes="dialog-title")
                yield Input(self.value, placeholder=self.placeholder)
                yield Label(Text.assemble(("enter", "bold"), " ok    ", ("esc", "bold"), " cancel"), classes="dialog-hint")

        @on(Input.Submitted)
        def done(self, ev: Input.Submitted) -> None:
            self.dismiss(ev.value.strip() or None)

        def action_cancel(self) -> None:
            self.dismiss(None)

    class Upload(ModalScreen[Path | None]):
        """Pick a recent PDF/EPUB, or type a path."""

        BINDINGS = [("escape", "cancel", "cancel")]

        def __init__(self, folder: str) -> None:
            super().__init__()
            self.folder = folder

        def compose(self) -> ComposeResult:
            with Vertical(classes="dialog wide"):
                yield Label(f"Send to  /{self.folder}", classes="dialog-title")
                yield Input(placeholder="type a path, or pick a recent file below")
                yield OptionList(*self._recent())
                yield Label(Text.assemble(("enter", "bold"), " send    ", ("↓", "bold"), " pick    ",
                                          ("esc", "bold"), " cancel"), classes="dialog-hint")

        def _recent(self) -> list[Option]:
            seen, files = set(), []
            for d in (Path.cwd(), HOME / "Downloads", HOME / "Documents", HOME / "Desktop", HOME):
                if not d.is_dir():
                    continue
                try:
                    for p in d.iterdir():
                        if p.suffix.lower() in UPLOADABLE and p.is_file() and p not in seen:
                            seen.add(p)
                            files.append(p)
                except OSError:
                    pass
            files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
            opts = []
            for p in files[:40]:
                where = str(p.parent).replace(str(HOME), "~", 1)
                label = Text.assemble((ICONS.get(p.suffix[1:].lower(), "") + "  "), p.name, (f"   {where}", "dim"))
                opts.append(Option(label, id=str(p)))
            if not opts:
                opts.append(Option(Text("no PDFs or EPUBs found nearby", style="dim"), disabled=True))
            return opts

        def on_key(self, ev) -> None:
            if ev.key == "down" and self.focused is self.query_one(Input):
                self.query_one(OptionList).focus()
                ev.stop()

        @on(Input.Submitted)
        def typed(self, ev: Input.Submitted) -> None:
            p = Path(ev.value.strip()).expanduser()
            if p.is_file():
                self.dismiss(p)
            else:
                self.notify("That file doesn't exist", severity="error")

        @on(OptionList.OptionSelected)
        def picked(self, ev: OptionList.OptionSelected) -> None:
            self.dismiss(Path(ev.option.id))

        def action_cancel(self) -> None:
            self.dismiss(None)

    class Remarkable(App):
        TITLE = "reMarkable"
        ENABLE_COMMAND_PALETTE = False
        CSS = """
        Screen { background: $background; }
        #top { height: 2; padding: 1 3 0 3; }
        #brand { width: auto; text-style: bold; color: $foreground; }
        #crumbs { width: 1fr; color: $text-muted; padding-left: 2; }
        #count { width: auto; color: $text-muted; }
        #search { display: none; margin: 0 3; border: round $secondary; background: $background; }
        #search.on { display: block; }
        #body { height: 1fr; padding: 1 2 0 2; }
        #files { width: 1fr; background: $background; border: none; padding: 0 1;
                 scrollbar-size-vertical: 1; scrollbar-background: $background;
                 scrollbar-background-hover: $background; scrollbar-background-active: $background;
                 scrollbar-color: $panel; scrollbar-color-hover: $secondary; scrollbar-color-active: $foreground; }
        #files:focus { background-tint: $background 0%; }
        #folderlist { color: $text-muted; padding-top: 1; }
        #files > ListItem { height: 1; padding: 0 1; background: $background; layout: horizontal; }
        #files > ListItem.-highlight { background: $primary 12%; }
        #files:focus > ListItem.-highlight { background: $primary; color: $block-cursor-foreground; }
        #files:focus > ListItem.-highlight Label { color: $block-cursor-foreground; }
        Row .icon { width: 3; color: $text-muted; }
        Row .name { width: 1fr; }
        Row .date { width: auto; color: $text-muted; }
        #side { width: 44%; max-width: 64; padding: 0 1 0 3; border-left: tall $panel; }
        #page { height: 1fr; align: center top; }
        #page Image { width: auto; height: 100%; }
        #page Static { color: $text-muted; content-align: center middle; height: 100%; }
        #page #folderlist { content-align: left top; color: $foreground; }
        #info { height: auto; padding: 1 0 1 0; }
        #empty { color: $text-muted; padding: 2 4; display: none; }
        #empty.on { display: block; }
        LoadingIndicator { color: $foreground; height: 1fr; }
        #keys { dock: bottom; height: auto; padding: 0 2; margin-top: 1; border-top: solid $panel;
                background: $background; color: $foreground; text-align: center; }
        Footer .footer-key--key { background: $background; color: $foreground; text-style: bold; }
        Footer .footer-key--description { color: $text-muted; }
        ModalScreen { align: center middle; background: $background 70%; }
        .dialog { width: 56; height: auto; padding: 1 3; border: round $foreground; background: $background; }
        .dialog.wide { width: 90; max-height: 80%; }
        .dialog OptionList { height: auto; max-height: 20; border: none; margin-top: 1; background: $background; }
        .dialog Input { border: round $secondary; background: $background; margin-top: 1; }
        .dialog-title { text-style: bold; }
        .dialog-detail { color: $text-muted; margin-top: 1; }
        .dialog-hint { color: $text-muted; margin-top: 1; }
        """

        BINDINGS = [
            Binding("enter", "open", "open", show=False),
            Binding("right,l", "enter", "", show=False),
            Binding("left,h,backspace", "back", "back"),
            Binding("j", "cursor('down')", "", show=False),
            Binding("k", "cursor('up')", "", show=False),
            Binding("d", "download", "download"),
            Binding("o", "view", "view"),
            Binding("u", "upload", "send"),
            Binding("n", "mkdir", "folder"),
            Binding("r", "rename", "rename"),
            Binding("x,delete", "delete", "delete"),
            Binding("slash", "search", "search"),
            Binding("escape", "clear_search", "", show=False),
            Binding("ctrl+r", "refresh", "", show=False),
            Binding("q", "quit", "quit"),
        ]

        def __init__(self) -> None:
            super().__init__()
            self.folder = ""
            self.all_entries: list[Entry] | None = None
            self.preview_token = 0
            self._preview_timer = None
            self.cursor_memory: dict[str, str] = {}

        # layout

        def compose(self) -> ComposeResult:
            with Horizontal(id="top"):
                yield Label(Text.assemble(("◆ ", "dim"), "reMarkable"), id="brand")
                yield Label("", id="crumbs")
                yield Label("", id="count")
            yield Input(placeholder="search everything…", id="search")
            with Horizontal(id="body"):
                with Vertical():
                    yield ListView(id="files")
                    yield Label("this folder is empty", id="empty")
                with Vertical(id="side"):
                    yield Vertical(id="page")
                    yield Static("", id="info")
            yield Static(self.controls(), id="keys")

        @staticmethod
        def controls() -> Text:
            groups = [
                [("↑↓", "move"), ("↵", "open"), ("←", "back"), ("/", "search"), ("esc", "clear")],
                [("d", "download"), ("o", "view"), ("u", "send"), ("n", "new folder"),
                 ("r", "rename"), ("x", "delete"), ("q", "quit")],
            ]
            t = Text(justify="center")
            for gi, group in enumerate(groups):
                if gi:
                    t.append("\n")
                for i, (key, desc) in enumerate(group):
                    if i:
                        t.append("    ")
                    t.append(key, style="bold")
                    t.append(f" {desc}", style="dim")
            return t

        def on_mount(self) -> None:
            for t in THEMES.values():
                self.register_theme(t)
            rice = rice_theme()
            self.theme = {"bw": "ink", "invert": "paper"}.get(rice, "catppuccin-mocha" if "cat" in rice else "ink")
            self.load(self.folder)

        # data

        @property
        def files(self) -> ListView:
            return self.query_one("#files", ListView)

        @property
        def current(self) -> Entry | None:
            item = self.files.highlighted_child
            return item.entry if isinstance(item, Row) else None

        @work(thread=True, exclusive=True, group="list")
        def load(self, folder: str, select: str | None = None) -> None:
            self.call_from_thread(setattr, self.files, "loading", True)
            try:
                entries = list_folder(folder)
            except RmError as e:
                self.call_from_thread(self.notify, str(e), title="couldn't load", severity="error")
                entries = None
            self.call_from_thread(self.show, folder, entries, select)

        async def show(self, folder: str, entries: list[Entry] | None, select: str | None = None,
                       searching: bool = False) -> None:
            self.files.loading = False
            if entries is None:
                return
            if not searching:
                self.folder = folder
            await self.files.clear()
            await self.files.extend(Row(e, show_folder=searching) for e in entries)
            index = 0
            want = select or self.cursor_memory.get(folder)
            for i, e in enumerate(entries):
                if e.path == want or e.name == want:
                    index = i
                    break
            if entries:
                self.files.index = index
            self.query_one("#empty").set_class(not entries, "on")
            self.query_one("#empty", Label).update("nothing matches" if searching else "this folder is empty")
            crumbs = Text()
            parts = folder.split("/") if folder else []
            for i, part in enumerate(parts):
                crumbs.append("›  ", style="dim")
                crumbs.append(part + "  ", style="bold" if i == len(parts) - 1 else "")
            self.query_one("#crumbs", Label).update(Text("search", style="dim") if searching else crumbs)
            n = len(entries)
            self.query_one("#count", Label).update(f"{n} item{'s' if n != 1 else ''}")
            if not searching:
                self.files.focus()
            if not entries:
                self.query_one("#info", Static).update("")
                self.clear_preview("")
            else:
                self.call_after_refresh(self.refresh_preview)

        # preview

        @on(ListView.Highlighted, "#files")
        def highlighted(self, ev: ListView.Highlighted) -> None:
            self.refresh_preview()

        def refresh_preview(self) -> None:
            e = self.current
            if e is not None and getattr(self, "_previewing", None) is e:
                return
            self._previewing = e
            if e is None:
                return
            self.cursor_memory[self.folder] = e.path
            self.preview_token += 1
            self.render_info(e)
            if e.is_dir:
                self.clear_preview("")
                self.peek_folder(e, self.preview_token)
                return
            if self._preview_timer:
                self._preview_timer.stop()
            token = self.preview_token
            self._preview_timer = self.set_timer(0.3, lambda: self.load_preview(e, token))

        def render_info(self, e: Entry, doc: Doc | None = None) -> None:
            t = Text()
            t.append(e.name + "\n", style="bold")
            kind = {"folder": "folder", "trash": "trash", "notebook": "notebook", "pdf": "PDF",
                    "epub": "EPUB"}.get(doc.kind if doc else e.kind, "document")
            bits = [kind]
            if doc and doc.kind == "notebook":
                n = len(doc.pages)
                bits.append(f"{n} page{'s' if n != 1 else ''}")
            elif doc and doc.content.get("pageCount"):
                bits.append(f"{doc.content['pageCount']} pages")
            if e.modified:
                bits.append(f"edited {when(e.modified)}")
            t.append("  ·  ".join(bits), style="dim")
            if e.folder:
                t.append(f"\n/{e.folder}", style="dim")
            self.query_one("#info", Static).update(t)

        def clear_preview(self, glyph: str, big: bool = False) -> None:
            page = self.query_one("#page")
            page.remove_children()
            if glyph:
                page.mount(Static(Text(glyph, style="dim")))

        @work(thread=True, group="peek", exclusive=True)
        def peek_folder(self, e: Entry, token: int) -> None:
            try:
                kids = list_folder(e.path)
            except RmError:
                return

            def place() -> None:
                if token != self.preview_token:
                    return
                t = Text()
                for k in kids[:24]:
                    t.append(f"{k.icon}  ", style="dim")
                    t.append(k.name + "\n", style="bold" if k.is_dir else "")
                if len(kids) > 24:
                    t.append(f"\n+ {len(kids) - 24} more", style="dim")
                if not kids:
                    t.append("empty", style="dim")
                page = self.query_one("#page")
                page.remove_children()
                page.mount(Static(t, id="folderlist"))
                n = len(kids)
                info = Text(e.name + "\n", style="bold")
                bits = ["folder", f"{n} item{'s' if n != 1 else ''}"]
                if e.modified:
                    bits.append(f"edited {when(e.modified)}")
                info.append("  ·  ".join(bits), style="dim")
                self.query_one("#info", Static).update(info)

            self.call_from_thread(place)

        def load_preview(self, e: Entry, token: int) -> None:
            if token != self.preview_token:
                return
            page = self.query_one("#page")
            page.remove_children()
            page.mount(LoadingIndicator())
            self.fetch_preview(e, token)

        @work(thread=True, group="preview")
        def fetch_preview(self, e: Entry, token: int) -> None:
            try:
                doc = fetch(e.path)
                png = preview_png(doc)
            except Exception as ex:  # noqa: BLE001 - previews must never crash the app
                doc, png = None, None
                err = str(ex)
            else:
                err = ""
            self.call_from_thread(self.place_preview, e, token, doc, png, err)

        def place_preview(self, e: Entry, token: int, doc: Doc | None, png: Path | None, err: str) -> None:
            if token != self.preview_token:
                return
            page = self.query_one("#page")
            page.remove_children()
            if doc:
                self.render_info(e, doc)
                for row in self.files.query(Row):
                    if row.entry.path == e.path:
                        row.query_one(".icon", Label).update(e.icon)
            if png and PageImage is not None:
                page.mount(PageImage(str(png)))
            elif err:
                page.mount(Static(Text(f"no preview\n{err}", style="dim")))
            else:
                page.mount(Static(Text(e.icon, style="dim")))

        # navigation

        def action_cursor(self, direction: str) -> None:
            (self.files.action_cursor_down if direction == "down" else self.files.action_cursor_up)()

        @on(ListView.Selected, "#files")
        def selected(self, ev: ListView.Selected) -> None:
            self.action_open()

        def action_open(self) -> None:
            if isinstance(self.focused, Input):
                return
            e = self.current
            if e is None:
                return
            if e.is_dir:
                self.go(e.path)
            else:
                self.action_view()

        def action_enter(self) -> None:
            e = self.current
            if e and e.is_dir:
                self.go(e.path)

        def go(self, folder: str, select: str | None = None) -> None:
            self.close_search()
            self.load(folder, select)

        def action_back(self) -> None:
            if self.searching:
                self.action_clear_search()
                return
            if not self.folder:
                return
            parent, _, _ = self.folder.rpartition("/")
            self.go(parent, select=self.folder)

        def action_refresh(self) -> None:
            self.all_entries = None
            self.load(self.folder, self.current.path if self.current else None)

        # search

        @property
        def searching(self) -> bool:
            return self.query_one("#search").has_class("on")

        def action_search(self) -> None:
            box = self.query_one("#search", Input)
            box.add_class("on")
            box.focus()
            if self.all_entries is None:
                self.index_everything()

        @work(thread=True, group="index")
        def index_everything(self) -> None:
            try:
                found = find_all()
            except RmError as e:
                self.call_from_thread(self.notify, str(e), severity="error")
                return
            self.all_entries = found
            self.call_from_thread(self.run_search)

        @on(Input.Changed, "#search")
        async def run_search(self, ev: Input.Changed | None = None) -> None:
            q = self.query_one("#search", Input).value.strip().lower()
            if not q:
                self.load(self.folder)
                return
            if self.all_entries is None:
                return
            words = q.split()
            hits = [e for e in self.all_entries if all(w in e.path.lower() for w in words)]
            hits.sort(key=lambda e: (not e.name.lower().startswith(words[0]), not e.is_dir, e.path.lower()))
            await self.show(self.folder, hits[:200], searching=True)

        @on(Input.Submitted, "#search")
        def search_done(self, ev: Input.Submitted) -> None:
            self.files.focus()

        def on_key(self, ev) -> None:
            if ev.key == "down" and self.focused is self.query_one("#search"):
                self.files.focus()
                ev.stop()

        def close_search(self) -> None:
            box = self.query_one("#search", Input)
            box.remove_class("on")
            box.value = ""

        def action_clear_search(self) -> None:
            if self.searching:
                self.close_search()
                self.load(self.folder)

        # actions

        def action_download(self) -> None:
            e = self.current
            if e is None or e.is_dir:
                self.notify("Pick a document to download", severity="warning")
                return
            self.export(e, DOWNLOADS, open_after=False)

        def action_view(self) -> None:
            e = self.current
            if e is None or e.is_dir:
                return
            self.export(e, CACHE / "open", open_after=True)

        @work(thread=True, group="export")
        def export(self, e: Entry, dest: Path, open_after: bool) -> None:
            verb = "opening" if open_after else "downloading"
            self.call_from_thread(self.notify, f"{verb} {e.name}…", timeout=2)
            try:
                out = to_pdf(fetch(e.path), dest)
            except Exception as ex:  # noqa: BLE001
                self.call_from_thread(self.notify, str(ex), title=f"couldn't export {e.name}", severity="error")
                return
            if open_after:
                subprocess.Popen(["xdg-open", str(out)], stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL, start_new_session=True)
            else:
                shown = str(out).replace(str(HOME), "~", 1)
                self.call_from_thread(self.notify, shown, title="saved")

        def action_upload(self) -> None:
            folder = self.folder

            def chosen(path: Path | None) -> None:
                if path:
                    self.send(path, folder)

            self.push_screen(Upload(folder), chosen)

        @work(thread=True, group="mutate")
        def send(self, path: Path, folder: str) -> None:
            self.call_from_thread(self.notify, f"sending {path.name}…", timeout=2)
            try:
                rmapi("put", str(path), *([folder] if folder else []))
            except RmError as e:
                self.call_from_thread(self.notify, str(e), title="couldn't send", severity="error")
                return
            self.call_from_thread(self.notify, f"{path.name} is on your tablet", title="sent")
            self.all_entries = None
            if self.folder == folder:
                self.call_from_thread(self.load, folder, path.stem)

        def action_mkdir(self) -> None:
            folder = self.folder

            def named(name: str | None) -> None:
                if name:
                    self.mutate(("mkdir", join(folder, name)), f"made {name}", select=join(folder, name))

            self.push_screen(Prompt("New folder", placeholder="name"), named)

        def action_rename(self) -> None:
            e = self.current
            if e is None or e.is_trash:
                return

            def named(name: str | None) -> None:
                if name and name != e.name:
                    self.mutate(("mv", e.path, join(e.folder, name)), f"renamed to {name}",
                                select=join(e.folder, name))

            self.push_screen(Prompt("Rename", value=e.name), named)

        def action_delete(self) -> None:
            e = self.current
            if e is None or e.is_trash:
                return
            in_trash = e.folder == "trash" or e.folder.startswith("trash/")
            if in_trash:
                title, detail = f"Delete {e.name} forever?", "It's already in the trash, so this can't be undone."
                cmd = ("rm", "-r", e.path) if e.is_dir else ("rm", e.path)
                msg = f"deleted {e.name}"
            else:
                title, detail = f"Move {e.name} to the trash?", "You can get it back from the trash on your tablet."
                cmd = ("mv", e.path, "trash")
                msg = f"{e.name} moved to trash"

            def answered(yes: bool) -> None:
                if yes:
                    self.mutate(cmd, msg)

            self.push_screen(Confirm(title, detail), answered)

        @work(thread=True, group="mutate")
        def mutate(self, cmd: tuple[str, ...], message: str, select: str | None = None) -> None:
            try:
                rmapi(*cmd)
            except RmError as e:
                self.call_from_thread(self.notify, str(e), severity="error")
                return
            self.all_entries = None
            self.call_from_thread(self.notify, message)
            self.call_from_thread(self.load, self.folder, select)

    if PageImage is not None:
        # textual-image needs to probe the terminal before the app takes over
        try:
            import textual_image.renderable  # noqa: F401
        except Exception:
            pass
    Remarkable().run()


def main() -> int:
    if len(sys.argv) > 1:
        return cli(sys.argv[1:])
    run_app()
    return 0


if __name__ == "__main__":
    sys.exit(main())

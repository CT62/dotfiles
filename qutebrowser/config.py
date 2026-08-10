config.load_autoconfig()

c.url.searchengines = {"DEFAULT": "https://www.google.com/search?q={}"}

c.url.start_pages = ["https://www.google.com"]
c.url.default_page = "https://www.google.com"

# Follow the rice's active theme (bw / invert) — same state file
# ~/.config/rice/toggle-theme.sh writes, reloaded via :config-source.
import pathlib

_theme_file = pathlib.Path.home() / ".config/rice/theme"
_theme = _theme_file.read_text().strip() if _theme_file.exists() else "bw"

if _theme == "invert":
    bg, fg, accent = "#FFFFFF", "#000000", "#000000"
else:
    bg, fg, accent = "#000000", "#FFFFFF", "#FFFFFF"

c.fonts.default_family = "Cascadia Mono NF"

c.colors.completion.fg = fg
c.colors.completion.odd.bg = bg
c.colors.completion.even.bg = bg
c.colors.completion.category.fg = accent
c.colors.completion.category.bg = bg
c.colors.completion.item.selected.fg = bg
c.colors.completion.item.selected.bg = accent
c.colors.completion.item.selected.border.top = accent
c.colors.completion.item.selected.border.bottom = accent
c.colors.completion.scrollbar.fg = fg
c.colors.completion.scrollbar.bg = bg

c.colors.statusbar.normal.bg = bg
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.command.bg = bg
c.colors.statusbar.command.fg = fg
c.colors.statusbar.url.fg = fg
c.colors.statusbar.url.success.http.fg = fg
c.colors.statusbar.url.success.https.fg = fg
c.colors.statusbar.insert.bg = accent
c.colors.statusbar.insert.fg = bg

c.colors.tabs.bar.bg = bg
c.colors.tabs.odd.bg = bg
c.colors.tabs.even.bg = bg
c.colors.tabs.odd.fg = fg
c.colors.tabs.even.fg = fg
c.colors.tabs.selected.odd.bg = accent
c.colors.tabs.selected.even.bg = accent
c.colors.tabs.selected.odd.fg = bg
c.colors.tabs.selected.even.fg = bg
c.colors.tabs.indicator.start = accent
c.colors.tabs.indicator.stop = accent

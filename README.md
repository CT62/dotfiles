# dotfiles

My full i3 rice: window manager, bars, terminal, browser, notifications,
launcher, compositor, lock screen, and wallpapers — three swappable themes
(bw / invert / catppuccin) that toggle together across all of it.

## Install (Fedora)

```
./install.sh
```

This installs every package the rice needs via `dnf`, then symlinks each
folder here into place under `~/.config` (and the wallpapers into
`~/Downloads`), backing up anything already there first.

On another distro: install the equivalent packages yourself (see
`install.sh` for the full list) and symlink the folders the same way.

After installing, log out and back into i3, or run
`~/.config/rice/toggle-theme.sh` twice to force every app to reload.

## What's in here

| Folder | What it is |
| --- | --- |
| `i3/` | Window manager config + per-theme border/title colors |
| `polybar/` | Top bar (workspaces, temp, now-playing, cpu/mem, date) and bottom bar (duf-style `/` usage, uptime, volume, battery) |
| `kitty/` | Terminal config + per-theme colors |
| `dunst/` | Notification daemon config, per theme |
| `rofi/` | Launcher, calculator, emoji picker, clipboard picker (scripts + per-theme `.rasi`) |
| `qutebrowser/` | Browser config (theme-aware, reads `rice/theme`) |
| `picom/` | Compositor: fades, shadows, rounded corners, open/close animations |
| `gammastep/` | Fixed dawn/dusk color temperature schedule |
| `flameshot/` | Screenshot tool config |
| `rice/` | The glue: `toggle-theme.sh` (cycles bw → invert → catppuccin across everything), `set-wallpaper.sh`, lock screen, on-screen volume/brightness display, workspace layout save/restore, scratchpad terminal, focus-border pulse, Obsidian theme CSS |
| `wallpapers/` | Images `set-wallpaper.sh` picks from at random — `wallpaper/` for the catppuccin theme, `wallpaper-bw/` for bw/invert |

## Not included / external

These are referenced by scripts here but aren't part of this repo — install
or configure them separately if you use them:

- **google-chrome-stable** — not in Fedora's repos; `rice/chrome-launch.sh`
  launches it with dark-mode flags matched to the active theme.
- **spicetify** — Spotify theming; `rice/toggle-theme.sh` calls
  `~/.spicetify/spicetify` if it exists, no-ops otherwise.
- **Obsidian** — `rice/obsidian/theme-*.css` gets copied into a vault's
  theme folder on toggle. `rice/toggle-theme.sh` hardcodes the vault path
  (`/home/clive/code/course/comp sci`) — edit that line to point at your own
  vault, or leave it; it's skipped if the folder doesn't exist.
- **copyq clipboard history** — the app is installed (used for the
  `$mod+Shift+v` picker), but its own state/history isn't shipped here.

## Keybindings

See `i3/config` for the full list. The highlights: `$mod+d` rofi launcher,
`$mod+Shift+t` cycle theme, `$mod+Shift+v` clipboard history,
`` $mod+` `` scratchpad terminal, `$mod+Shift+y` / `$mod+y` save/restore
layout, `$mod+Shift+s` region screenshot to clipboard, `Print` flameshot.

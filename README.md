# polybar-dotfiles

My i3 + polybar setup: a top bar and a bottom bar.

**Top bar** — workspaces, temperature, now-playing/window title (center), failed
systemd units, mic-mute indicator, CPU, memory, date, power menu, tray.

**Bottom bar** — a duf-style usage bar for `/`, uptime, volume, battery.

Color themes (bw / invert / catppuccin) live in `colors-*.ini`; `colors.ini`
is the active one, swapped in by a theme toggler that isn't part of this repo.

## Install (Fedora)

```
./install.sh
```

This installs the required packages via `dnf` and symlinks `polybar/` to
`~/.config/polybar`. Then start the bars with:

```
~/.config/polybar/launch.sh
```

On another distro, install the equivalent packages yourself (see
`install.sh` for the list) and either run `ln -sfn "$(pwd)/polybar"
~/.config/polybar` or copy the folder there directly.

## Dependencies

`polybar`, `i3` (for `i3-msg`), `playerctl`, `pulseaudio-utils` (`pactl`),
`bluez` (`bluetoothctl`), `jq`, `rofi`, `kitty`, and the Cascadia Mono Nerd
Font (`cascadia-mono-nf-fonts` on Fedora).

`powermenu.sh` calls `rofi` with a theme at `~/.config/rofi/current.rasi`,
which lives outside this repo — point it at your own rofi theme or edit
that line out if you don't use rofi.

## Files

- `config.ini` — bar and module definitions
- `colors*.ini` — color themes
- `launch.sh` — (re)starts both bars
- `storage.sh` — duf-style `/` usage bar for the bottom bar
- `uptime.sh`, `bluetooth.sh`, `failed-units.sh`, `mic-mute.sh`,
  `now-playing.sh`, `powermenu.sh` — module scripts

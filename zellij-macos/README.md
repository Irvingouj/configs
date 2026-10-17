# Zellij (macOS)

macOS copy of `../zellij/config.kdl`. Same keybinds, layouts and Solarized
light/dark themes; only the OS-specific bits differ.

macOS config location:

```sh
~/.config/zellij
```

## Differences from the Windows config

- `default_shell "/bin/zsh"` instead of `nu.exe`
- `copy_command "pbcopy"` enabled for the system clipboard
- the `zellij-agent-resume.wasm` plugin is not loaded (the file is not in this
  repo and does not exist on macOS)
- `zellij-autolock.wasm` is shipped under `plugins/` but, as on Windows, is not
  loaded by `config.kdl`

## Install

```sh
mkdir -p ~/.config/zellij
cp -R config.kdl layouts themes plugins ~/.config/zellij/
```

## Light/dark theme

`config.kdl` declares `theme_dark "solarized-dark"`,
`theme_light "solarized-light-paper"` and `explicit_theme_hue`. Alacritty does
not reliably report the OS appearance, so run the helper to rewrite the hue:

```sh
./follow-os-theme.sh          # once
./follow-os-theme.sh --watch  # keep following
```

Zellij live-reloads `config.kdl`, so no restart is needed.

## Validate

```sh
zellij --config-dir ~/.config/zellij setup --check
```

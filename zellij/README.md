# Zellij

Windows config location. macOS users: see [`../zellij-macos/`](../zellij-macos/).

```powershell
C:\Users\jou\AppData\Roaming\Zellij\config
```

This setup uses:

- `layouts/default.kdl` with a top `zellij:compact-bar` and no bottom bar
- native Zellij `Ctrl+g` lock/unlock
- `nvim` as the scrollback editor
- Solarized light/dark that follows the OS, switched by `../alacritty/follow-os-theme.nu` rewriting `explicit_theme_hue`
- `Alt` + arrows to move pane focus, also in locked mode

`zellij-autolock.wasm` may exist under `plugins/`, but it is not loaded by `config.kdl`.

Validate after restoring:

```powershell
zellij --config-dir 'C:\Users\jou\AppData\Roaming\Zellij\config' setup --check
```

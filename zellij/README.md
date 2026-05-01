# Zellij

Windows config location:

```powershell
C:\Users\jou\AppData\Roaming\Zellij\config
```

This setup uses:

- `layouts/default.kdl` with a top `zellij:compact-bar` and no bottom bar
- native Zellij `Ctrl+g` lock/unlock
- `nvim` as the scrollback editor

`zellij-autolock.wasm` may exist under `plugins/`, but it is not loaded by `config.kdl`.

Validate after restoring:

```powershell
zellij --config-dir 'C:\Users\jou\AppData\Roaming\Zellij\config' setup --check
```

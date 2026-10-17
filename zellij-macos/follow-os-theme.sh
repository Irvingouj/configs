#!/bin/bash
# Keep Zellij on the Solarized paper/dark theme that matches macOS appearance.
#
# Alacritty does not reliably report the OS light/dark mode to Zellij, so this
# rewrites `explicit_theme_hue` in config.kdl. Zellij live-reloads the config.
#
# Usage:
#   ./follow-os-theme.sh          # apply once
#   ./follow-os-theme.sh --watch  # keep following (polls every 2s)
set -u

CONFIG="${ZELLIJ_CONFIG:-${HOME}/.config/zellij/config.kdl}"

appearance() {
  # `defaults read -g AppleInterfaceStyle` is the cached pref (missing = light).
  local mode
  mode="$(defaults read -g AppleInterfaceStyle 2>/dev/null || true)"
  if [[ "${mode}" == "Dark" ]]; then
    echo dark
  else
    echo light
  fi
}

apply() {
  local hue="$1"
  [[ -f "${CONFIG}" ]] || return 0
  python3 - "${CONFIG}" "${hue}" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
hue = sys.argv[2]
text = path.read_text()
updated, n = re.subn(r'^explicit_theme_hue ".*"', f'explicit_theme_hue "{hue}"', text, count=1, flags=re.M)
if n and updated != text:
    path.write_text(updated)
    print(f"zellij explicit_theme_hue: {hue}")
PY
}

apply "$(appearance)"

if [[ "${1:-}" != "--watch" ]]; then
  exit 0
fi

last="$(appearance)"
while true; do
  sleep 2
  mode="$(appearance)"
  if [[ "${mode}" != "${last}" ]]; then
    apply "${mode}"
    last="${mode}"
  fi
done

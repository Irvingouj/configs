"""Mark the zellij tab that holds this agent with " (!)" when it needs attention.

Usage: zellij_attn.py on|off
Used by Claude Code hooks and the OpenCode plugin opencode/plugins/zellij-attn/tui.ts.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

MARK = " (!)"


def zellij_json(*args: str):
    out = subprocess.run(["zellij", "action", *args, "-j"], capture_output=True, encoding="utf-8", timeout=5).stdout
    return json.loads(out)


def main() -> None:
    pane = os.environ.get("ZELLIJ_PANE_ID", "").removeprefix("terminal_")
    if not pane or len(sys.argv) != 2 or sys.argv[1] not in ("on", "off"):
        return
    state = sys.argv[1]

    # "off" runs after every tool call, so skip the zellij round trip unless this pane marked its tab.
    flag = Path(tempfile.gettempdir()) / f"zellij-attn-{os.environ.get('ZELLIJ_SESSION_NAME', '')}-{pane}"
    if state == "off" and not flag.exists():
        return

    tab = next((p for p in zellij_json("list-panes", "-t") if not p["is_plugin"] and str(p["id"]) == pane), None)
    if tab is None:
        return

    if state == "on" and any(t["tab_id"] == tab["tab_id"] and t["active"] for t in zellij_json("list-tabs")):
        return

    name = tab["tab_name"]
    base = name.removesuffix(MARK)
    new = base + MARK if state == "on" else base
    if new != name:
        subprocess.run(["zellij", "action", "rename-tab", "-t", str(tab["tab_id"]), new], timeout=5)
    if state == "on":
        flag.touch()
    else:
        flag.unlink(missing_ok=True)


if __name__ == "__main__":
    main()

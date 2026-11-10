import json, os, subprocess, sys

cwd = json.load(sys.stdin).get("cwd") or os.getcwd()
try:
    top = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"], capture_output=True, text=True, timeout=5).stdout.strip()
except Exception:
    top = ""
root = top or cwd
parts = []
for name, tail in (("INTENT.md", None), ("DECISIONS.md", 150)):
    path = os.path.join(root, name)
    if os.path.isfile(path):
        lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
        if tail:
            lines = lines[-tail:]
        parts.append(f"=== {path} ===\n" + "\n".join(lines))
if parts:
    msg = "The conversation was just compacted. These are Irving's recorded rulings for this repo; the code must follow them:\n\n" + "\n\n".join(parts)
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": msg}}))

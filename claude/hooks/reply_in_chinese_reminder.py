import json, sys
from pathlib import Path

data = json.loads(sys.stdin.buffer.read().decode("utf-8") or "{}")
counter = Path(__file__).parent / "state" / f"zh-{data.get('session_id', 'unknown')}.txt"
slips = int(counter.read_text() or 0) if counter.exists() else 0

msg = "Reply in Simplified Chinese. Code, identifiers and text to be posted stay as-is."
if slips:
    msg += (f" You already replied in English {slips} time(s) in this session and had to rewrite."
            " Write this reply in Chinese from the first word, even if it is a long report or table.")
print(msg)

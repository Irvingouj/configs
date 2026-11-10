import json, re, sys
from pathlib import Path

STATE = Path(__file__).parent / "state"
STRIP = re.compile(r"```.*?```|`[^`]*`|\[[^\]]*\]\([^)]*\)|https?://\S+|\S*[\\/]\S*|^>.*$", re.S | re.M)


def is_english(reply: str) -> bool:
    text = STRIP.sub(" ", reply)
    if re.search(r"[㐀-鿿]", text.strip()[:40]):
        return False
    cjk = len(re.findall(r"[㐀-鿿]", text))
    words = len(re.findall(r"[A-Za-z]{2,}", text))
    return words >= 3 and cjk < words


if __name__ == "__main__":
    data = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    if data.get("stop_hook_active") or not is_english(data.get("last_assistant_message") or ""):
        sys.exit(0)
    STATE.mkdir(exist_ok=True)
    counter = STATE / f"zh-{data.get('session_id', 'unknown')}.txt"
    slips = int(counter.read_text() or 0) + 1 if counter.exists() else 1
    counter.write_text(str(slips))
    print(json.dumps({"decision": "block", "reason": (
        f"Your last reply to Irving was mostly English (slip #{slips} in this session). "
        "Rewrite it now in Simplified Chinese. Keep code, identifiers, commands and text meant to be posted as-is. "
        "From now on, write EVERY reply in this session in Simplified Chinese from the first word, "
        "including long reports, tables and status updates. Never draft in English first."
    )}))

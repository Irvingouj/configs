import json, re, sys

OFFER = re.compile(
    r"(要不要我|需不需要我|是否需要我|是否要我|要我|需要我|我可以|我来|我去|我先)[^。！？?\n]{0,60}[吗么呢]?\s*[？?]"
    r"|你(要|想要|希望)我[^。！？?\n]{0,60}[？?]"
    r"|(你说一句|你回复?|回复|告诉我)[^。！？?\n]{0,40}(我就|就|它就)"
    r"|(的话|就)告诉我[。.]?\s*$"
    r"|\b(want me to|should I|shall I|do you want me to|would you like me to|let me know if you want)\b[^\n]{0,120}",
    re.I,
)
DECISION = re.compile(r"需要你决定|需要你拍板|Needs your decision", re.I)


def verdict(reply: str) -> bool:
    text = re.sub(r"```.*?```", " ", reply, flags=re.S).strip()
    tail = "\n".join(text.splitlines()[-3:])
    return bool(OFFER.search(tail)) and not DECISION.search(text)


if __name__ == "__main__":
    data = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    if data.get("stop_hook_active") or not verdict(data.get("last_assistant_message") or ""):
        sys.exit(0)
    print(json.dumps({"decision": "block", "reason": (
        "Your reply ends by asking Irving whether you should do something. Apply the i-before-asking skill now. "
        "If the step is reversible, inside the task he gave and not a merge, a message to a person, or a design ruling: "
        "do it now, then report what you did. "
        "If it truly needs him, rewrite the ending as a section titled '需要你决定' with: background assuming he read nothing, "
        "current state, 2-4 options with what each costs or risks, and your pick. Ask only one decision."
    )}))

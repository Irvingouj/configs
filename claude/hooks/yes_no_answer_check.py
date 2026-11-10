import json, re, sys

TAGS = re.compile(r"<(system-reminder|pasted_content|command-[a-z]+|local-command-[a-z]+)[^>]*>.*?</\1[^>]*>", re.S)
EN_QUESTION = re.compile(
    r"^(is|are|was|were|am|do|does|did|can|could|will|would|should|shall|has|have|had|must|may|might)"
    r"(n't|\s+not)?\b[^\n]*\?",
    re.I,
)
ZH_QUESTION = re.compile(r"[吗么][？?]?\s*$|是不是|有没有|能不能|会不会|对不对|要不要|行不行|可不可以|是否")
ANSWER = re.compile(
    r"^(yes|no|wrong question|是|否|不是|对|不对|有|没有|会|不会|能|不能|可以|不可以|行|不行|要|不要|问题问错了|问错了)",
    re.I,
)


def last_user_text(transcript_path: str) -> str:
    text = ""
    with open(transcript_path, encoding="utf-8") as f:
        for line in f:
            entry = json.loads(line)
            if entry.get("type") != "user" or entry.get("isMeta"):
                continue
            content = entry.get("message", {}).get("content")
            if isinstance(content, list):
                parts = [b.get("text", "") for b in content if b.get("type") == "text"]
                if not parts:
                    continue
                content = "\n".join(parts)
            if not isinstance(content, str):
                continue
            cleaned = TAGS.sub(" ", content).strip()
            if cleaned and not cleaned.startswith("[Request interrupted"):
                text = cleaned
    return text


def is_yes_no(question: str) -> bool:
    return any(EN_QUESTION.search(s.strip()) for s in re.split(r"(?<=[?？.!])\s+|\n", question)) or bool(
        ZH_QUESTION.search(question)
    )


def starts_with_answer(reply: str) -> bool:
    return bool(ANSWER.match(re.sub(r"^[\s*#>_`\-]+", "", reply)))


if __name__ == "__main__":
    data = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    if data.get("stop_hook_active"):
        sys.exit(0)
    question = last_user_text(data.get("transcript_path") or "")
    if not is_yes_no(question) or starts_with_answer(data.get("last_assistant_message") or ""):
        sys.exit(0)
    print(json.dumps({"decision": "block", "reason": (
        "Irving asked a yes/no question. Rewrite your reply so its first word is the answer: "
        "'yes' / 'no' / 'wrong question', or in Chinese '是' / '不是' / '对' / '不对' / '有' / '没有' / '会' / '不会' / "
        "'能' / '不能' / '问题问错了'. Use 'wrong question' (问题问错了) when neither yes nor no is true, "
        "then say in one line what the right question is. Put the explanation after the answer."
    )}))

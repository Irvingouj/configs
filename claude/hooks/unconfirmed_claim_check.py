import json, os, re, sys, urllib.request

LINE = "The input is a reply an AI assistant wrote to its user. Judge only this one line of it:\n<line>{line}</line>\n"
QUOTES = " False for section headings and for lines that only quote, test or discuss such phrases."
LINE_QUESTIONS = {
    "unconfirmed": LINE + (
        "True when this line states or relies on something while admitting the assistant did not check it "
        '(for example: "I have not confirmed", "not verified yet", "I did not check", "I assume", '
        '"should work" without a test, "未确认", "还没验证", "没有核实", "没有观察", "应该是"). '
        'False when the line says the assistant is unable to confirm ("cannot confirm", "无法确认", "没法证实"). '
        "False when the line reports what an attempt the assistant actually made returned, "
        "even if that attempt failed or was inconclusive. "
        "False for plans, questions to the user, and a hypothesis the reply says it will verify next." + QUOTES
    ),
    "cannot": LINE + (
        "True only when this line says it is impossible for the assistant to confirm, verify or prove something "
        '(for example: "cannot confirm", "unable to verify", "无法确认", "没法证实", "无法验证"). '
        'False when the line only says the assistant has not checked yet ("have not verified", "还没确认", "unverified"). '
        "False for a hypothesis the assistant will verify next, and when the line only reports what one attempt returned."
        + QUOTES
    ),
    "asks": LINE + (
        "True when this line asks or tells the user to perform an action by hand: click something, run a command, "
        "open a page, log in, change a setting, check or test something, send something. "
        "False when the line only asks the user for a decision, a preference, an approval or information." + QUOTES
    ),
}
REPLY_QUESTIONS = {
    "two_routes": (
        "The input is a reply an AI assistant wrote to its user. The reply says the assistant cannot confirm something. "
        "Does the reply describe two or more separate attempts the assistant already made to confirm it "
        "(for example: it read a file, ran a command, searched the docs, called an API)?"
    ),
    "tried_itself": (
        "The input is a reply an AI assistant wrote to its user. The reply asks the user to do something by hand. "
        "Does the reply also describe an attempt the assistant already made to do that thing itself, "
        "or explain why the assistant cannot do it itself?"
    ),
}
RULES = {
    "unconfirmed": (None, (
        "Your reply contains statements you admit you did not confirm:\n{lines}\n"
        "Irving forbids 'not confirmed'. Only two states are allowed: confirmed, or unable to confirm. "
        "Confirm each statement now: read the code, run the command, open the reference."
    )),
    "cannot": ("two_routes", (
        "Your reply says you cannot confirm something without listing two routes you tried:\n{lines}\n"
        "Irving forbids 'cannot confirm' until you have tried at least two different routes. "
        "Try two routes now for each statement (for example: read the code, run it, search the docs, query the API, "
        "check the knowledge base). If one confirms it, report it as confirmed with the evidence. "
        "If both fail, say 'unable to confirm' and list each route you tried and what it returned."
    )),
    "asks": ("tried_itself", (
        "Your reply asks Irving to do something by hand without saying what you tried yourself:\n{lines}\n"
        "Irving forbids this until you have tried at least one way of doing it yourself. Try now: "
        "the browser (chrome-devtools or agent-browser), the terminal, an API, an MCP tool. "
        "If it works, do it and report. If it fails, say what you tried, what it returned, "
        "and why neither the browser nor the terminal can do it, then ask."
    )),
}
ENDING = "Then explain again cleanly: lead with the conclusion, and give each claim with its evidence."


def probabilities(reply: str) -> tuple[list[str], dict[str, float]]:
    prose = re.sub(r"```.*?```", "", reply, flags=re.S)
    lines = [l.strip() for l in prose.splitlines() if len(l.strip()) >= 8][:130]
    questions = [
        {"type": "predicate", "name": f"{kind}:{i}", "instructions": question.format(line=line)}
        for i, line in enumerate(lines)
        for kind, question in LINE_QUESTIONS.items()
    ] + [{"type": "predicate", "name": name, "instructions": question} for name, question in REPLY_QUESTIONS.items()]
    request = urllib.request.Request(
        "https://api.openai.com/v1/decisions",
        data=json.dumps({"model": "gpt-6-luna", "input": reply, "questions": questions}).encode("utf-8"),
        headers={"Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=25) as response:
        answers = json.load(response)["answers"]
    return lines, {a["name"]: a.get("probability", 0) for a in answers}


def hits(lines: list[str], p: dict[str, float]) -> dict[str, list[str]]:
    found = {}
    for kind, (excuse, _) in RULES.items():
        if excuse and p[excuse] >= 0.5:
            continue
        found[kind] = [line for i, line in enumerate(lines) if p[f"{kind}:{i}"] >= 0.6]
    return {kind: found_lines for kind, found_lines in found.items() if found_lines}


def violations(reply: str) -> list[str]:
    return [
        RULES[kind][1].format(lines="\n".join(f"- {line}" for line in found_lines))
        for kind, found_lines in hits(*probabilities(reply)).items()
    ]


if __name__ == "__main__":
    data = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    reply = data.get("last_assistant_message") or ""
    if data.get("stop_hook_active") or not reply.strip():
        sys.exit(0)
    parts = violations(reply)
    if not parts:
        sys.exit(0)
    print(json.dumps({"decision": "block", "reason": "\n\n".join(parts + [ENDING])}))

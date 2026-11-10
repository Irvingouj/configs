import hashlib, json, os, subprocess, sys, tempfile, time

data = json.load(sys.stdin)
cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or os.getcwd()

def run(*args):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, encoding="utf-8", timeout=5).stdout.strip()
    except Exception:
        return ""

branch = run("git", "branch", "--show-current")
out = os.path.basename(cwd.rstrip("\\/")) or cwd
if branch:
    out += f" | {branch}"
    # gh is slow, so the PR lookup is cached per directory and branch.
    cache = os.path.join(tempfile.gettempdir(), "claude-statusline-" + hashlib.md5(f"{cwd}|{branch}".encode()).hexdigest())
    if os.path.exists(cache) and time.time() - os.path.getmtime(cache) < 60:
        pr = open(cache, encoding="utf-8").read()
    else:
        pr = run("gh", "pr", "view", "--json", "number,title", "--jq", '"#\\(.number) \\(.title)"')[:60]
        open(cache, "w", encoding="utf-8").write(pr)
    if pr:
        out += f" | {pr}"
model = (data.get("model") or {}).get("display_name")
if model:
    out += f" | {model}"
sys.stdout.reconfigure(encoding="utf-8")
print(out)

import argparse
import contextlib
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time


ACTIONS = ("review", "second-opinion", "fix-ci", "address-comments", "rebase", "rebase-stack", "checkout")
REVIEW_ACTIONS = {"review", "second-opinion"}
DEFAULT_AGENTS = {
    "review": "pi",
    "second-opinion": ["claude", "codex"],
    "fix-ci": "claude",
    "address-comments": "claude",
    "rebase": "claude",
    "rebase-stack": "claude",
    # Only a checkout to work in, no agent.
    "checkout": [],
}
SESSION = "agents"
SHELLS = {"zsh", "bash", "sh", "fish"}
REVIEW_MAX_AGE_DAYS = 14
# Only turns at least this long notify when they finish.
DONE_NOTIFY_SECONDS = 30
CODE_DIR = Path(os.environ.get("AGENT_RUN_CODE_DIR", "~/code")).expanduser()
ABOARD_REPO = Path(os.environ.get("ABOARD_REPO", "~/code/aboard")).expanduser().resolve()
DATA_DIR = Path(os.environ.get("XDG_DATA_HOME", "~/.local/share")).expanduser() / "agent-run"
WORKTREE_ROOT = DATA_DIR / "worktrees"
TRIAGE_DIR = Path(os.environ.get("XDG_CACHE_HOME", "~/.cache")).expanduser() / "agent-run" / "triage"
TRIAGE_MODEL = "haiku"
# Diffs are cut here (~40k tokens) so one huge PR can't run up the bill.
TRIAGE_MAX_DIFF = 150_000
TRIAGE_RETRY_SECONDS = 3600
LOCK_FILES = {"Gemfile.lock", "yarn.lock", "package-lock.json", "pnpm-lock.yaml", "flake.lock", "Cargo.lock",
              "poetry.lock", "composer.lock", "mix.lock", "bun.lockb"}


class AgentRunError(Exception):
    pass


def run(*args, cwd=None, capture=False, check=True):
    return subprocess.run(
        [str(arg) for arg in args], cwd=cwd, check=check, text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def notify(message):
    if shutil.which("notify-send"):
        run("notify-send", "--app-name=agent-run", "agent-run", message, check=False)
    print(f"agent-run: {message}", file=sys.stderr)


def config_agents():
    path = Path(os.environ.get("XDG_CONFIG_HOME", "~/.config")).expanduser() / "agent-run/config.json"
    agents = dict(DEFAULT_AGENTS)
    if path.is_file():
        agents.update(json.loads(path.read_text()).get("agents", {}))
    return agents


def parse_url(url):
    match = re.fullmatch(r"https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)/?", url)
    if not match:
        raise AgentRunError(f"Not a GitHub pull request URL: {url}")
    return match[1], match[2], int(match[3])


def stack_lines(pr):
    return "\n".join(f"- #{member['number']} {member['headRefName']}"
                     + (f" ({member['worktree']})" if member.get("worktree") else "")
                     for member in pr.get("stack", []))


def prompt(action, pr):
    url, base, number = pr["url"], pr["baseRefName"], pr["number"]
    context = f"Pull request #{number} \"{pr['title']}\" ({url}), base branch {base}."
    no_push = "Commit your changes, but ask me before pushing."
    return {
        "review": f"""{context}
You are reviewing someone else's change. Read the description with `gh pr view {url}` and the diff with
`git diff origin/{base}...HEAD`. Report correctness bugs, risky changes, and missing tests, most severe
first, with file:line references. Do not edit files and do not post anything to GitHub.""",
        "second-opinion": f"""{context}
Give an independent review. Read the description with `gh pr view {url}` and the diff with
`git diff origin/{base}...HEAD`. Report correctness bugs, risky changes, and missing tests, most severe
first, with file:line references. Do not edit files and do not post anything to GitHub.""",
        "fix-ci": f"""{context}
CI is failing. Find the failing checks with `gh pr checks {url}` and their logs with
`gh run view <run-id> --log-failed`. Fix the root cause, run the affected tests locally, and say what you
could not verify. {no_push}""",
        "address-comments": f"""{context}
Reviewers requested changes. Read the reviews with `gh pr view {url} --comments` and the inline review
comments with `gh api repos/{{owner}}/{{repo}}/pulls/{number}/comments`. Address each unresolved comment, or
explain why you disagree, then summarise what you did per comment. Do not reply on GitHub. {no_push}""",
        "rebase": f"""{context}
The branch conflicts with {base}. Run `git fetch origin` and rebase onto origin/{base}, resolving conflicts
by keeping the intent of both sides. Run the tests touching the conflicted files. Ask me before
force-pushing.""",
        "rebase-stack": f"""{context}
It is the base of this stack of pull requests, bottom first (branch, then the worktree it is checked out in):
{stack_lines(pr)}
You are in a checkout of the top branch. Run `git fetch origin`, then rebase the whole stack onto
origin/{base} at once with `git rebase --update-refs origin/{base}`, resolving conflicts by keeping the intent of
both sides. Git skips branches that are checked out in other worktrees; afterwards point each of those at its
rebased commit, with `git -C <worktree> reset --hard <commit>` if that worktree has no local changes, and
otherwise stop and ask me. Run the tests touching the conflicted files. Then show me each branch with its new
commit, and ask me before force-pushing them all with `git push --force-with-lease origin <branches>`.""",
    }[action]


def worktrees(repo):
    records = run("git", "-C", repo, "worktree", "list", "--porcelain", "-z", capture=True).stdout.split("\0\0")
    result = {}
    for record in records:
        fields = dict(line.partition(" ")[::2] for line in record.split("\0") if line)
        if "worktree" in fields:
            result[Path(fields["worktree"]).resolve()] = fields
    return result


def parent_pid(pid):
    return int(Path(f"/proc/{pid}/stat").read_text().rpartition(")")[2].split()[1])


def window_of(pid):
    """The Hyprland window address owning pid or one of its ancestors."""
    clients = run("hyprctl", "clients", "-j", capture=True, check=False) if shutil.which("hyprctl") else None
    if not clients or clients.returncode or not clients.stdout.strip():
        return None
    # One process can own several windows (e.g. Ghostty); take the most recently focused.
    windows = {client["pid"]: client["address"] for client in
               sorted(json.loads(clients.stdout), key=lambda client: client.get("focusHistoryID", 0), reverse=True)}
    with contextlib.suppress(OSError, ValueError):
        while pid > 1 and pid not in windows:
            pid = parent_pid(pid)
    return windows.get(pid)


def focus_window(address):
    # Lua configs (Hyprland 0.56+) take a dispatcher expression; legacy configs the old syntax.
    lua = f'hl.dsp.focus({{ window = "address:{address}" }})'
    if run("hyprctl", "dispatch", lua, capture=True, check=False).returncode != 0:
        run("hyprctl", "dispatch", "focuswindow", f"address:{address}", capture=True, check=False)


def focus_window_of(pid):
    """Focus the Hyprland window owning pid or one of its ancestors."""
    address = window_of(pid)
    if address:
        focus_window(address)
    return address is not None


def focus_session(session):
    """Show the tmux session in an open terminal by switching a tmux client to it: the one in the
    focused window, else the most recently used. A new terminal is only opened when no tmux client
    has a window."""
    active = None
    if shutil.which("hyprctl"):
        with contextlib.suppress(ValueError, AttributeError):
            active = json.loads(run("hyprctl", "activewindow", "-j", capture=True, check=False).stdout).get("address")
    clients = []
    for line in run("tmux", "list-clients", "-F", "#{client_activity} #{client_pid} #{client_tty} #{session_name}",
                    capture=True, check=False).stdout.splitlines():
        activity, pid, tty, name = line.split(" ", 3)
        address = window_of(int(pid))
        if address:
            clients.append((address == active, int(activity), address, tty, name))
    if clients:
        _, _, address, tty, name = max(clients)
        if name != session:
            run("tmux", "switch-client", "-c", tty, "-t", f"={session}")
        focus_window(address)
        return
    terminal = os.environ.get("AGENT_RUN_TERMINAL", "ghostty")
    subprocess.Popen([terminal, "-e", "tmux", "attach-session", "-t", f"={session}"],
                     start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def watch(produce, interval=1):
    """Print produce() as one JSON line whenever it changes; Quickshell reads these."""
    previous = None
    while True:
        current = json.dumps(produce())
        if current != previous:
            print(current, flush=True)
            previous = current
        time.sleep(interval)


def agent_command(agent, text):
    if agent not in ("claude", "codex", "pi"):
        raise AgentRunError(f"Unknown agent: {agent}")
    return [agent, text]


class AgentRun:
    def __init__(self, action, url, agents=None):
        self.action = action
        self.url = url
        self.owner, self.repo_name, self.number = parse_url(url)
        configured = config_agents()[action]
        self.agents = agents or (configured if isinstance(configured, list) else [configured])

    @property
    def window(self):
        return f"{self.repo_name}#{self.number} {self.action}"

    def repo(self):
        path = (CODE_DIR / self.repo_name).resolve()
        remote = run("git", "-C", path, "remote", "get-url", "origin", capture=True, check=False)
        if remote.returncode or f"{self.owner}/{self.repo_name}".lower() not in remote.stdout.lower():
            raise AgentRunError(f"No clone of {self.owner}/{self.repo_name} at {path}")
        return path

    def launch(self):
        """Open the work in a tmux window and bring a terminal to it."""
        executable = os.environ.get("AGENT_RUN_EXE", "agent-run")
        target = f"={SESSION}:={self.window}"
        if run("tmux", "has-session", "-t", f"={SESSION}", capture=True, check=False).returncode:
            run("tmux", "new-session", "-d", "-s", SESSION, "-n", "home")
        if run("tmux", "list-windows", "-t", f"={SESSION}", "-F", "#{window_name}",
               capture=True).stdout.splitlines().count(self.window) == 0:
            agents = [arg for agent in self.agents for arg in ("--agent", agent)]
            inner = "exec " + shlex.join([executable, "_run", self.action, self.url, *agents])
            # An interactive shell gives agents the same PATH as a terminal (e.g. ~/.npm-packages/bin).
            shell = os.environ.get("SHELL", "/bin/bash")
            run("tmux", "new-window", "-d", "-t", f"={SESSION}:", "-n", self.window,
                "-c", Path.home(), shlex.join([shell, "-ic", inner]))
        run("tmux", "select-window", "-t", target)
        focus_session(SESSION)
        # Tidy up in the background; the log shows what was removed or skipped.
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        with (DATA_DIR / "prune.log").open("w") as log:
            subprocess.Popen([executable, "prune"], start_new_session=True,
                             stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT)

    def pull_request(self):
        fields = "number,title,url,baseRefName,headRefName,isCrossRepository,state"
        return json.loads(run("gh", "pr", "view", self.url, "--json", fields, capture=True).stdout)

    def stack(self, pr):
        """This PR followed by the open PRs stacked on it, bottom first."""
        fields = "number,title,url,baseRefName,headRefName,isCrossRepository"
        repo = f"{self.owner}/{self.repo_name}"
        open_prs = [candidate for candidate in json.loads(
            run("gh", "pr", "list", "--repo", repo, "--state", "open", "--limit", "1000", "--json", fields,
                capture=True).stdout) if not candidate["isCrossRepository"]]
        stack = [pr]
        while len(stack) < 50:
            children = sorted((candidate for candidate in open_prs
                               if candidate["baseRefName"] == stack[-1]["headRefName"]),
                              key=lambda candidate: candidate["number"])
            if not children:
                break
            stack.append(children[0])
        return stack

    def prepare(self, pr):
        """Return the worktree to run agents in, reusing a checkout of the PR branch when one exists."""
        repo = self.repo()
        print(f"Fetching {self.repo_name}…", flush=True)
        run("git", "-C", repo, "fetch", "origin")
        branch = f"refs/heads/{pr['headRefName']}"
        if not pr["isCrossRepository"]:
            for path, fields in worktrees(repo).items():
                if fields.get("branch") == branch:
                    print(f"Reusing {path}", flush=True)
                    return path
        if pr["isCrossRepository"]:
            if self.action in REVIEW_ACTIONS:
                return self.review_worktree(repo)
            raise AgentRunError("This needs a branch in this repository; this PR comes from a fork.")
        # Every aboard PR gets one workspace under ~/code/aboard, with the secrets and databases tests need.
        if repo == ABOARD_REPO:
            return self.aboard_worktree(repo, pr["headRefName"], pr["number"])
        if self.action in REVIEW_ACTIONS:
            return self.review_worktree(repo)
        return self.branch_worktree(repo, pr["headRefName"], pr["number"])

    def review_worktree(self, repo):
        """A detached checkout of the PR head; cheap, and never touches local branches."""
        path = WORKTREE_ROOT / self.repo_name / f"review-{self.number}"
        run("git", "-C", repo, "fetch", "origin", f"pull/{self.number}/head")
        # FETCH_HEAD is per-worktree, so resolve it here before using it in the review worktree.
        head = run("git", "-C", repo, "rev-parse", "FETCH_HEAD^{commit}", capture=True).stdout.strip()
        if path.resolve() in worktrees(repo):
            if run("git", "-C", path, "status", "--porcelain", capture=True).stdout.strip():
                print(f"{path} has local changes; leaving it at its current commit.", flush=True)
            else:
                run("git", "-C", path, "checkout", "--quiet", "--detach", head)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            run("git", "-C", repo, "worktree", "add", "--detach", path, head)
        return path

    def branch_worktree(self, repo, branch, number):
        path = WORKTREE_ROOT / self.repo_name / f"pr-{number}"
        if path.resolve() in worktrees(repo):
            return path
        path.parent.mkdir(parents=True, exist_ok=True)
        if run("git", "-C", repo, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}", check=False).returncode == 0:
            run("git", "-C", repo, "worktree", "add", path, branch)
        else:
            run("git", "-C", repo, "worktree", "add", "--track", "-b", branch, path, f"origin/{branch}")
        return path

    def aboard_worktree(self, repo, branch, number):
        """A full aboard-wt workspace, so agents can run DB-backed tests."""
        name = f"pr-{number}"
        path = repo / "worktrees" / name
        if path.resolve() not in worktrees(repo):
            local = run("git", "-C", repo, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}",
                        check=False).returncode == 0
            print("Creating aboard-wt workspace; this seeds databases and takes a few minutes.", flush=True)
            run("aboard-wt", "create", name, "--branch", branch if local else f"origin/{branch}", "--no-open")
        elif not run("git", "-C", path, "status", "--porcelain", capture=True).stdout.strip():
            # Bring a clean workspace up to date, e.g. for a second review after new pushes.
            run("git", "-C", path, "merge", "--ff-only", "--quiet", "@{upstream}", check=False)
        return path

    @staticmethod
    def is_aboard_workspace(path):
        config = path / "devenv.local.nix"
        return config.is_file() and config.read_text().startswith("# Generated by aboard-wt.")

    def command(self, path, agent, text):
        command = agent_command(agent, text)
        if self.is_aboard_workspace(path):
            # Run inside the workspace's own devenv, not the environment of whatever launched us.
            return ["aboard-wt", "_pane", path.name, "exec", "--", *command]
        return command

    def open_checkout(self, path):
        print(f"Checked out in {path}", flush=True)
        if self.is_aboard_workspace(path) and os.environ.get("TMUX_PANE"):
            # The workspace has its own tmux session (editor, shell, server); this window is done.
            run("aboard-wt", "open", path.name)
            run("tmux", "kill-window", "-t", os.environ["TMUX_PANE"])

    def start_agents(self, path, pr):
        text = prompt(self.action, pr)
        # Session hooks read these to label the agent in the Agents widget.
        labels = {"AGENT_RUN_TITLE": self.window, "AGENT_RUN_URL": self.url}
        os.environ.update(labels)
        first, *rest = self.agents
        for agent in rest:
            env = [arg for key, value in labels.items() for arg in ("-e", f"{key}={value}")]
            run("tmux", "split-window", "-h", *env, "-c", path, shlex.join(self.command(path, agent, text)))
        if rest:
            run("tmux", "select-pane", "-L")
        subprocess.run(self.command(path, first, text), cwd=path)

    def execute(self):
        """Runs inside the tmux window: prepare, start agents or open the checkout, then leave a shell there."""
        path = None
        try:
            pr = self.pull_request()
            if pr["state"] != "OPEN":
                raise AgentRunError(f"Pull request is {pr['state'].lower()}.")
            if self.action == "rebase-stack":
                pr["stack"] = self.stack(pr)
                if len(pr["stack"]) < 2:
                    raise AgentRunError("No pull requests are stacked on this one.")
                # Agents work from the top of the stack, so one rebase moves every branch.
                path = self.prepare(pr["stack"][-1])
                checkouts = {fields.get("branch"): worktree for worktree, fields in worktrees(self.repo()).items()}
                for member in pr["stack"]:
                    worktree = checkouts.get(f"refs/heads/{member['headRefName']}")
                    if worktree and worktree != path.resolve():
                        member["worktree"] = str(worktree)
            else:
                path = self.prepare(pr)
            if self.action == "checkout":
                self.open_checkout(path)
            else:
                self.start_agents(path, pr)
        except (AgentRunError, OSError, subprocess.CalledProcessError) as error:
            if isinstance(error, subprocess.CalledProcessError) and error.stderr:
                print(error.stderr.strip(), file=sys.stderr)
            print(f"agent-run: {error}", file=sys.stderr)
        except KeyboardInterrupt:
            pass
        if path and path.is_dir():
            os.chdir(path)
        shell = os.environ.get("SHELL", "/bin/bash")
        os.execvp(shell, [shell, "-i"])


class Sessions:
    """Live agent sessions, one JSON file each, written by the agents' own hooks."""

    # Hook event -> status. None ends the session.
    STATUS = {
        "SessionStart": "idle", "session_start": "idle",
        "UserPromptSubmit": "working", "PostToolUse": "working",
        "agent_start": "working", "ui_prompt_end": "working",
        "PermissionRequest": "waiting", "PreToolUse": "waiting", "ui_prompt_start": "waiting",
        "Stop": "done", "agent_settled": "done",
        "SessionEnd": None, "session_shutdown": None,
    }
    ORDER = {"waiting": 0, "done": 1, "working": 2, "idle": 3}
    # What a waiting agent is blocked on; only permission prompts can be answered with a key.
    WAITING_FOR = {"PermissionRequest": "permission", "PreToolUse": "question", "ui_prompt_start": "prompt"}

    def __init__(self):
        runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        self.dir = Path(runtime) / "agent-sessions"

    @staticmethod
    def agent_pid():
        """The agent is the nearest ancestor that is not the shell running this hook."""
        pid = os.getppid()
        with contextlib.suppress(OSError, ValueError):
            while pid > 1 and Path(f"/proc/{pid}/comm").read_text().strip() in SHELLS:
                pid = parent_pid(pid)
        return pid

    @staticmethod
    def title(cwd):
        if os.environ.get("AGENT_RUN_TITLE"):
            return os.environ["AGENT_RUN_TITLE"]
        top = run("git", "-C", cwd, "rev-parse", "--show-toplevel", capture=True, check=False).stdout.strip()
        branch = run("git", "-C", cwd, "branch", "--show-current", capture=True, check=False).stdout.strip()
        name = Path(top or cwd).name
        return f"{name} ({branch})" if branch else name

    @staticmethod
    def message(event, payload):
        tool_input = payload.get("tool_input") or {}
        if event == "PreToolUse" and payload.get("tool_name") == "AskUserQuestion":
            questions = tool_input.get("questions") or [{}]
            text = questions[0].get("question") or "Has a question for you"
        elif event == "PermissionRequest":
            detail = tool_input.get("description") or tool_input.get("command") or tool_input.get("file_path") or ""
            text = f"Approve {payload.get('tool_name', 'tool')}: {detail}".rstrip(": ")
        else:
            text = payload.get("last_assistant_message") or payload.get("message") or ""
        lines = [line.strip() for line in str(text).splitlines() if line.strip()]
        return lines[0][:200] if lines else ""

    @staticmethod
    def ask(payload):
        """The last question in the agent's final message, usually what it wants from you."""
        text = str(payload.get("last_assistant_message") or payload.get("message") or "")
        questions = [line.strip() for line in text.splitlines() if line.strip().endswith("?")]
        return questions[-1][-200:] if questions else ""

    def hook(self, agent, event):
        payload = {} if sys.stdin.isatty() else json.loads(sys.stdin.read() or "{}")
        if event not in self.STATUS:
            return
        pid = int(payload.get("pid") or self.agent_pid())
        session = str(payload.get("session_id") or pid)
        path = self.dir / f"{agent}-{re.sub(r'[^A-Za-z0-9_-]', '_', session)}.json"
        status = self.STATUS[event]
        if event == "PreToolUse" and payload.get("tool_name") != "AskUserQuestion":
            status = "working"
        if status is None:
            path.unlink(missing_ok=True)
            self.spawn_notification(path.stem, "close")
            return
        try:
            record = json.loads(path.read_text())
        except (OSError, ValueError):
            record = None
        if record and event == "SessionStart" and payload.get("source") == "compact":
            return
        cwd = payload.get("cwd") or os.getcwd()
        record = record or {
            "id": path.stem, "agent": agent, "pid": pid, "cwd": cwd, "title": self.title(cwd),
            "url": os.environ.get("AGENT_RUN_URL", ""), "pane": os.environ.get("TMUX_PANE", ""),
        }
        previous, since, now = record.get("status"), record.get("since", 0), time.time()
        message = self.message(event, payload)
        record.update(status=status, updated=now, since=since if previous == status else now, message=message or (
            record.get("message", "") if status == "working" else ""),
            waiting_for=self.WAITING_FOR.get(event, "") if status == "waiting" else "",
            ask=self.ask(payload) if status == "done" else "")
        self.dir.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(".tmp")
        temporary.write_text(json.dumps(record))
        temporary.replace(path)
        if status == "waiting" and previous != "waiting":
            self.spawn_notification(path.stem, "waiting")
        elif status == "done" and previous == "working" and now - since >= DONE_NOTIFY_SECONDS:
            self.spawn_notification(path.stem, "done")
        elif previous in ("waiting", "done") and status != previous:
            # You answered or prompted again; the notification is stale.
            self.spawn_notification(path.stem, "close")

    def spawn_notification(self, session_id, kind):
        # Detached: notify-send waits for the click, and the agent must not wait on the hook.
        subprocess.Popen([os.environ.get("AGENT_RUN_EXE", "agent-run"), "_notify", session_id, kind],
                         start_new_session=True, stdin=subprocess.DEVNULL,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def visible(self, record):
        """Whether the agent is on screen: its pane is shown in the focused window."""
        if not shutil.which("hyprctl"):
            return False
        active = json.loads(run("hyprctl", "activewindow", "-j", capture=True, check=False).stdout or "{}")
        address = active.get("address") if isinstance(active, dict) else None
        if not address:
            return False
        pane = record.get("pane")
        if not pane:
            return window_of(record["pid"]) == address
        shown = run("tmux", "display-message", "-p", "-t", pane, "#{pane_active}#{window_active} #{session_name}",
                    capture=True, check=False)
        flags, _, session = shown.stdout.strip().partition(" ")
        if shown.returncode or flags != "11":
            return False
        clients = run("tmux", "list-clients", "-t", f"={session}", "-F", "#{client_pid}",
                      capture=True, check=False).stdout.split()
        return any(window_of(int(client)) == address for client in clients)

    def notification(self, session_id, kind):
        """Show, replace or close the session's notification; Show focuses the agent."""
        state_path = self.dir / f"{session_id}.notification"
        try:
            state = json.loads(state_path.read_text())
        except (OSError, ValueError):
            state = {}
        # Only one notification per session: stop the previous one's click waiter.
        waiter = state.get("pid")
        with contextlib.suppress(OSError):
            if waiter and "_notify" in Path(f"/proc/{waiter}/cmdline").read_text():
                os.killpg(waiter, signal.SIGTERM)
        if kind == "close":
            if state.get("id"):
                run("gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                    "--object-path", "/org/freedesktop/Notifications",
                    "--method", "org.freedesktop.Notifications.CloseNotification", str(state["id"]),
                    capture=True, check=False)
            state_path.unlink(missing_ok=True)
            return
        record = next((r for r in self.list() if r["id"] == session_id), None)
        if record is None or self.visible(record):
            return
        agent = record["agent"].capitalize()
        summary = f"{agent} needs you" if kind == "waiting" else f"{agent} is done"
        body = "\n".join(filter(None, [record["title"], record.get("message", "")]))
        process = subprocess.Popen(
            ["notify-send", "--app-name=Agents", "--print-id", "--wait", "--action=focus=Show",
             f"--urgency={'critical' if kind == 'waiting' else 'normal'}",
             *([f"--replace-id={state['id']}"] if state.get("id") else []), summary, body],
            stdout=subprocess.PIPE, text=True)
        notification_id = process.stdout.readline().strip()
        if notification_id.isdigit():
            state_path.write_text(json.dumps({"id": int(notification_id), "pid": os.getpid()}))
        try:
            action = process.communicate(timeout=3600)[0].strip()
        except subprocess.TimeoutExpired:
            process.kill()
            return
        if action == "focus":
            self.focus(session_id)

    def list(self):
        records = []
        for path in self.dir.glob("*.json") if self.dir.is_dir() else []:
            try:
                record = json.loads(path.read_text())
            except (OSError, ValueError):
                continue
            if not Path(f"/proc/{record.get('pid')}").exists():
                path.unlink(missing_ok=True)
                continue
            records.append(record)
        return sorted(records, key=lambda r: (self.ORDER.get(r["status"], 9), -r["updated"]))

    def focus(self, session_id):
        record = next((r for r in self.list() if r["id"] == session_id), None)
        if record is None:
            raise AgentRunError("That agent session has ended.")
        pane = record.get("pane")
        if pane and run("tmux", "display-message", "-p", "-t", pane, "", capture=True, check=False).returncode == 0:
            session = run("tmux", "display-message", "-p", "-t", pane, "#{session_name}", capture=True).stdout.strip()
            run("tmux", "select-window", "-t", pane)
            run("tmux", "select-pane", "-t", pane)
            focus_session(session)
        elif not focus_window_of(record["pid"]):
            raise AgentRunError("Could not find a window for that agent session.")

    def pane(self, session_id):
        """The tmux pane the agent runs in, checked so keys never go to a pane that was reused."""
        record = next((r for r in self.list() if r["id"] == session_id), None)
        if record is None:
            raise AgentRunError("That agent session has ended.")
        pane = record.get("pane")
        result = run("tmux", "display-message", "-p", "-t", pane, "#{pane_pid}", capture=True, check=False) \
            if pane else None
        if not result or result.returncode:
            raise AgentRunError("That agent is not running in a tmux pane.")
        pid, shell = record["pid"], int(result.stdout.strip())
        with contextlib.suppress(OSError, ValueError):
            while pid > 1 and pid != shell:
                pid = parent_pid(pid)
        if pid != shell:
            raise AgentRunError("That agent is no longer in its tmux pane.")
        return record, pane

    def reply(self, session_id, text):
        record, pane = self.pane(session_id)
        if record["status"] == "waiting":
            raise AgentRunError("That agent is waiting on a prompt; open it to answer.")
        # One line: a newline would submit early.
        text = " ".join(text.split())
        if text:
            run("tmux", "send-keys", "-t", pane, "-l", text)
            run("tmux", "send-keys", "-t", pane, "Enter")

    def approve(self, session_id, allow):
        record, pane = self.pane(session_id)
        if record["status"] != "waiting" or record.get("waiting_for") != "permission":
            raise AgentRunError("That agent is not waiting for a permission.")
        # The prompt highlights "Yes" first; Escape declines.
        run("tmux", "send-keys", "-t", pane, "Enter" if allow else "Escape")

    def kill(self, session_id):
        """Stop the agent and close the tmux pane it runs in."""
        record = next((r for r in self.list() if r["id"] == session_id), None)
        if record is None:
            raise AgentRunError("That agent session has ended.")
        try:
            pane = self.pane(session_id)[1]
        except AgentRunError:
            pane = None
        # Make sure the pid still belongs to the agent and was not reused.
        argv = Path(f"/proc/{record['pid']}/cmdline").read_text(errors="replace").split("\0")[:2]
        if record["agent"] not in (Path(arg).name for arg in argv):
            raise AgentRunError(f"Process {record['pid']} is no longer {record['agent']}.")
        os.kill(record["pid"], signal.SIGTERM)
        if pane:
            # The pane may already be gone if the agent was all that ran in it.
            run("tmux", "kill-pane", "-t", pane, capture=True, check=False)
        (self.dir / f"{session_id}.json").unlink(missing_ok=True)
        self.spawn_notification(session_id, "close")

    def running_in(self, path):
        return any(Path(r["cwd"]).resolve() == path or path in Path(r["cwd"]).resolve().parents
                   for r in self.list())


class Triage:
    """Cheap first read of review requests: what a PR does, how risky it is, how long a review takes.
    Results are cached per PR head commit, so each push is triaged once."""

    SYSTEM_PROMPT = (
        "You triage GitHub pull requests so a reviewer can decide what to review first. "
        "Risk is how likely a mistake that slips through review hurts production. "
        "high: likely data loss or corruption, a security hole, or an outage, e.g. destructive migrations, "
        "auth or permission changes, money or ledger math. "
        "medium: the default for feature work and refactors, including additive migrations and new endpoints. "
        "low: dependency patch bumps, copy, styling, tests, docs, config behind a flag. "
        "Expect most PRs to be medium. Be concrete and terse. Never ask questions."
    )
    SCHEMA = {
        "type": "object",
        "properties": {
            "summary": {"type": "string", "description": "One sentence, at most 120 characters: what the PR does."},
            "risk": {"type": "string", "enum": ["low", "medium", "high"]},
            "minutes": {"type": "integer", "description": "Estimated minutes for a careful human review."},
            "flags": {"type": "array", "items": {"type": "string"}, "maxItems": 3,
                      "description": "Up to three labels of one or two lowercase words for what needs "
                                     "attention, e.g. 'migration', 'auth', 'public api'."},
        },
        "required": ["summary", "risk", "minutes", "flags"],
    }

    def path(self, url):
        owner, repo, number = parse_url(url)
        return TRIAGE_DIR / f"{owner}_{repo}_{number}.json"

    def read(self, url):
        try:
            return json.loads(self.path(url).read_text())
        except (OSError, ValueError):
            return None

    def write(self, url, record):
        TRIAGE_DIR.mkdir(parents=True, exist_ok=True)
        path = self.path(url)
        temporary = path.with_suffix(".tmp")
        temporary.write_text(json.dumps({"url": url, "updated": time.time(), **record}))
        temporary.replace(path)

    def list(self):
        records = {}
        for path in TRIAGE_DIR.glob("*.json") if TRIAGE_DIR.is_dir() else []:
            with contextlib.suppress(OSError, ValueError):
                record = json.loads(path.read_text())
                records[record["url"]] = record
        return records

    @staticmethod
    def diff(url):
        text = run("gh", "pr", "diff", url, capture=True).stdout
        # Drop lock files: large, and they say nothing about risk.
        sections = re.split(r"(?m)^(?=diff --git )", text)
        kept = [section for section in sections
                if not (m := re.match(r"diff --git a/(\S+)", section)) or Path(m[1]).name not in LOCK_FILES]
        text = "".join(kept)
        if len(text) > TRIAGE_MAX_DIFF:
            text = text[:TRIAGE_MAX_DIFF] + "\n[diff truncated]\n"
        return text

    def triage(self, url, pr):
        files = "\n".join(f"{f['path']} (+{f['additions']} -{f['deletions']})" for f in pr["files"])
        text = (
            f"Pull request: {pr['title']}\nAuthor: {pr['author']['login']}\n"
            f"Size: +{pr['additions']} -{pr['deletions']} in {pr['changedFiles']} files\n\n"
            f"Description:\n{(pr['body'] or '(none)')[:4000]}\n\nFiles:\n{files}\n\nDiff:\n{self.diff(url)}"
        )
        # Lean on purpose: no tools, MCP servers, settings or hooks. That cuts the cost ~500x
        # and keeps triage out of the Agents widget.
        result = subprocess.run(
            ["claude", "-p", "--model", TRIAGE_MODEL, "--tools", "", "--strict-mcp-config",
             "--setting-sources", "", "--no-session-persistence", "--system-prompt", self.SYSTEM_PROMPT,
             "--output-format", "json", "--json-schema", json.dumps(self.SCHEMA)],
            input=text, capture_output=True, text=True, timeout=300, cwd=TRIAGE_DIR, check=True)
        output = json.loads(result.stdout)
        if output.get("is_error") or not output.get("structured_output"):
            raise AgentRunError(output.get("result") or "No triage returned")
        return {**output["structured_output"], "cost": output.get("total_cost_usd")}

    def run(self, urls):
        TRIAGE_DIR.mkdir(parents=True, exist_ok=True)
        # One triage at a time; later calls queue here and then find most PRs cached.
        with (TRIAGE_DIR / ".lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            for url in urls:
                try:
                    pr = json.loads(run("gh", "pr", "view", url, "--json",
                                        "headRefOid,title,body,author,files,additions,deletions,changedFiles",
                                        capture=True).stdout)
                    cached = self.read(url) or {}
                    if cached.get("sha") == pr["headRefOid"] and (cached.get("status") == "done" or (
                            cached.get("status") == "error" and time.time() - cached["updated"] < TRIAGE_RETRY_SECONDS)):
                        continue
                    self.write(url, {**cached, "sha": pr["headRefOid"], "status": "running"})
                    self.write(url, {"sha": pr["headRefOid"], "status": "done", **self.triage(url, pr)})
                except (AgentRunError, OSError, ValueError, KeyError,
                        subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
                    detail = getattr(error, "stderr", None) or str(error)
                    self.write(url, {**(self.read(url) or {}), "status": "error", "error": str(detail).strip()[:300]})
            # Forget PRs not seen for a month.
            for path in TRIAGE_DIR.glob("*.json"):
                if time.time() - path.stat().st_mtime > 30 * 86400:
                    path.unlink(missing_ok=True)


class Prune:
    """Remove agent-run worktrees whose PR is closed, and review checkouts nobody has used in a while.

    Only checkouts agent-run created are removed, and only when they hold no uncommitted or unpushed
    work and no process outside an idle tmux shell is using them.
    """

    def __init__(self, dry_run=False):
        self.dry_run = dry_run
        self.states = {}

    @staticmethod
    def slug(repo):
        remote = run("git", "-C", repo, "remote", "get-url", "origin", capture=True, check=False).stdout.strip()
        match = re.search(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?/?$", remote)
        return f"{match[1]}/{match[2]}" if match else None

    def state(self, slug, number):
        key = (slug, number)
        if key not in self.states:
            result = run("gh", "pr", "view", number, "--repo", slug, "--json", "state", capture=True, check=False)
            self.states[key] = json.loads(result.stdout)["state"] if result.returncode == 0 else None
        return self.states[key]

    @staticmethod
    def last_used(path):
        index = Path(run("git", "-C", path, "rev-parse", "--path-format=absolute", "--git-path", "index",
                         capture=True).stdout.strip())
        return max(index.stat().st_mtime if index.exists() else 0, path.stat().st_mtime)

    @staticmethod
    def windows(repo_name, number):
        output = run("tmux", "list-panes", "-s", "-t", f"={SESSION}", "-F",
                     "#{window_id}\t#{window_name}\t#{pane_current_command}", capture=True, check=False).stdout
        result = {}
        for line in output.splitlines():
            window, name, command = line.split("\t")
            if name.startswith(f"{repo_name}#{number} "):
                result.setdefault(window, []).append(command)
        return result

    @staticmethod
    def users(path):
        """PIDs whose working directory is inside path."""
        pids = []
        for proc in Path("/proc").iterdir():
            try:
                cwd = (proc / "cwd").resolve()
            except OSError:
                continue
            if proc.name.isdigit() and (cwd == path or path in cwd.parents):
                pids.append(int(proc.name))
        return pids

    def blocker(self, path, kind):
        if run("git", "-C", path, "status", "--porcelain", capture=True).stdout.strip():
            return "has uncommitted changes"
        if kind == "pr" and run("git", "-C", path, "log", "--oneline", "HEAD", "--not", "--remotes",
                                capture=True).stdout.strip():
            return "has unpushed commits"
        return None

    def reason(self, slug, kind, number, path):
        state = self.state(slug, number)
        if state in ("MERGED", "CLOSED"):
            return f"PR {state.lower()}"
        if state is None:
            return None
        if kind == "review":
            days = (time.time() - self.last_used(path)) / 86400
            if days > REVIEW_MAX_AGE_DAYS:
                return f"review unused for {int(days)} days"
        return None

    def remove(self, repo, path, repo_name, number, why):
        windows = self.windows(repo_name, number)
        busy = [w for w, commands in windows.items() if any(c not in SHELLS for c in commands)]
        if busy or Sessions().running_in(path.resolve()):
            print(f"skip {path}: an agent is still running in tmux")
            return
        if self.dry_run:
            print(f"would remove {path} ({why})")
            return
        for window in windows:
            run("tmux", "kill-window", "-t", window, check=False)
        time.sleep(0.2)
        if self.users(path.resolve()):
            print(f"skip {path}: still in use by another process")
            return
        run("git", "-C", repo, "worktree", "remove", path)
        with contextlib.suppress(OSError):
            path.parent.rmdir()
        print(f"removed {path} ({why})")

    def prune(self):
        for repo_dir in sorted(p for p in WORKTREE_ROOT.glob("*") if p.is_dir()):
            repo = CODE_DIR / repo_dir.name
            slug = self.slug(repo) if repo.is_dir() else None
            if slug is None:
                print(f"skip {repo_dir}: no clone at {repo}")
                continue
            run("git", "-C", repo, "worktree", "prune")
            registered = worktrees(repo)
            for path in sorted(repo_dir.iterdir()):
                match = re.fullmatch(r"(review|pr)-([0-9]+)", path.name)
                if not match or path.resolve() not in registered:
                    print(f"skip {path}: not an agent-run worktree")
                    continue
                kind, number = match[1], match[2]
                why = self.reason(slug, kind, number, path)
                if why is None:
                    continue
                blocker = self.blocker(path, kind)
                if blocker:
                    print(f"skip {path} ({why}): {blocker}")
                    continue
                self.remove(repo, path, repo_dir.name, number, why)
        self.aboard_workspaces()

    def aboard_workspaces(self):
        """aboard-wt workspaces own databases, so only suggest removing them."""
        if not ABOARD_REPO.is_dir():
            return
        slug = self.slug(ABOARD_REPO)
        for path in worktrees(ABOARD_REPO):
            match = re.fullmatch(r"pr-([0-9]+)", path.name)
            if match and path.parent == ABOARD_REPO / "worktrees" and self.state(slug, match[1]) in ("MERGED", "CLOSED"):
                print(f"PR closed; remove its workspace with: aboard-wt remove {path.name}")

    def run(self):
        WORKTREE_ROOT.mkdir(parents=True, exist_ok=True)
        with (DATA_DIR / "prune.lock").open("w") as handle:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                print("Another prune is running.")
                return
            self.prune()


def main():
    parser = argparse.ArgumentParser(prog="agent-run", description="Start a coding agent on a GitHub pull request.")
    parser.add_argument("action", choices=ACTIONS + ("prune", "sessions", "focus", "reply", "approve", "deny", "kill",
                                                     "triage", "hook", "_run", "_notify"),
                        help="An action on a PR; 'prune' removes worktrees that are no longer needed; "
                             "'sessions' lists live agent sessions, 'focus ID' jumps to one, 'reply ID TEXT' "
                             "sends it a prompt, 'approve ID' and 'deny ID' answer its permission prompt, 'kill ID' stops it, "
                             "'triage URL...' pre-reads review requests in the background, "
                             "and 'hook AGENT EVENT' records an agent hook event")
    parser.add_argument("args", nargs="*", metavar="url")
    parser.add_argument("--agent", action="append", choices=("claude", "codex", "pi"),
                        help="Agent to use (repeat for side-by-side panes); defaults per action")
    parser.add_argument("--dry-run", action="store_true", help="prune: only show what would be removed")
    parser.add_argument("--watch", action="store_true", help="sessions, triage: print the list again whenever it changes")
    args = parser.parse_args()
    expected = {"prune": 0, "sessions": 0, "focus": 1, "reply": 2, "triage": None, "hook": 2, "_run": 2, "_notify": 2}.get(args.action, 1)
    if expected is not None and len(args.args) != expected:
        parser.error(f"{args.action} takes {expected} argument(s)")
    if args.action == "hook":
        # Never disturb the agent: a failed status update only costs the widget a row.
        with contextlib.suppress(Exception):
            Sessions().hook(*args.args)
        return 0
    try:
        if args.action == "prune":
            Prune(args.dry_run).run()
        elif args.action == "sessions":
            watch(Sessions().list) if args.watch else print(json.dumps(Sessions().list(), indent=2))
        elif args.action == "triage":
            if args.args:
                Triage().run(args.args)
            else:
                watch(Triage().list, interval=2) if args.watch else print(json.dumps(Triage().list(), indent=2))
        elif args.action == "focus":
            Sessions().focus(args.args[0])
        elif args.action == "reply":
            Sessions().reply(*args.args)
        elif args.action == "kill":
            Sessions().kill(args.args[0])
        elif args.action in ("approve", "deny"):
            Sessions().approve(args.args[0], args.action == "approve")
        elif args.action == "_notify":
            Sessions().notification(*args.args)
        elif args.action == "_run":
            action, url = args.args
            AgentRun(action, url, args.agent).execute()
        else:
            (url,) = args.args
            AgentRun(args.action, url, args.agent).launch()
    except (AgentRunError, OSError, ValueError, subprocess.CalledProcessError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.stderr:
            print(error.stderr.strip(), file=sys.stderr)
        notify(str(error))
        return 1
    return 0


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    sys.exit(main())

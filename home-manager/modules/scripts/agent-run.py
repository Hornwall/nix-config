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


ACTIONS = ("review", "second-opinion", "fix-ci", "address-comments", "rebase")
REVIEW_ACTIONS = {"review", "second-opinion"}
DEFAULT_AGENTS = {
    "review": "pi",
    "second-opinion": ["claude", "codex"],
    "fix-ci": "claude",
    "address-comments": "claude",
    "rebase": "claude",
}
SESSION = "agents"
SHELLS = {"zsh", "bash", "sh", "fish"}
REVIEW_MAX_AGE_DAYS = 14
CODE_DIR = Path(os.environ.get("AGENT_RUN_CODE_DIR", "~/code")).expanduser()
ABOARD_REPO = Path(os.environ.get("ABOARD_REPO", "~/code/aboard")).expanduser().resolve()
DATA_DIR = Path(os.environ.get("XDG_DATA_HOME", "~/.local/share")).expanduser() / "agent-run"
WORKTREE_ROOT = DATA_DIR / "worktrees"


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
    if not shutil.which("hyprctl"):
        return None
    windows = {client["pid"]: client["address"] for client in
               json.loads(run("hyprctl", "clients", "-j", capture=True).stdout)}
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
    """Show the tmux session in an open terminal, switching the most recently used tmux client
    to it; a new terminal is only opened when no tmux client has a window."""
    clients = []
    for line in run("tmux", "list-clients", "-F", "#{client_activity} #{client_pid} #{client_tty} #{session_name}",
                    capture=True, check=False).stdout.splitlines():
        activity, pid, tty, name = line.split(" ", 3)
        clients.append((name == session, int(activity), int(pid), tty))
    # Prefer a client already showing the session, then the most recently active one.
    for showing, _, pid, tty in sorted(clients, reverse=True):
        address = window_of(pid)
        if address:
            if not showing:
                run("tmux", "switch-client", "-c", tty, "-t", f"={session}")
            focus_window(address)
            return
    terminal = os.environ.get("AGENT_RUN_TERMINAL", "ghostty")
    subprocess.Popen([terminal, "-e", "tmux", "attach-session", "-t", f"={session}"],
                     start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


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
        if self.action in REVIEW_ACTIONS:
            return self.review_worktree(repo)
        if pr["isCrossRepository"]:
            raise AgentRunError("Fix actions need a branch in this repository; this PR comes from a fork.")
        if repo == ABOARD_REPO:
            return self.aboard_worktree(repo, pr["headRefName"])
        return self.branch_worktree(repo, pr["headRefName"])

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

    def branch_worktree(self, repo, branch):
        path = WORKTREE_ROOT / self.repo_name / f"pr-{self.number}"
        if path.resolve() in worktrees(repo):
            return path
        path.parent.mkdir(parents=True, exist_ok=True)
        if run("git", "-C", repo, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}", check=False).returncode == 0:
            run("git", "-C", repo, "worktree", "add", path, branch)
        else:
            run("git", "-C", repo, "worktree", "add", "--track", "-b", branch, path, f"origin/{branch}")
        return path

    def aboard_worktree(self, repo, branch):
        """A full aboard-wt workspace, so agents can run DB-backed tests."""
        name = f"pr-{self.number}"
        path = repo / "worktrees" / name
        if path.resolve() not in worktrees(repo):
            local = run("git", "-C", repo, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}",
                        check=False).returncode == 0
            print("Creating aboard-wt workspace; this seeds databases and takes a few minutes.", flush=True)
            run("aboard-wt", "create", name, "--branch", branch if local else f"origin/{branch}", "--no-open")
        return path

    def command(self, path, agent, text):
        command = agent_command(agent, text)
        config = path / "devenv.local.nix"
        if config.is_file() and config.read_text().startswith("# Generated by aboard-wt."):
            # Run inside the workspace's own devenv, not the environment of whatever launched us.
            return ["aboard-wt", "_pane", path.name, "exec", "--", *command]
        return command

    def execute(self):
        """Runs inside the tmux window: prepare, start agents, then leave a shell in the worktree."""
        path = None
        try:
            pr = self.pull_request()
            if pr["state"] != "OPEN":
                raise AgentRunError(f"Pull request is {pr['state'].lower()}.")
            path = self.prepare(pr)
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
        message = self.message(event, payload)
        record.update(status=status, updated=time.time(), message=message or (
            record.get("message", "") if status == "working" else ""))
        self.dir.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(".tmp")
        temporary.write_text(json.dumps(record))
        temporary.replace(path)

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

    def watch(self):
        previous = None
        while True:
            current = json.dumps(self.list())
            if current != previous:
                print(current, flush=True)
                previous = current
            time.sleep(1)

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

    def running_in(self, path):
        return any(Path(r["cwd"]).resolve() == path or path in Path(r["cwd"]).resolve().parents
                   for r in self.list())


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
    parser.add_argument("action", choices=ACTIONS + ("prune", "sessions", "focus", "hook", "_run"),
                        help="An action on a PR; 'prune' removes worktrees that are no longer needed; "
                             "'sessions' lists live agent sessions, 'focus ID' jumps to one, "
                             "and 'hook AGENT EVENT' records an agent hook event")
    parser.add_argument("args", nargs="*", metavar="url")
    parser.add_argument("--agent", action="append", choices=("claude", "codex", "pi"),
                        help="Agent to use (repeat for side-by-side panes); defaults per action")
    parser.add_argument("--dry-run", action="store_true", help="prune: only show what would be removed")
    parser.add_argument("--watch", action="store_true", help="sessions: print the list again whenever it changes")
    args = parser.parse_args()
    expected = {"prune": 0, "sessions": 0, "focus": 1, "hook": 2, "_run": 2}.get(args.action, 1)
    if len(args.args) != expected:
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
            Sessions().watch() if args.watch else print(json.dumps(Sessions().list(), indent=2))
        elif args.action == "focus":
            Sessions().focus(args.args[0])
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

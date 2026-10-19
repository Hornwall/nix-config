import importlib.util
import os
from pathlib import Path
import pty
import select
import socket
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("aboard_wt", Path(__file__).with_name("aboard-wt.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def git(path, *args):
    return subprocess.run(["git", "-C", str(path), *args], check=True, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.strip()


real_run = module.run


def run_without_services(*args, **kwargs):
    if args[0] in ("direnv", "tmux"):
        return subprocess.CompletedProcess(args, 0, stdout="", stderr="")
    return real_run(*args, **kwargs)


class WorkspacesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="aboard-wt-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.origin = self.base / "origin.git"
        self.repo = self.base / "aboard"
        git(self.base, "init", "--bare", str(self.origin))
        git(self.base, "init", "-b", "main", str(self.repo))
        git(self.repo, "config", "user.name", "Worktree Test")
        git(self.repo, "config", "user.email", "worktree@example.invalid")
        (self.repo / ".gitignore").write_text(".env.development\n.devenv/\ndevenv.local.nix\nworktrees/\n")
        (self.repo / "README").write_text("fixture\n")
        git(self.repo, "add", ".")
        git(self.repo, "commit", "-m", "fixture")
        git(self.repo, "remote", "add", "origin", str(self.origin))
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "branch", "local-feature")
        git(self.repo, "push", "origin", "main:refs/heads/remote-feature")
        git(self.repo, "fetch", "origin")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")
        (self.repo / ".env.development").write_text("HTTP_HOST=aboardhr.localhost\n")
        self.env = patch.dict(os.environ, {"ABOARD_REPO": str(self.repo)}, clear=False)
        self.env.start()
        self.addCleanup(self.env.stop)
        self.workspaces = module.Workspaces()

    def create(self, name="review", **kwargs):
        with patch.object(self.workspaces, "setup"), patch.object(self.workspaces, "open"), \
             patch.object(self.workspaces, "port_busy", return_value=False):
            self.workspaces.create(name, **kwargs)
        return self.repo / "worktrees" / name

    def test_remote_checkout_tracks_branch_and_keeps_main_checkout_unchanged(self):
        path = self.create(branch="origin/remote-feature")
        self.assertEqual(git(path, "branch", "--show-current"), "remote-feature")
        self.assertEqual(git(path, "rev-parse", "--abbrev-ref", "@{upstream}"), "origin/remote-feature")
        self.assertEqual(git(self.repo, "branch", "--show-current"), "main")
        self.assertEqual(git(path, "status", "--porcelain"), "")
        self.assertEqual(self.workspaces.config_slot(path), 1)
        config = (path / "devenv.local.nix").read_text()
        self.assertIn('POSTGRES_HOST = lib.mkForce config.env.PGHOST', config)
        self.assertIn('REDIS_URL = lib.mkForce "redis://127.0.0.1:6380/0"', config)
        self.assertIn('after = [ "devenv:processes:postgres"', config)
        self.assertFalse((path / ".env.development").is_symlink())
        self.assertEqual((path / ".env.development").stat().st_mode & 0o777, 0o600)

    def test_local_checkout_and_already_checked_out_branch(self):
        self.create(branch="local-feature")
        with self.assertRaisesRegex(module.WorkspaceError, "already checked out"):
            self.create("another", branch="local-feature")
        self.assertFalse((self.repo / "worktrees/another").exists())

    def test_new_branch_from_default_base(self):
        path = self.create("new-feature")
        self.assertEqual(git(path, "branch", "--show-current"), "new-feature")
        self.assertEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))

    def test_completion_uses_cached_refs_and_omits_symbolic_head(self):
        self.assertIn("local-feature", self.workspaces.branches())
        self.assertIn("origin/remote-feature", self.workspaces.branches())
        self.assertNotIn("origin/HEAD", self.workspaces.branches())
        self.create(branch="local-feature")
        self.assertEqual(self.workspaces.names(), ["review"])
        # Completion must keep working with an unavailable remote.
        git(self.repo, "remote", "set-url", "origin", "/does/not/exist")
        self.assertIn("origin/remote-feature", self.workspaces.branches())

    def test_reservations_include_stopped_legacy_worktrees_and_accounts_port(self):
        first = self.create("first")
        second = self.create("second")
        third = self.create("third")
        self.assertEqual([self.workspaces.config_slot(p) for p in (first, second, third)], [1, 2, 4])
        # Older helper configs have plain PORT assignments; still reserve their slots.
        (second / "devenv.local.nix").write_text('{ env.PORT = "3002"; }\n  PORT = "3002";\n')
        self.assertEqual(self.workspaces.config_slot(second), 2)
        self.assertNotIn("second", self.workspaces.names())
        with patch.object(self.workspaces, "port_busy", return_value=False):
            self.assertEqual(self.workspaces.allocate_slot(), 5)

    def test_live_listener_is_not_available(self):
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            listener.listen()
            self.assertTrue(self.workspaces.port_busy(listener.getsockname()[1]))

    def test_concurrent_slot_allocation_is_rejected(self):
        with self.workspaces.lock():
            with self.assertRaisesRegex(module.WorkspaceError, "Another aboard-wt operation"):
                with module.Workspaces().lock():
                    pass

    def test_invalid_names_and_unknown_branches_do_not_create_directories(self):
        for name in ("../oops", "a/b", "Uppercase", "x;echo", ""):
            with self.assertRaises(module.WorkspaceError):
                self.workspaces.path(name)
        with self.assertRaisesRegex(module.WorkspaceError, "Unknown"):
            self.create(branch="origin/missing")
        self.assertFalse((self.repo / "worktrees/review").exists())

    def test_parent_environment_cannot_redirect_database_or_devenv(self):
        with patch.dict(os.environ, {"PGHOST": "/main/socket", "DATABASE_URL": "postgres://main",
                                     "DEVENV_ROOT": str(self.repo), "REDIS_URL": "redis://main",
                                     "DIRENV_DIR": str(self.repo), "RAILS_ENV": "production",
                                     "BUNDLE_GEMFILE": str(self.repo / "Gemfile"), "GEM_PATH": "/main/gems"}):
            env = self.workspaces.environment()
        for key in ("PGHOST", "DATABASE_URL", "DEVENV_ROOT", "REDIS_URL", "DIRENV_DIR", "RAILS_ENV",
                    "BUNDLE_GEMFILE", "GEM_PATH"):
            self.assertNotIn(key, env)
        self.assertIn("PATH", env)

    def test_setup_is_once_only_and_starts_databases_before_rails(self):
        path = self.create()
        (path / ".devenv").mkdir()
        calls = []
        with patch.object(module, "run", side_effect=run_without_services), \
             patch.object(self.workspaces, "devenv", side_effect=lambda p, *a: calls.append(a)), \
             patch.object(self.workspaces, "shell_command", side_effect=lambda p, *a: calls.append(a)):
            self.workspaces.setup("review")
            self.assertLess(calls.index(("processes", "wait", "--timeout", "120")),
                            calls.index(("env", "RAILS_ENV=development", "bin/rails", "db:prepare")))
            self.assertEqual(calls[-1], ("processes", "down"))
            calls.clear()
            self.workspaces.setup("review")
            self.assertEqual(calls, [])

    def test_failed_setup_stops_services_and_never_marks_ready(self):
        path = self.create()
        (path / ".devenv").mkdir()

        def shell_command(p, *args):
            if "db:prepare" in args:
                raise module.WorkspaceError("fixture migration failed")

        with patch.object(module, "run", side_effect=run_without_services), patch.object(self.workspaces, "devenv") as devenv, \
             patch.object(self.workspaces, "shell_command", side_effect=shell_command):
            with self.assertRaisesRegex(module.WorkspaceError, "migration failed"):
                self.workspaces.setup("review")
            self.assertEqual(devenv.call_args.args[1:], ("processes", "down"))
        self.assertFalse((path / ".devenv/aboard-wt-prepared").exists())
        self.assertFalse((path / ".devenv/aboard-wt-seeded").exists())

    def test_up_refuses_unprepared_or_already_running_workspace(self):
        path = self.create()
        with self.assertRaisesRegex(module.WorkspaceError, "setup"):
            self.workspaces.up("review")
        (path / ".devenv").mkdir()
        (path / ".devenv/aboard-wt-prepared").touch()
        with patch.object(self.workspaces, "running", return_value=True):
            with self.assertRaisesRegex(module.WorkspaceError, "already running"):
                self.workspaces.up("review")

    def test_remove_refuses_dirty_and_unpushed_work_before_stopping(self):
        path = self.create()
        (path / "README").write_text("changed\n")
        with self.assertRaisesRegex(module.WorkspaceError, "uncommitted"):
            self.workspaces.remove("review")
        git(path, "add", "README")
        git(path, "commit", "-m", "unpublished change")
        with self.assertRaisesRegex(module.WorkspaceError, "not present on a remote"):
            self.workspaces.remove("review")
        self.assertTrue(path.exists())

    def test_zsh_tab_completes_remote_local_and_workspace_names(self):
        self.create()
        bin_dir = self.base / "completion-bin"
        bin_dir.mkdir()
        executable = bin_dir / "aboard-wt"
        executable.write_text(f'#!/bin/sh\nexec {module.shlex.quote(module.sys.executable)} '
                              f'{module.shlex.quote(str(Path(module.__file__).resolve()))} "$@"\n')
        executable.chmod(0o755)
        master, slave = pty.openpty()
        process = subprocess.Popen(["zsh", "-f"], stdin=slave, stdout=slave, stderr=slave,
                                   env={**os.environ, "TERM": "xterm", "PATH": f"{bin_dir}:{os.environ['PATH']}"})
        os.close(slave)
        self.addCleanup(os.close, master)
        self.addCleanup(process.wait)
        self.addCleanup(process.kill)
        completions = Path(__file__).resolve().parents[2] / "dotfiles/zsh/completions"
        buffer_file = self.base / "completed-buffer"
        initialization = (
            f"fpath=({module.shlex.quote(str(completions))} $fpath); "
            "autoload -Uz compinit; compinit -D -i; bindkey '^I' complete-word; "
            f"capture_buffer() {{ print -r -- \"$BUFFER\" > {buffer_file}; }}; "
            "zle -N capture_buffer; bindkey '^X' capture_buffer; PROMPT='WORKTREE_READY> '\n"
        )
        os.write(master, initialization.encode())
        deadline = time.monotonic() + 5
        output = b""
        while b"WORKTREE_READY> \x1b" not in output and time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                output += os.read(master, 65536)
        for typed, expected in (
            ("aboard-wt create review --branch origin/remote-f", "origin/remote-feature"),
            ("aboard-wt create review --branch local-f", "local-feature"),
            ("aboard-wt open rev", "review"),
        ):
            if buffer_file.exists():
                buffer_file.unlink()
            os.write(master, ("\x15" + typed + "\t").encode())
            time.sleep(0.15)
            os.write(master, b"\x18")
            deadline = time.monotonic() + 3
            while not buffer_file.exists() and time.monotonic() < deadline:
                if select.select([master], [], [], 0.05)[0]:
                    os.read(master, 65536)
            self.assertTrue(buffer_file.exists(), "Zsh did not capture the completion buffer")
            self.assertEqual(buffer_file.read_text().strip(), typed.rsplit(" ", 1)[0] + " " + expected)

    def test_tmux_has_editor_and_side_by_side_dev_panes_and_reuses_session(self):
        path = self.create()
        (path / ".devenv").mkdir()
        (path / ".devenv/aboard-wt-prepared").touch()
        bin_dir = self.base / "bin"
        bin_dir.mkdir()
        direnv = bin_dir / "direnv"
        direnv.write_text('#!/bin/sh\nif [ "$1" = allow ]; then exit 0; fi\nshift 2\nexec "$@"\n')
        direnv.chmod(0o755)
        executable = bin_dir / "aboard-wt"
        executable.write_text(f'#!/bin/sh\nexec >>{self.base}/pane.log 2>&1\n'
                              'if [ "$1" = up ]; then exec sleep 600; fi\n'
                              f'exec {module.shlex.quote(module.sys.executable)} '
                              f'{module.shlex.quote(str(Path(module.__file__).resolve()))} "$@"\n')
        executable.chmod(0o755)
        server = f"aboard-wt-test-{os.getpid()}"
        self.addCleanup(lambda: real_run("tmux", "-L", server, "kill-server", capture=True, check=False))

        def private_tmux(*args, **kwargs):
            if args[0] == "tmux":
                if args[1] in ("attach-session", "switch-client"):
                    return subprocess.CompletedProcess(args, 0)
                return real_run("tmux", "-L", server, "-f", "/dev/null", *args[1:], **kwargs)
            return real_run(*args, **kwargs)

        with patch.dict(os.environ, {"PATH": f"{bin_dir}:{os.environ['PATH']}",
                                     "ABOARD_WT_EXE": str(executable), "EDITOR": "sleep 600",
                                     "SHELL": module.shutil.which("bash")}), \
             patch.object(module, "run", side_effect=private_tmux):
            try:
                self.workspaces.open("review")
            except subprocess.CalledProcessError:
                if (self.base / "pane.log").exists():
                    print((self.base / "pane.log").read_text())
                raise
            time.sleep(0.2)
            self.workspaces.open("review")
            windows = private_tmux("tmux", "list-windows", "-t", "=aboard-review", "-F",
                                   "#{window_index} #{window_name} #{window_panes}", capture=True).stdout
            self.assertEqual(windows.splitlines(), ["1 editor 1", "2 dev 2"])
            panes = private_tmux("tmux", "list-panes", "-t", "=aboard-review:2", "-F",
                                 "#{pane_left} #{pane_current_path}", capture=True).stdout.splitlines()
            self.assertEqual(len(panes), 2)
            self.assertEqual(panes[0], f"0 {path}")
            self.assertNotEqual(panes[1].split()[0], "0")
            private_tmux("tmux", "kill-session", "-t", "=aboard-review")
        self.assertTrue(path.exists())
        self.assertTrue((path / ".devenv/aboard-wt-prepared").exists())

    def test_explicit_remove_deletes_ignored_state_but_keeps_branch(self):
        path = self.create()
        (path / ".devenv").mkdir()
        (path / ".devenv/fixture-database").write_text("private state")
        with patch("builtins.input", return_value="review"), patch.object(module.sys.stdin, "isatty", return_value=True), \
             patch.object(self.workspaces, "stop"), patch.object(module, "run", side_effect=run_without_services) as runner:
            self.workspaces.remove("review")
            self.assertFalse(any(call.args[:2] == ("tmux", "kill-session") for call in runner.call_args_list))
        self.assertFalse(path.exists())
        self.assertIn("review", git(self.repo, "branch", "--list"))


if __name__ == "__main__":
    unittest.main()

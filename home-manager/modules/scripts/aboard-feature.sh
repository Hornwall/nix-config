set -euo pipefail

MAIN_REPO="${ABOARD_REPO:-$HOME/code/aboard}"
WORKTREE_ROOT="$MAIN_REPO/worktrees"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aboard-feature/sessions"
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/aboard-feature/teardown.log"
SLOT_COUNT="${ABOARD_FEATURE_SLOT_COUNT:?ABOARD_FEATURE_SLOT_COUNT is not set}"

usage() {
  cat <<EOF
Usage: aboard-feature <branch-name> [base]
       aboard-feature setup
       aboard-feature teardown <session-name>

Creates a worktree under $WORKTREE_ROOT, allocates one of the $SLOT_COUNT nginx
worktree slots, symlinks .env.development from the main checkout, and opens a
tmux session with nvim + claude and a server window running the isolated devenv.

Each worktree gets private Postgres and Redis state in its own .devenv directory.
Its URL is https://app.aboardhr-wt<N>.localhost, where N is the allocated slot.

When the tmux session is killed, devenv is stopped and the worktree (including
its private databases) is removed. Worktrees with uncommitted changes are kept.
Teardown output is written to $LOG_FILE.

  base    Ref to branch from. With no base, an existing remote branch is fetched
          and checked out; otherwise a new branch is created from origin/main.
          Passing a base forces a new branch; pass '.' for the main checkout's
          current HEAD.

  setup     Internal: prepare dependencies and databases before devenv starts.
  teardown  Internal: run by the tmux session-closed hook.
EOF
  exit 1
}

sanitize_name() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    tr -c 'a-z0-9-' '-' |
    cut -c1-48 |
    sed 's/^-*//; s/-*$//'
}

state_file_for() {
  printf '%s/%s' "$STATE_DIR" "$1"
}

ensure_ssh_auth_sock() {
  local runtime_dir candidate

  if [ -S "${SSH_AUTH_SOCK:-}" ]; then
    return
  fi

  runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  for candidate in "$runtime_dir/gcr/ssh" "$runtime_dir/keyring/ssh"; do
    if [ -S "$candidate" ]; then
      export SSH_AUTH_SOCK="$candidate"
      return
    fi
  done
}

port_is_listening() {
  local port="$1"
  ss -H -ltn "sport = :$port" | grep -q .
}

slot_from_config() {
  local config_file="$1"
  sed -n 's/^[[:space:]]*PORT = "\([0-9][0-9]*\)";.*/\1/p' "$config_file" |
    head -n 1
}

allocate_slot() {
  local -a used_slots=()
  local worktree config_file port slot candidate web_port redis_port

  while IFS= read -r worktree; do
    config_file="$worktree/devenv.local.nix"
    [ -f "$config_file" ] || continue
    port="$(slot_from_config "$config_file")"
    [ -n "$port" ] || continue
    slot=$((port - 3000))
    if ((slot >= 1 && slot <= SLOT_COUNT)); then
      used_slots+=("$slot")
    fi
  done < <(git -C "$MAIN_REPO" worktree list --porcelain | sed -n 's/^worktree //p')

  for ((candidate = 1; candidate <= SLOT_COUNT; candidate++)); do
    if printf '%s\n' "${used_slots[@]:-}" | grep -qx "$candidate"; then
      continue
    fi

    web_port=$((3000 + candidate))
    redis_port=$((6379 + candidate))
    if port_is_listening "$web_port" || port_is_listening "$redis_port"; then
      continue
    fi

    printf '%s\n' "$candidate"
    return 0
  done

  echo "error: all $SLOT_COUNT Aboard worktree slots are allocated or busy" >&2
  echo "raise aboardhrWtCount in nixos/thinkpad-z16/aboard.nix and rebuild NixOS" >&2
  return 1
}

write_devenv_config() {
  local dir="$1"
  local slot="$2"
  local web_port=$((3000 + slot))
  local redis_port=$((6379 + slot))

  cat >"$dir/devenv.local.nix" <<EOF
# Gitignored and auto-imported by devenv. Isolated Aboard env on nginx slot $slot:
#   https://app.aboardhr-wt$slot.localhost
{ ... }:
{
  services.redis.port = $redis_port;

  env = {
    PORT = "$web_port";
    OVERMIND_PORT = "$web_port";
    REDIS_URL = "redis://127.0.0.1:$redis_port/0";
    HTTP_HOST = "aboardhr-wt$slot.localhost";
    CANONICAL_HOST = "aboardhr-wt$slot.localhost";
  };

  processes = {
    web = {
      exec = "bundle exec falcon serve --count 1 -b http://127.0.0.1:$web_port";
      process-compose.depends_on = {
        postgres.condition = "process_healthy";
        redis.condition = "process_healthy";
      };
    };
    sidekiq = {
      exec = "bundle exec sidekiq";
      process-compose.depends_on = {
        postgres.condition = "process_healthy";
        redis.condition = "process_healthy";
      };
    };
    js.exec = "npm run build:watch";
    css.exec = "npm run build:css:watch";
  };
}
EOF
}

# Runs inside the worktree in the tmux server window.
setup() {
  [ -f devenv.local.nix ] || {
    echo "error: $PWD has no devenv.local.nix" >&2
    exit 1
  }

  direnv allow "$PWD"

  if ! direnv exec "$PWD" bundle check >/dev/null 2>&1; then
    echo "==> Installing gems..."
    direnv exec "$PWD" bundle install
  fi

  echo "==> Installing node modules..."
  direnv exec "$PWD" npm install

  echo "==> Starting Postgres and Redis for database preparation..."
  devenv up -d --strict-ports postgres redis
  trap 'devenv processes down >/dev/null 2>&1 || true' EXIT
  devenv processes wait --timeout 120

  echo "==> Preparing development database..."
  direnv exec "$PWD" env RAILS_ENV=development bin/rails db:prepare
  echo "==> Preparing test database..."
  direnv exec "$PWD" env RAILS_ENV=test bin/rails db:prepare
  echo "==> Priming demo data..."
  direnv exec "$PWD" bin/rails dev:prime

  devenv processes down
  trap - EXIT
  echo "==> Setup complete; starting the full devenv stack..."
}

# Runs from the global tmux session-closed hook.
teardown() {
  local session="$1"
  local state_file dir
  state_file="$(state_file_for "$session")"
  [ -f "$state_file" ] || exit 0

  dir="$(cat "$state_file")"
  mkdir -p "$(dirname "$LOG_FILE")"
  exec >>"$LOG_FILE" 2>&1
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] tearing down session '$session' ($dir)"

  if [ -d "$dir" ]; then
    (cd "$dir" && devenv processes down) ||
      echo "devenv shutdown failed; processes may need to be stopped manually"
    git -C "$MAIN_REPO" worktree remove "$dir" ||
      echo "worktree not removed (uncommitted changes?); left at $dir"
  fi

  rm -f "$state_file"
  echo "done"
}

case "${1:-}" in
  setup)
    setup
    exit 0
    ;;
  teardown)
    [ "$#" -ge 2 ] || usage
    teardown "$2"
    exit 0
    ;;
esac

[ "$#" -ge 1 ] || usage

branch="$1"
base="${2:-}"

git -C "$MAIN_REPO" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "error: $MAIN_REPO is not a git repository" >&2
  exit 1
}

name="${branch#feature/}"
name="${name#fix/}"
name="${name#chore/}"
name="$(sanitize_name "$name")"
[ -n "$name" ] || {
  echo "error: branch name does not produce a usable worktree name" >&2
  exit 1
}

dir="$WORKTREE_ROOT/$name"
session="aboard-$name"
remote_branch_exists=false

# tmux servers can retain an old login session's SSH_AUTH_SOCK. Repair it before
# contacting GitHub, and distinguish authentication/network errors from a branch
# that genuinely does not exist on the remote.
ensure_ssh_auth_sock
if [ ! -d "$dir" ] &&
  ! git -C "$MAIN_REPO" show-ref --verify --quiet "refs/heads/$branch" &&
  [ -z "$base" ]; then
  remote_error="$(mktemp)"
  if git -C "$MAIN_REPO" ls-remote --exit-code --heads origin "$branch" \
    >/dev/null 2>"$remote_error"; then
    remote_branch_exists=true
  else
    remote_status=$?
    if [ "$remote_status" -ne 2 ]; then
      cat "$remote_error" >&2
      rm -f "$remote_error"
      exit "$remote_status"
    fi
  fi
  rm -f "$remote_error"
fi

mkdir -p "$WORKTREE_ROOT"
if [ -d "$dir" ]; then
  if ! git -C "$MAIN_REPO" worktree list --porcelain |
    grep -Fxq "worktree $dir"; then
    echo "error: $dir exists but is not a worktree of $MAIN_REPO" >&2
    exit 1
  fi
  echo "Worktree $dir already exists, reusing it."
elif git -C "$MAIN_REPO" show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Branch $branch already exists, adding worktree for it."
  git -C "$MAIN_REPO" worktree add "$dir" "$branch"
elif [ "$remote_branch_exists" = true ]; then
  echo "Remote branch origin/$branch exists, checking it out."
  git -C "$MAIN_REPO" fetch origin "$branch"
  git -C "$MAIN_REPO" worktree add --track -b "$branch" "$dir" "origin/$branch"
else
  if [ -z "$base" ]; then
    echo "Fetching origin/main..."
    git -C "$MAIN_REPO" fetch origin main
    base="origin/main"
  elif [ "$base" = "." ]; then
    base="$(git -C "$MAIN_REPO" rev-parse HEAD)"
  fi
  echo "Creating $branch from $base in $dir"
  git -C "$MAIN_REPO" worktree add -b "$branch" "$dir" "$base"
fi

if [ ! -f "$MAIN_REPO/.env.development" ]; then
  echo "error: $MAIN_REPO/.env.development does not exist" >&2
  exit 1
fi
ln -sfn "$MAIN_REPO/.env.development" "$dir/.env.development"

if [ ! -f "$dir/devenv.local.nix" ]; then
  slot="$(allocate_slot)"
  write_devenv_config "$dir" "$slot"
  echo "Allocated nginx slot $slot: https://app.aboardhr-wt$slot.localhost"
else
  port="$(slot_from_config "$dir/devenv.local.nix")"
  if [ -z "$port" ]; then
    echo "error: could not read PORT from $dir/devenv.local.nix" >&2
    exit 1
  fi
  slot=$((port - 3000))
  if ((slot < 1 || slot > SLOT_COUNT)); then
    echo "error: slot $slot in $dir/devenv.local.nix is outside 1..$SLOT_COUNT" >&2
    exit 1
  fi
  echo "Reusing nginx slot $slot: https://app.aboardhr-wt$slot.localhost"
fi

direnv allow "$dir"

mkdir -p "$STATE_DIR"
state_file="$(state_file_for "$session")"
if [ -f "$state_file" ] && [ "$(cat "$state_file")" != "$dir" ]; then
  echo "error: tmux session $session is already tracked for $(cat "$state_file")" >&2
  exit 1
fi
if tmux has-session -t "=$session" 2>/dev/null && [ ! -f "$state_file" ]; then
  echo "error: tmux session $session already exists and is not managed by aboard-feature" >&2
  exit 1
fi
printf '%s\n' "$dir" >"$state_file"

script_path="$(readlink -f "$0")"
tmux set-hook -g 'session-closed[100]' \
  "run-shell '$script_path teardown \"#{hook_session_name}\"'"

if ! tmux has-session -t "=$session" 2>/dev/null; then
  if [ -n "${TMUX:-}" ]; then
    read -r width height < <(
      tmux display-message -p '#{client_width} #{client_height}'
    )
  else
    width="$(tput cols 2>/dev/null || echo 200)"
    height="$(tput lines 2>/dev/null || echo 50)"
  fi

  tmux new-session -d -s "$session" -c "$dir" -n editor -x "$width" -y "$height"
  tmux send-keys -t "=$session:editor" 'nvim' Enter
  tmux split-window -v -l 30% -t "=$session:editor" -c "$dir"
  tmux send-keys -t "=$session:editor" "claude -n \"$branch\"" Enter
  tmux new-window -t "=$session" -n server -c "$dir"
  tmux send-keys -t "=$session:server" \
    'aboard-feature setup && devenv up --strict-ports' Enter
  tmux select-window -t "=$session:editor"
  tmux select-pane -t "=$session:editor.{top}"
fi

global_right="$(tmux show-options -gv status-right 2>/dev/null || true)"
tmux set-option -t "$session" status-right-length 160
tmux set-option -t "$session" status-right \
  "#[dim]https://app.aboardhr-wt$slot.localhost #[default]$global_right"

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$session"
else
  tmux attach-session -t "=$session"
fi

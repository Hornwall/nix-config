#!/usr/bin/env bash
# Add stack context to a {pullRequests, error} result on stdin.
# A PR is stacked when its base branch is the head of another open PR. Each stacked PR gets
# `stack: {id, position, size, parent, children, problems}`, and members of a stack are listed together
# (bottom first) where its most recently updated member was. A PR still based on the branch of a merged PR
# gets `mergedBase: {number, onto}`; problems lists that and the members with conflicts.
set -euo pipefail

input=$(cat)
open='[]'
for repository in $(jq -r '[.pullRequests[].repository] | unique | .[]' <<<"$input"); do
  if pages=$(gh api graphql --paginate -F name="$repository" -f query='
    query($name: String!, $endCursor: String) {
      repository(owner: "Teamtailor", name: $name) {
        defaultBranchRef { name }
        pullRequests(states: OPEN, first: 100, after: $endCursor) {
          nodes {
            number
            title
            baseRefName
            headRefName
            isCrossRepository
            mergeable
            author { login }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    }' 2>/dev/null); then
    open=$(jq -c --arg repository "$repository" --argjson open "$open" -s '$open + [
      .[0].data.repository.defaultBranchRef.name as $default
      | .[].data.repository.pullRequests.nodes[] | select(.isCrossRepository | not)
        | { repository: $repository, number, title, base: .baseRefName, head: .headRefName,
            author: .author.login, conflicting: (.mergeable == "CONFLICTING"), default: $default }
    ]' <<<"$pages")
  fi
done

# A PR based on neither the default branch nor another open PR may still target the branch of a merged PR.
merged='{}'
while IFS=$'\t' read -r repository base default; do
  [[ -n $repository ]] || continue
  if pr=$(gh pr list --repo "Teamtailor/$repository" --head "$base" --state merged --limit 1 \
      --json number --jq 'first.number // empty' 2>/dev/null) && [[ -n $pr ]]; then
    merged=$(jq -c --arg key "$repository:$base" --argjson number "$pr" --arg onto "$default" \
      '. + { ($key): { number: $number, onto: $onto } }' <<<"$merged")
  fi
done < <(jq -r --argjson open "$open" '
  ($open | map("\(.repository):\(.head)")) as $heads
  | [.pullRequests[] | . as $pullRequest
      | $open[] | select(.repository == $pullRequest.repository and .number == $pullRequest.number)]
  | map(select(.base != .default and ("\(.repository):\(.base)" | IN($heads[]) | not)))
  | unique_by([.repository, .base]) | .[] | [.repository, .base, .default] | @tsv' <<<"$input")

jq -c --argjson open "$open" --argjson merged "$merged" '
  ($open | map({ key: "\(.repository):\(.head)", value: . }) | from_entries) as $byHead
  | ($open | group_by("\(.repository):\(.base)")
      | map({ key: "\(.[0].repository):\(.[0].base)", value: sort_by(.number) }) | from_entries) as $byBase
  | def parent: $byHead["\(.repository):\(.base)"];
    def children: $byBase["\(.repository):\(.head)"] // [];
    # Depth limits guard against branch cycles.
    def below($depth): if $depth > 0 and parent then (parent | below($depth - 1)) + [parent] else [] end;
    def above($depth): (children | first) as $child
      | if $depth > 0 and $child then [$child] + ($child | above($depth - 1)) else [] end;
    def brief: { number, title, author };
    def mergedBase: $merged["\(.repository):\(.base)"];

  .pullRequests |= (
    to_entries
    | map(.value as $pullRequest
      | ($open | map(select(.repository == $pullRequest.repository and .number == $pullRequest.number))
          | first) as $self
      | .value + { order: .key, stack: (
          if $self and ($self | parent or (children | length > 0)) then
            ($self | below(50)) as $below | ($self | above(50)) as $above
            | {
                id: "\($self.repository)#\(($below | first // $self).number)",
                position: ($below | length) + 1,
                size: ($below | length) + 1 + ($above | length),
                parent: ($self | parent | if . then brief else null end),
                children: ($self | children | map(brief)),
                problems: (($below + [$self] + $above) as $members
                  | [($members | first | mergedBase | select(.) | "base #\(.number) merged")]
                    + [$members[] | select(.conflicting) | "#\(.number) conflicts"])
              }
          else null end),
        mergedBase: ($self | if . then mergedBase else null end) })
    | group_by(.stack.id // "\(.repository)#\(.number)")
    | sort_by(map(.order) | min)
    | map(sort_by(.stack.position // 0))
    | flatten
    | map(del(.order))
  )
' <<<"$input"

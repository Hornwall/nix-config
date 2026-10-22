#!/usr/bin/env bash
# Add stack context to a {pullRequests, error} result on stdin.
# A PR is stacked when its base branch is the head of another open PR. Each stacked PR gets
# `stack: {id, position, size, parent, children}`, and members of a stack are listed together
# (bottom first) where its most recently updated member was.
set -euo pipefail

input=$(cat)
open='[]'
for repository in $(jq -r '[.pullRequests[].repository] | unique | .[]' <<<"$input"); do
  if pages=$(gh api graphql --paginate -F name="$repository" -f query='
    query($name: String!, $endCursor: String) {
      repository(owner: "Teamtailor", name: $name) {
        pullRequests(states: OPEN, first: 100, after: $endCursor) {
          nodes {
            number
            title
            baseRefName
            headRefName
            isCrossRepository
            author { login }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    }' 2>/dev/null); then
    open=$(jq -c --arg repository "$repository" --argjson open "$open" -s '$open + [
      .[].data.repository.pullRequests.nodes[] | select(.isCrossRepository | not)
        | { repository: $repository, number, title, base: .baseRefName, head: .headRefName,
            author: .author.login }
    ]' <<<"$pages")
  fi
done

jq -c --argjson open "$open" '
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
                children: ($self | children | map(brief))
              }
          else null end) })
    | group_by(.stack.id // "\(.repository)#\(.number)")
    | sort_by(map(.order) | min)
    | map(sort_by(.stack.position // 0))
    | flatten
    | map(del(.order))
  )
' <<<"$input"

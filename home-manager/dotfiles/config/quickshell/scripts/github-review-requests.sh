#!/usr/bin/env bash
# Fetch open Teamtailor pull requests that are waiting for my review.
set -euo pipefail

if ! response=$(gh search prs \
  --owner Teamtailor \
  --review-requested @me \
  --state open \
  --sort updated \
  --order desc \
  --limit 30 \
  --json number,title,repository,url,author,updatedAt,isDraft 2>&1); then
  jq -cn --arg error "$response" '{ pullRequests: [], error: $error }'
  exit 0
fi

jq -c '{
  pullRequests: map({
    number,
    title,
    url,
    updatedAt,
    isDraft,
    repository: .repository.name,
    author: .author.login
  }),
  error: null
}' <<<"$response"

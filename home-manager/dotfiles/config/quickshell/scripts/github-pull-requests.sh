#!/usr/bin/env bash
# Fetch my open Teamtailor pull requests and their review and check status.
set -euo pipefail

if ! response=$(gh api graphql \
  -f query='query($searchQuery: String!) {
    search(query: $searchQuery, type: ISSUE, first: 30) {
      nodes {
        ... on PullRequest {
          number
          title
          url
          updatedAt
          isDraft
          reviewDecision
          mergeable
          mergeStateStatus
          repository { name }
          statusCheckRollup { state }
        }
      }
    }
  }' \
  -f searchQuery='org:Teamtailor is:pr is:open author:@me sort:updated-desc' 2>&1); then
  jq -cn --arg error "$response" '{ pullRequests: [], error: $error }'
  exit 0
fi

jq -c '{
  pullRequests: [.data.search.nodes[] | {
    number,
    title,
    url,
    updatedAt,
    isDraft,
    reviewDecision,
    mergeable,
    mergeStateStatus,
    checkStatus: .statusCheckRollup.state,
    repository: .repository.name
  }],
  error: null
}' <<<"$response"

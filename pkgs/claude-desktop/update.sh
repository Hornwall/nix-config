#!/usr/bin/env nix
#!nix shell --ignore-environment nixpkgs#cacert nixpkgs#coreutils nixpkgs#curl nixpkgs#gawk nixpkgs#jq nixpkgs#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

REPO_URL="https://downloads.claude.ai/claude-desktop/apt/stable"

# Print "version filename sha256" for every claude-desktop entry in an apt index.
packages() {
  curl -fsSL "$REPO_URL/dists/stable/main/binary-$1/Packages" |
    awk -v RS= '/(^|\n)Package: claude-desktop\n/ {
      for (i = 1; i <= NF; i++) {
        if ($i == "Version:") v = $(i + 1)
        if ($i == "Filename:") f = $(i + 1)
        if ($i == "SHA256:") s = $(i + 1)
      }
      print v, f, s
    }'
}

VERSION="${1:-$(packages amd64 | cut -d' ' -f1 | sort -V | tail -n 1)}"

platforms='{}'
for platform in x86_64-linux:amd64 aarch64-linux:arm64; do
  system="${platform%%:*}"
  arch="${platform#*:}"
  read -r _ filename sha256 < <(packages "$arch" | awk -v v="$VERSION" '$1 == v' | tail -n 1) || {
    echo "claude-desktop ${VERSION} not found for ${arch}" >&2
    exit 1
  }
  platforms="$(jq -c --arg system "$system" --arg url "$REPO_URL/$filename" --arg sha256 "$sha256" \
    '.[$system] = { url: $url, sha256: $sha256 }' <<< "$platforms")"
done

echo "Updating claude-desktop manifest to ${VERSION}"
jq -n --arg version "$VERSION" --argjson platforms "$platforms" \
  '{ version: $version, platforms: $platforms }' > manifest.json

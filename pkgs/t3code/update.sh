#!/usr/bin/env nix
#!nix shell --ignore-environment nixpkgs#cacert nixpkgs#coreutils nixpkgs#curl nixpkgs#jq nixpkgs#nix nixpkgs#bash --command bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

VERSION="${1:-$(curl -fsSL https://api.github.com/repos/pingdotgg/t3code/releases/latest | jq -r .tag_name)}"
VERSION="${VERSION#v}"

URL="https://github.com/pingdotgg/t3code/releases/download/v${VERSION}/T3-Code-${VERSION}-x86_64.AppImage"
HASH="$(nix --extra-experimental-features 'nix-command' store prefetch-file --json "$URL" | jq -r .hash)"

echo "Updating t3code manifest to ${VERSION}"
jq -n --arg version "$VERSION" --arg hash "$HASH" '{version: $version, hash: $hash}' > manifest.json

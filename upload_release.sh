#!/bin/bash
# Upload dist/ wheels for a given version to a GitHub release.
#
# Create the release on the remote first (e.g. `gh release create v0.1.0 ...`),
# then run this to attach the wheels. Idempotent: assets already present on the
# release are skipped, so it's safe to re-run after building more wheels.
#
# Usage: ./upload_release.sh <version> [tag]
#   <version>  base package version, e.g. 0.1.0  (uploads dist/<pkg>-<version>+*.whl)
#   [tag]      release tag to upload to            (default: v<version>)
set -euo pipefail

VERSION=${1:?usage: upload_release.sh <version> [release-tag]}
TAG=${2:-v$VERSION}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

shopt -s nullglob
wheels=( "$SCRIPT_DIR"/dist/torch_forced_align-"$VERSION"+*.whl )
shopt -u nullglob

if [ ${#wheels[@]} -eq 0 ]; then
  echo "No wheels for version '$VERSION' in $SCRIPT_DIR/dist/" >&2
  exit 1
fi

# The release must already exist (created manually on the remote). Upload via
# `gh`, which URL-encodes '+' correctly so the PEP 440 local-version label
# survives in the asset name (raw API uploads mangle it to '.').
if ! gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release '$TAG' not found — create it first (e.g. gh release create $TAG)." >&2
  exit 1
fi

# Skip wheels already attached to the release (idempotent re-runs).
mapfile -t existing < <(gh release view "$TAG" --json assets --jq '.assets[].name')
to_upload=()
for w in "${wheels[@]}"; do
  name=$(basename "$w")
  if printf '%s\n' "${existing[@]+"${existing[@]}"}" | grep -qxF "$name"; then
    echo "skip (already uploaded): $name" >&2
  else
    to_upload+=( "$w" )
  fi
done

if [ ${#to_upload[@]} -eq 0 ]; then
  echo "All ${#wheels[@]} wheel(s) for $VERSION already on release $TAG." >&2
  exit 0
fi

echo "Uploading ${#to_upload[@]} of ${#wheels[@]} wheel(s) to release $TAG ..." >&2
gh release upload "$TAG" "${to_upload[@]}"
echo "Done: $TAG now has $(( ${#existing[@]} + ${#to_upload[@]} )) wheel asset(s)." >&2

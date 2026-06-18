#!/usr/bin/env bash
# Sync the skald addon from the skald-godot repo into this project.
set -euo pipefail

SRC="$HOME/repos/skald-godot/addons/skald"
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/addons"
DEST="$DEST_DIR/skald"

if [[ ! -d "$SRC" ]]; then
  echo "Source addon not found: $SRC" >&2
  exit 1
fi

echo "Removing old addon: $DEST"
rm -rf "$DEST"

echo "Copying $SRC -> $DEST"
mkdir -p "$DEST_DIR"
cp -R "$SRC" "$DEST"

echo "Done."

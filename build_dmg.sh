#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_NAME="EasyPubMac-0.1.0"
RELEASE_DIR="$DIST_DIR/$RELEASE_NAME"
DMG_PATH="$DIST_DIR/$RELEASE_NAME.dmg"

"$ROOT_DIR/build_app.sh"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "EasyPubMac" \
  -srcfolder "$RELEASE_DIR" \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH"
echo "DMG: $DMG_PATH"

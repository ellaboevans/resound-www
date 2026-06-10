#!/bin/bash
set -euo pipefail

# ─── Resound DMG Builder ─────────────────────────────────────────────
# Uses create-dmg to build a professional disk image with custom
# background, volume icon, and correct Finder window layout.

# ─── Configuration ───────────────────────────────────────────────────
APP_NAME="Resound"
VOLUME_NAME="$APP_NAME"
DMG_NAME="${APP_NAME}.dmg"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_PATH="${PROJECT_DIR}/${APP_NAME}.app"
ICON_PATH="${PROJECT_DIR}/Sources/${APP_NAME}/Resources/${APP_NAME}.icns"
BACKGROUND="${SCRIPT_DIR}/dmg-background.png"
STAGING_DIR="/tmp/${APP_NAME}-dmg-staging"
FINAL_DMG="${PROJECT_DIR}/${DMG_NAME}"

# ─── Prerequisite checks ────────────────────────────────────────────
if [ ! -d "$APP_PATH" ]; then
    echo "Error: ${APP_PATH} not found. Run 'make release' first."
    exit 1
fi

if [ ! -f "$BACKGROUND" ]; then
    echo "Error: Background not found at ${BACKGROUND}"
    exit 1
fi

if ! command -v create-dmg &>/dev/null; then
    echo "Error: create-dmg not installed. Run: brew install create-dmg"
    exit 1
fi

# ─── Stage contents ─────────────────────────────────────────────────
echo "Staging DMG contents..."
rm -rf "$STAGING_DIR" "$FINAL_DMG"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
cp "$ICON_PATH" "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
cp "${SCRIPT_DIR}/Install Resound.command" "$STAGING_DIR/"
chmod +x "$STAGING_DIR/Install Resound.command"

# Stamp the Resound icon on the install script
if ! command -v fileicon &>/dev/null; then
    echo "Installing fileicon..."
    brew install fileicon >/dev/null 2>&1
fi
fileicon set "$STAGING_DIR/Install Resound.command" "$ICON_PATH" 2>/dev/null

# ─── Build DMG with create-dmg ──────────────────────────────────────
echo "Building DMG..."
create-dmg \
    --volname "$VOLUME_NAME" \
    --volicon "$ICON_PATH" \
    --background "$BACKGROUND" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 80 \
    --icon "$APP_NAME.app" 110 200 \
    --app-drop-link 300 200 \
    --icon "Install Resound.command" 490 200 \
    --hide-extension "$APP_NAME.app" \
    --format UDZO \
    --no-internet-enable \
    "$FINAL_DMG" \
    "$STAGING_DIR"

rm -rf "$STAGING_DIR"

echo "✓ Created $(basename "$FINAL_DMG") ($(du -h "$FINAL_DMG" | awk '{print $1}'))"

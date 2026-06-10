#!/bin/bash
# Install, fix quarantine, and launch Resound

APP_NAME="Resound"
APP_PATH="/Applications/$APP_NAME.app"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DMG_APP="$SELF_DIR/$APP_NAME.app"

# If not already in Applications, copy it
if [ ! -d "$APP_PATH" ]; then
    echo "Copying $APP_NAME to Applications..."
    cp -R "$DMG_APP" "$APP_PATH"
fi

echo "Removing quarantine flag (may ask for your password)..."
sudo xattr -r -d com.apple.quarantine "$APP_PATH" 2>&1

echo "Launching $APP_NAME..."
open "$APP_PATH"

echo "Done!"
sleep 1

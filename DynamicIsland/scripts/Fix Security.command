#!/bin/bash
# Fix Gatekeeper quarantine on Resound.app
# Double-click this after dragging Resound to Applications.

APP="/Applications/Resound.app"

if [ ! -d "$APP" ]; then
    echo "Resound.app not found in /Applications."
    echo "Drag it to your Applications folder first, then run this again."
    echo
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
fi

echo "Removing quarantine flag (may ask for your password)..."
sudo xattr -r -d com.apple.quarantine "$APP" 2>&1

echo "Done! You can now open Resound from your Applications folder."
echo
read -n 1 -s -r -p "Press any key to close..."

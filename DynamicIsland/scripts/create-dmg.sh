#!/bin/bash
set -euo pipefail

APP_NAME="Resound"
STAGING="/tmp/$APP_NAME-dmg"

rm -rf "$STAGING" "${APP_NAME}.dmg"
mkdir -p "$STAGING"
cp -R "${APP_NAME}.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -fs HFS+ -srcfolder "$STAGING" -format UDZO -volname "$APP_NAME" "${APP_NAME}.dmg" > /dev/null
rm -rf "$STAGING"
echo "Created ${APP_NAME}.dmg"

#!/bin/bash
set -euo pipefail

APP_NAME="Sweep"
DMG_NAME="Sweep"
VOLUME_NAME="Sweep"
BG_IMG="dmg/background.png"

# find the built app
APP_PATH="${1:-$(find ~/Library/Developer/Xcode/DerivedData/Sweep-*/Build/Products/Release -name 'Sweep.app' -maxdepth 1 2>/dev/null | head -1)}"
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Sweep-*/Build/Products/Debug -name 'Sweep.app' -maxdepth 1 2>/dev/null | head -1)"
fi

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "error: Sweep.app not found. build first or pass path as argument."
    exit 1
fi

echo "using app: $APP_PATH"

# extract Applications folder icon for the symlink
APPS_ICON_TMP="$(mktemp -d)/Applications.icns"
APPS_ICON_SRC="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns"
if [ -f "$APPS_ICON_SRC" ]; then
    cp "$APPS_ICON_SRC" "$APPS_ICON_TMP"
fi

# clean previous
rm -f "${DMG_NAME}.dmg"

create-dmg \
    --volname "$VOLUME_NAME" \
    --background "$BG_IMG" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 170 180 \
    --app-drop-link 490 180 \
    --text-size 14 \
    --hide-extension "$APP_NAME.app" \
    --no-internet-enable \
    "${DMG_NAME}.dmg" \
    "$APP_PATH"

# hide status bar and toolbar
hdiutil attach -readwrite -noverify -noautoopen "${DMG_NAME}.dmg" -mountpoint /tmp/sweep-dmg-mount 2>/dev/null && {
    osascript <<'APPLESCRIPT'
tell application "Finder"
    tell disk "Sweep"
        open
        tell container window
            set statusbar visible to false
            set toolbar visible to false
        end tell
        close
    end tell
end tell
APPLESCRIPT
    sleep 1
    hdiutil detach /tmp/sweep-dmg-mount >/dev/null 2>&1
} || true

echo "done: ${DMG_NAME}.dmg"

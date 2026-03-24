#!/usr/bin/env bash
# Remove Whisper Hotkey Launch Agent
PLIST_DEST="$HOME/Library/LaunchAgents/com.jeffstelle.whisperhotkey.plist"

launchctl unload "$PLIST_DEST" 2>/dev/null && echo "Agent stopped." || echo "Agent was not running."
rm -f "$PLIST_DEST" && echo "Agent removed. It will no longer start on login."

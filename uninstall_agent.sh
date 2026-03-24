#!/bin/bash
# ============================================================================
# WhisperHotkey — Uninstall Launch Agent (remove from startup)
# ============================================================================

LABEL="com.whisperhotkey.launcher"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm "$PLIST_PATH"
    echo "✓ Launch agent removed. WhisperHotkey will no longer start on login."
else
    echo "Launch agent not found — nothing to remove."
fi

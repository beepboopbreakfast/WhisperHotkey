#!/usr/bin/env bash
# Install Whisper Hotkey as a macOS Login Item (Launch Agent)
set -e

PLIST_SRC="$(cd "$(dirname "$0")" && pwd)/com.jeffstelle.whisperhotkey.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.jeffstelle.whisperhotkey.plist"

echo "=== Installing Whisper Hotkey Launch Agent ==="

# Stop existing agent if running
launchctl unload "$PLIST_DEST" 2>/dev/null || true

# Copy plist to LaunchAgents
cp "$PLIST_SRC" "$PLIST_DEST"

# Load it
launchctl load "$PLIST_DEST"

echo ""
echo "Done! Whisper Hotkey will now start automatically on login."
echo ""
echo "IMPORTANT — grant Accessibility permission to the Python binary:"
echo "  1. System Settings → Privacy & Security → Accessibility"
echo "  2. Click + and navigate to:"
echo "     /Users/jeffstelle/Claude Project/.venv/bin/python3.9"
echo "  3. Toggle it ON"
echo ""
echo "Check logs at: /Users/jeffstelle/Claude Project/whisper_hotkey.log"
echo "To stop:       ./uninstall_agent.sh"

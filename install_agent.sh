#!/bin/bash
# ============================================================================
# WhisperHotkey — Install Launch Agent (start on login)
#
# NOTE: Due to macOS permission restrictions, the recommended approach
# is to have Terminal launch the script. This ensures Terminal's existing
# Accessibility, Input Monitoring, and Microphone permissions are used.
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

LABEL="com.whisperhotkey.launcher"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

# ── Create the wrapper app ────────────────────────────────────────────────
echo "Creating WhisperHotkey launcher app..."

APP_DIR="$SCRIPT_DIR/WhisperHotkey.app/Contents/MacOS"
mkdir -p "$APP_DIR"

cat > "$APP_DIR/WhisperHotkey" << APPEOF
#!/bin/bash
osascript -e '
tell application "Terminal"
    activate
    do script "cd \"$SCRIPT_DIR\" && source .venv/bin/activate && python whisper_hotkey.py"
end tell
'
APPEOF

chmod +x "$APP_DIR/WhisperHotkey"

# ── Create Info.plist for the app ─────────────────────────────────────────
cat > "$SCRIPT_DIR/WhisperHotkey.app/Contents/Info.plist" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>WhisperHotkey</string>
    <key>CFBundleIdentifier</key>
    <string>com.whisperhotkey.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLISTEOF

echo "✓ Created WhisperHotkey.app"

# ── Create Launch Agent ───────────────────────────────────────────────────
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" << LAEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>

    <key>ProgramArguments</key>
    <array>
        <string>open</string>
        <string>$SCRIPT_DIR/WhisperHotkey.app</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/whisper_hotkey.log</string>

    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/whisper_hotkey.log</string>
</dict>
</plist>
LAEOF

launchctl load "$PLIST_PATH" 2>/dev/null || true

echo "✓ Launch agent installed"
echo ""
echo "============================================"
echo "  WhisperHotkey will now start on login!"
echo "============================================"
echo ""
echo "A Terminal window will open with the script"
echo "running when you log in."
echo ""
echo "IMPORTANT: Make sure Terminal has these permissions"
echo "in System Settings → Privacy & Security:"
echo "  • Accessibility  → Terminal ON"
echo "  • Input Monitoring → Terminal ON"
echo "  • Microphone → Terminal ON"
echo ""
echo "To remove: ./uninstall_agent.sh"
echo "============================================"

#!/usr/bin/env bash
# Setup script for whisper_hotkey
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Whisper Hotkey Setup ==="
echo ""

# Check for Python 3.9+
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 not found."
    echo "Install it with: brew install python"
    exit 1
fi

PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "Python $PY_VERSION found."

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
echo "Installing dependencies (this may take a moment)..."
pip install --upgrade pip --quiet
pip install faster-whisper sounddevice numpy pynput

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Run:  ./run.sh"
echo "  2. Grant Microphone access when macOS prompts you."
echo "  3. Grant Accessibility access in:"
echo "     System Settings → Privacy & Security → Accessibility → add Terminal (or your app)"
echo ""
echo "Usage: Hold Right Option (⌥) to record, release to transcribe and paste."

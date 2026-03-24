#!/bin/bash
# ============================================================================
# WhisperHotkey Setup
# Creates a virtual environment and installs all dependencies.
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "============================================"
echo "  WhisperHotkey Setup"
echo "============================================"
echo ""

# ── Check for Python ───────────────────────────────────────────────────────
PYTHON=""
for candidate in python3.11 python3.10 python3.9 python3; do
    if command -v "$candidate" &>/dev/null; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3 not found."
    echo ""
    echo "Install it with Homebrew:"
    echo "  brew install python@3.11"
    echo ""
    exit 1
fi

PYTHON_VERSION=$($PYTHON --version 2>&1)
echo "✓ Found $PYTHON_VERSION"

# ── Check for ffmpeg ──────────────────────────────────────────────────────
if ! command -v ffmpeg &>/dev/null; then
    echo ""
    echo "WARNING: ffmpeg not found. Whisper needs it for audio processing."
    echo "Install it with:"
    echo "  brew install ffmpeg"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ Found ffmpeg"
fi

# ── Create virtual environment ────────────────────────────────────────────
if [ -d ".venv" ]; then
    echo "✓ Virtual environment already exists"
else
    echo ""
    echo "Creating virtual environment..."
    $PYTHON -m venv .venv
    echo "✓ Virtual environment created"
fi

source .venv/bin/activate

# ── Install dependencies ──────────────────────────────────────────────────
echo ""
echo "Installing Python packages (this may take a few minutes)..."
echo ""

pip install --upgrade pip --quiet

pip install \
    faster-whisper \
    sounddevice \
    numpy \
    pynput \
    --quiet

echo ""
echo "✓ All packages installed"

# ── Verify installation ──────────────────────────────────────────────────
echo ""
echo "Verifying installation..."

python -c "
import faster_whisper
import sounddevice
import numpy
import pynput
print('  ✓ faster-whisper')
print('  ✓ sounddevice')
print('  ✓ numpy')
print('  ✓ pynput')
"

# ── Check audio devices ──────────────────────────────────────────────────
echo ""
echo "Audio devices:"
python -c "
import sounddevice as sd
devices = sd.query_devices()
for i, d in enumerate(devices):
    marker = '  '
    if d['max_input_channels'] > 0:
        if i == sd.default.device[0]:
            marker = '> '
        print(f\"  {marker}{d['name']} ({d['max_input_channels']} in)\")
"

echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "To run WhisperHotkey:"
echo "  ./run.sh"
echo ""
echo "First run will download the Whisper model (~150MB)."
echo ""
echo "Make sure to grant permissions in System Settings:"
echo "  • Privacy & Security → Accessibility"
echo "  • Privacy & Security → Input Monitoring"
echo "  • Privacy & Security → Microphone"
echo "============================================"

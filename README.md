# WhisperHotkey

**Local speech-to-text for Mac. Hold a key, speak, release — your words appear as text.**

Everything runs 100% locally on your Mac. No internet needed after setup. No data sent anywhere.

![macOS](https://img.shields.io/badge/macOS-12%2B-blue) ![Python](https://img.shields.io/badge/Python-3.9%2B-green) ![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## How It Works

1. Press and hold **Right Option (⌥)** key
2. Speak naturally
3. Release the key
4. Your words are typed wherever your cursor is

Uses [faster-whisper](https://github.com/SYSTRAN/faster-whisper) for fast, accurate, offline transcription.

## System Requirements

- macOS 12 (Monterey) or later
- 4GB+ free RAM
- ~500MB disk space (for dependencies + speech model)
- A working microphone

## Installation

### 1. Install Homebrew (if you don't have it)

Open **Terminal** (`Cmd + Space` → type "Terminal" → Enter) and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the "Next steps" it prints to add Homebrew to your PATH.

### 2. Install system dependencies

```bash
brew install python@3.11 ffmpeg
```

### 3. Clone this repo

```bash
git clone https://github.com/YOUR_USERNAME/whisper-hotkey.git
cd whisper-hotkey
```

### 4. Run the setup script

```bash
chmod +x setup.sh
./setup.sh
```

This creates a Python virtual environment and installs all dependencies. It may take a few minutes.

### 5. Grant macOS permissions

The app needs three permissions to work. Go to **System Settings → Privacy & Security** and enable:

| Permission | Why |
|---|---|
| **Accessibility** | So it can type text into your apps |
| **Input Monitoring** | So it can detect the hotkey |
| **Microphone** | So it can hear you |

**Tip:** The easiest way is to run the script from Terminal first (see below). macOS will prompt you to grant permissions automatically.

### 6. Run it

```bash
./run.sh
```

Or manually:

```bash
source .venv/bin/activate
python whisper_hotkey.py
```

You should see:

```
Ready. Hold Key.alt_r to record, release to transcribe and paste.
Press Ctrl+C to quit.
```

## Start on Login (Optional)

To have WhisperHotkey start automatically when you log in:

```bash
chmod +x install_agent.sh
./install_agent.sh
```

To remove it from startup:

```bash
chmod +x uninstall_agent.sh
./uninstall_agent.sh
```

**Note on permissions:** When running as a launch agent (background service), macOS may not inherit Terminal's permissions. If you get "not trusted" errors, the simplest workaround is to add the app as a Login Item that opens in Terminal:

1. Create a wrapper script or use the provided `install_agent.sh`
2. Go to **System Settings → General → Login Items**
3. Add Terminal with the run command

See [Troubleshooting](#troubleshooting) for details.

## Configuration

Edit the top of `whisper_hotkey.py` to customize:

```python
# Hotkey — what you hold to record
HOTKEY = keyboard.Key.alt_r       # Right Option key (default)
# HOTKEY = keyboard.Key.f13      # F13 key
# HOTKEY = keyboard.Key.cmd_r    # Right Command key

# Whisper model — bigger = more accurate but slower
MODEL_SIZE = "base.en"            # English only, fast (default)
# MODEL_SIZE = "small.en"        # English only, better accuracy
# MODEL_SIZE = "medium.en"       # English only, best accuracy (needs ~5GB RAM)
# MODEL_SIZE = "base"            # Multilingual
```

## Troubleshooting

**"This process is not trusted"**
The app doesn't have Accessibility or Input Monitoring permission. Go to System Settings → Privacy & Security and add Python or Terminal to both Accessibility and Input Monitoring.

**No orange microphone icon when recording**
Microphone permission hasn't been granted. Run the script from Terminal once — macOS should prompt you. If not, add Terminal (or Python) to Microphone in System Settings → Privacy & Security.

**"No speech detected"**
Speak louder or closer to your mic. Check System Settings → Sound → Input to verify your mic level moves when you speak.

**"App is not trusted" after reboot (launch agent)**
Background services use Python directly, which may not inherit Terminal's permissions. See the [Start on Login](#start-on-login-optional) section for workarounds.

**Script won't start — module not found errors**
Make sure you ran `setup.sh` first. If you moved the folder, re-run setup.

## Uninstall

```bash
# Remove from startup
./uninstall_agent.sh

# Delete the project folder
rm -rf ~/path/to/whisper-hotkey
```

## How It Works (Technical)

1. `pynput` listens for the hotkey (Right Option key by default)
2. When held, `sounddevice` records audio from your default microphone at 16kHz
3. When released, the audio is saved to a temporary WAV file
4. `faster-whisper` transcribes the audio using a local Whisper model
5. The transcribed text is pasted at your cursor using macOS AppleScript

The first run downloads the Whisper model (~150MB for base.en). After that, everything is offline.

## Credits

- [OpenAI Whisper](https://github.com/openai/whisper) — the speech recognition model
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) — optimized Whisper inference
- Built by AI Breakfast with help from [Claude](https://claude.ai) by Anthropic

## License

MIT — do whatever you want with it.

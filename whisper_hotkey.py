#!/usr/bin/env python3
"""
WhisperHotkey — Local speech-to-text via faster-whisper.

Usage:
  Hold RIGHT OPTION (⌥) to record. Release to transcribe and paste.

Requires macOS Accessibility and Microphone permissions.
"""

import os
import sys
import threading
import tempfile
import wave
import subprocess
import time

import numpy as np
import sounddevice as sd
from pynput import keyboard
from faster_whisper import WhisperModel

# ── Configuration ──────────────────────────────────────────────────────────────

# Hotkey to hold while speaking. Common choices:
#   keyboard.Key.alt_r      → Right Option  (default)
#   keyboard.Key.f13        → F13 key
#   keyboard.Key.cmd_r      → Right Command key
HOTKEY = keyboard.Key.alt_r

# Whisper model size. Larger = more accurate but slower to load/transcribe.
# Options: "tiny.en", "base.en", "small.en", "medium.en", "tiny", "base", "small", "medium", "large-v3"
# The ".en" variants are English-only and faster. Remove ".en" for multilingual support.
MODEL_SIZE = "base.en"

# Audio settings
SAMPLE_RATE = 16000  # Whisper expects 16kHz audio

# ── Globals ────────────────────────────────────────────────────────────────────

recording = False
audio_frames = []
stream = None
model = None

# ── Functions ──────────────────────────────────────────────────────────────────

def load_model():
    """Load the Whisper model."""
    global model
    print(f"Loading Whisper '{MODEL_SIZE}' model (first run downloads it)...")
    model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
    print("Ready.  Hold Key.alt_r to record, release to transcribe and paste.")
    print("Press Ctrl+C to quit.")
    print()


def paste_text(text):
    """Paste text at the current cursor position using macOS clipboard + Cmd+V."""
    process = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
    process.communicate(text.encode("utf-8"))
    
    # Small delay to ensure clipboard is set
    time.sleep(0.05)
    
    # Simulate Cmd+V to paste
    script = '''
    tell application "System Events"
        keystroke "v" using command down
    end tell
    '''
    subprocess.run(["osascript", "-e", script], capture_output=True)


def start_recording():
    """Start recording audio from the microphone."""
    global recording, audio_frames, stream
    audio_frames = []
    recording = True

    def callback(indata, frames, time_info, status):
        if status:
            print(f"  (audio status: {status})", file=sys.stderr)
        if recording:
            audio_frames.append(indata.copy())

    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
        callback=callback,
    )
    stream.start()
    print("● Recording...", end=" ", flush=True)


def stop_and_transcribe():
    """Stop recording and transcribe the audio."""
    global recording, stream
    recording = False

    if stream:
        stream.stop()
        stream.close()
        stream = None

    print("■ Stopped.")

    if not audio_frames:
        print("(no audio captured)")
        return

    # Combine all audio frames
    audio_data = np.concatenate(audio_frames, axis=0).flatten()

    # Skip very short recordings (< 0.3 seconds)
    if len(audio_data) < SAMPLE_RATE * 0.3:
        print("(too short)")
        return

    # Save to temporary WAV file
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp_path = f.name
        with wave.open(tmp_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)  # 16-bit
            wf.setframerate(SAMPLE_RATE)
            wf.writeframes((audio_data * 32767).astype(np.int16).tobytes())

    try:
        print("Transcribing...", end=" ", flush=True)
        segments, info = model.transcribe(tmp_path, beam_size=5)
        text = " ".join(seg.text.strip() for seg in segments).strip()

        if text:
            print(f'"{text}"')
            paste_text(text)
        else:
            print("(no speech detected)")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
    finally:
        os.unlink(tmp_path)


# ── Hotkey Listener ────────────────────────────────────────────────────────────

def on_press(key):
    """Handle key press events."""
    global recording
    if key == HOTKEY and not recording:
        start_recording()


def on_release(key):
    """Handle key release events."""
    if key == HOTKEY and recording:
        threading.Thread(target=stop_and_transcribe, daemon=True).start()


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    load_model()

    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        try:
            listener.join()
        except KeyboardInterrupt:
            print("\nQuitting.")


if __name__ == "__main__":
    main()

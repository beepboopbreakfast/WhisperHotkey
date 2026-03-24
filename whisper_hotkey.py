#!/usr/bin/env python3
"""
Whisper Hotkey — Local speech-to-text via OpenAI Whisper.

Usage:
  Hold RIGHT OPTION (⌥) to record. Release to transcribe and paste.

Requires macOS Accessibility and Microphone permissions.
"""

import os
import sys
import threading
import tempfile
import wave

import numpy as np
import sounddevice as sd
from pynput import keyboard
from faster_whisper import WhisperModel

# ── Configuration ──────────────────────────────────────────────────────────────

# Hotkey to hold while speaking. Common choices:
#   keyboard.Key.alt_r      → Right Option  (default)
#   keyboard.Key.f13        → F13 key
#   keyboard.Key.scroll_lock → Scroll Lock
HOTKEY = keyboard.Key.alt_r

# Whisper model size. Larger = more accurate but slower to load/transcribe.
#   "tiny.en"   ~39 MB  — fastest, lower accuracy
#   "base.en"   ~74 MB  — good balance  ← default
#   "small.en"  ~244 MB — better accuracy, ~2-3x slower
#   "medium.en" ~769 MB — near-human accuracy, slow on CPU
MODEL_SIZE = "base.en"

# Set to a specific language code (e.g. "en", "es", "fr") or None for auto-detect
LANGUAGE = "en"

# After transcribing, automatically paste at the cursor using Cmd+V
AUTO_PASTE = True

SAMPLE_RATE = 16000
CHANNELS = 1

# ───────────────────────────────────────────────────────────────────────────────

_recording = False
_audio_chunks: list = []
_lock = threading.Lock()
_model = None


def _load_model() -> None:
    global _model
    print(f"Loading Whisper '{MODEL_SIZE}' model (first run downloads it)...")
    _model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
    print(f"Ready.  Hold {HOTKEY} to record, release to transcribe and paste.")
    print("Press Ctrl+C to quit.\n")


def _audio_callback(indata, frames, time_info, status) -> None:
    if _recording:
        _audio_chunks.append(indata.copy())


def _transcribe_and_paste() -> None:
    with _lock:
        if not _audio_chunks:
            return
        audio = np.concatenate(_audio_chunks, axis=0).flatten()
        _audio_chunks.clear()

    # Skip clips shorter than 0.3 s (accidental keypresses)
    if len(audio) < SAMPLE_RATE * 0.3:
        print("(too short, ignoring)")
        return

    # Write to a temp WAV file
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp_path = f.name

    with wave.open(tmp_path, "w") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes((audio * 32767).astype(np.int16).tobytes())

    print("Transcribing...", end=" ", flush=True)
    segments, _ = _model.transcribe(
        tmp_path,
        language=LANGUAGE,
        vad_filter=True,           # skip silent regions
        vad_parameters={"min_silence_duration_ms": 300},
    )
    text = " ".join(s.text.strip() for s in segments).strip()
    os.unlink(tmp_path)

    if not text:
        print("(no speech detected)")
        return

    print(f'"{text}"')

    # Copy to clipboard
    import subprocess
    proc = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
    proc.communicate(text.encode("utf-8"))

    if AUTO_PASTE:
        # Paste at the current cursor position
        subprocess.run([
            "osascript", "-e",
            'tell application "System Events" to keystroke "v" using command down',
        ], check=False)


def _on_press(key) -> None:
    global _recording
    if key == HOTKEY and not _recording:
        _recording = True
        print("● Recording...", end=" ", flush=True)


def _on_release(key) -> None:
    global _recording
    if key == HOTKEY and _recording:
        _recording = False
        print("■ Stopped.")
        threading.Thread(target=_transcribe_and_paste, daemon=True).start()


def main() -> None:
    _load_model()

    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype="float32",
        callback=_audio_callback,
        blocksize=1024,
    )

    try:
        with stream:
            with keyboard.Listener(on_press=_on_press, on_release=_on_release) as listener:
                listener.join()
    except KeyboardInterrupt:
        print("\nBye.")


if __name__ == "__main__":
    main()

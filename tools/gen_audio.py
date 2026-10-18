#!/usr/bin/env python3
"""Generate School Rush's chiptune music stems and SFX (GDD Section V - Audio).

Pure synthesis (numpy) -> 16-bit mono WAV at 22.05 kHz, written into
assets/audio/. Music loops are rendered to an exact number of bars so they
loop seamlessly at the per-zone tempos: 110 / 130 / 155 BPM.
"""

from __future__ import annotations

import math
import os
import wave

import numpy as np

SR = 22050
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")

# --- Synthesis primitives ---------------------------------------------------


def _t(duration: float) -> np.ndarray:
    return np.arange(int(duration * SR), dtype=np.float64) / SR


def _env(n: int, attack: float = 0.004, release: float = 0.02, decay: float = 0.0) -> np.ndarray:
    env = np.ones(n, dtype=np.float64)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    env[: min(a, n)] = np.linspace(0.0, 1.0, min(a, n))
    if r < n:
        env[-r:] = np.linspace(env[-r], 0.0, r)
    if decay > 0.0:
        env *= np.exp(-np.linspace(0.0, decay, n))
    return env


def square(freq: float, duration: float, volume: float = 0.2, duty: float = 0.5, decay: float = 0.0) -> np.ndarray:
    t = _t(duration)
    phase = (freq * t) % 1.0
    wave_data = np.where(phase < duty, 1.0, -1.0)
    return wave_data * volume * _env(len(t), decay=decay)


def triangle(freq: float, duration: float, volume: float = 0.2, decay: float = 0.0) -> np.ndarray:
    t = _t(duration)
    phase = (freq * t) % 1.0
    wave_data = 4.0 * np.abs(phase - 0.5) - 1.0
    return wave_data * volume * _env(len(t), decay=decay)


def sine(freq: float, duration: float, volume: float = 0.2, decay: float = 1.5) -> np.ndarray:
    t = _t(duration)
    return np.sin(2.0 * np.pi * freq * t) * volume * _env(len(t), decay=decay)


def noise(duration: float, volume: float = 0.2, bright: float = 1.0, decay: float = 2.0, seed: int = 7) -> np.ndarray:
    rng = np.random.default_rng(seed)
    n = int(duration * SR)
    data = rng.uniform(-1.0, 1.0, n)
    if bright < 1.0:
        smooth = np.convolve(data, np.ones(4) / 4.0, mode="same")
        data = data * bright + smooth * (1.0 - bright)
    return data * volume * _env(n, decay=decay)


def midi(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def _add(buffer: np.ndarray, signal: np.ndarray, start_sec: float) -> None:
    start = int(start_sec * SR)
    end = min(len(buffer), start + len(signal))
    if start >= len(buffer) or end <= start:
        return
    buffer[start:end] += signal[: end - start]


def _write(name: str, samples: np.ndarray, peak: float = 0.85) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    data = np.clip(samples, -1.0, 1.0)
    max_val = float(np.max(np.abs(data))) or 1.0
    data = data / max_val * peak
    # 6 ms fades guarantee click-free loops.
    fade = int(0.006 * SR)
    if len(data) > fade * 2:
        data[:fade] *= np.linspace(0.0, 1.0, fade)
        data[-fade:] *= np.linspace(1.0, 0.0, fade)
    pcm = (data * 32767.0).astype("<i2")
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(pcm.tobytes())
    print(f"wrote {name:22s} {len(pcm) / SR:6.2f}s")


# --- Music ------------------------------------------------------------------

HOME_CHORDS = [[60, 64, 67, 72], [55, 59, 62, 67], [57, 60, 64, 69], [53, 57, 60, 65]]
STREET_CHORDS = [[57, 60, 64, 69], [53, 57, 60, 65], [60, 64, 67, 72], [55, 59, 62, 67]]
HALL_CHORDS = [[62, 65, 69, 74], [58, 62, 65, 70], [65, 69, 72, 77], [60, 64, 67, 72]]
MENU_CHORDS = [[60, 64, 67, 72], [57, 60, 64, 69], [53, 57, 60, 65], [55, 59, 62, 67]]

MELODY_MOTIF = [0, 2, 1, 3, 2, 1, 0, 2]


def render_music(bpm: int, bars: int, chords: list[list[int]], swing: bool = False) -> np.ndarray:
    beat = 60.0 / bpm
    bar = beat * 4.0
    step = beat / 4.0
    total = int(bar * bars * SR) + 1
    lead = np.zeros(total)
    harmony = np.zeros(total)
    bass = np.zeros(total)
    drums = np.zeros(total)

    for bar_index in range(bars):
        chord = chords[bar_index % len(chords)]
        bar_start = bar_index * bar
        root = chord[0] - 12

        # Bass: root on 1 and 3, octave bounce on the "and" of 3.
        _add(bass, triangle(midi(root), beat * 0.9, 0.20), bar_start)
        _add(bass, triangle(midi(root), beat * 0.5, 0.14), bar_start + beat * 2.0)
        _add(bass, triangle(midi(root + 12), beat * 0.35, 0.10), bar_start + beat * 3.5)

        # Harmony: fast 16th arpeggio.
        for step_index in range(16):
            note = chord[step_index % len(chord)] + 12
            if step_index % 4 == 3:
                note += 12
            _add(harmony, square(midi(note), step * 0.85, 0.055, duty=0.25, decay=1.2), bar_start + step_index * step)

        # Lead: eighth-note motif, one octave above the chord.
        for i, degree in enumerate(MELODY_MOTIF):
            note = chord[degree % len(chord)] + 12 + (12 if bar_index % 4 == 3 and i > 4 else 0)
            offset = i * beat * 0.5
            if swing and i % 2 == 1:
                offset += beat * 0.06
            _add(lead, square(midi(note), beat * 0.44, 0.11, duty=0.5, decay=0.9), bar_start + offset)

        # Drums.
        for beat_index in range(4):
            t = bar_start + beat_index * beat
            if beat_index in (0, 2):
                kick_t = _t(0.09)
                kick = np.sin(2.0 * np.pi * (150.0 * np.exp(-kick_t * 32.0)) * kick_t)
                _add(drums, kick * 0.35 * _env(len(kick_t), decay=3.0), t)
            if beat_index in (1, 3):
                _add(drums, noise(0.11, 0.16, bright=0.65, decay=3.0, seed=beat_index), t)
            for half in (0.0, 0.5):
                _add(drums, noise(0.035, 0.05, bright=1.0, decay=5.0, seed=11), t + half * beat)

    mixed = lead + harmony + bass + drums
    return mixed[: int(bar * bars * SR)]


def render_drive_layer(bpm: int, bars: int) -> np.ndarray:
    """Percussion-only layer that fades in as run speed climbs."""
    beat = 60.0 / bpm
    bar = beat * 4.0
    total = int(bar * bars * SR)
    buffer = np.zeros(total)
    for bar_index in range(bars):
        for beat_index in range(4):
            t = bar_index * bar + beat_index * beat
            kick_t = _t(0.1)
            kick = np.sin(2.0 * np.pi * (140.0 * np.exp(-kick_t * 28.0)) * kick_t)
            _add(buffer, kick * 0.32 * _env(len(kick_t), decay=3.5), t)
            _add(buffer, noise(0.09, 0.14, bright=0.7, decay=4.0, seed=beat_index), t + beat * 0.5)
            for i in range(4):
                _add(buffer, noise(0.03, 0.06, decay=6.0, seed=21), t + i * beat * 0.25)
    return buffer


# --- SFX --------------------------------------------------------------------


def sfx_jump() -> np.ndarray:
    duration = 0.16
    t = _t(duration)
    freq = 260.0 + 720.0 * (t / duration)
    phase = np.cumsum(freq) / SR
    data = np.where((phase % 1.0) < 0.5, 1.0, -1.0) * 0.28
    return data * _env(len(t), decay=3.0)


def sfx_dash() -> np.ndarray:
    whoosh = noise(0.34, 0.22, bright=0.5, decay=2.0, seed=3)
    sweep_t = _t(0.34)
    sweep = np.sin(2.0 * np.pi * np.cumsum(320.0 + 900.0 * sweep_t / 0.34) / SR) * 0.12
    return whoosh + sweep * _env(len(sweep_t), decay=2.0)


def sfx_slide() -> np.ndarray:
    data = noise(0.28, 0.18, bright=0.35, decay=1.6, seed=5)
    t = _t(0.28)
    return data * (0.6 + 0.4 * np.sin(2.0 * np.pi * 18.0 * t))


def sfx_pickup() -> np.ndarray:
    out = np.zeros(int(0.2 * SR))
    _add(out, square(midi(88), 0.07, 0.18, duty=0.25), 0.0)
    _add(out, square(midi(95), 0.1, 0.16, duty=0.25), 0.06)
    return out


def sfx_combo() -> np.ndarray:
    out = np.zeros(int(0.42 * SR))
    for i, note in enumerate([84, 88, 91, 96]):
        _add(out, square(midi(note), 0.1, 0.14, duty=0.25, decay=1.2), i * 0.06)
    return out


def sfx_lane() -> np.ndarray:
    return square(midi(79), 0.05, 0.10, duty=0.25, decay=4.0)


def sfx_hurt() -> np.ndarray:
    duration = 0.34
    t = _t(duration)
    freq = 320.0 * np.exp(-t * 5.0) + 70.0
    phase = np.cumsum(freq) / SR
    saw = (2.0 * (phase % 1.0) - 1.0) * 0.22
    return (saw + noise(duration, 0.14, bright=0.4, decay=1.5, seed=9)) * _env(len(t), decay=1.2)


def sfx_pursuer() -> np.ndarray:
    duration = 0.9
    t = _t(duration)
    tremolo = 0.75 + 0.25 * np.sin(2.0 * np.pi * 7.0 * t)
    low = triangle(82.0, duration, 0.24) + triangle(110.0, duration, 0.12)
    return low * tremolo * _env(len(t), decay=0.8)


def sfx_bell() -> np.ndarray:
    duration = 1.1
    out = np.zeros(int(duration * SR))
    for i, note in enumerate([84, 88, 91]):
        _add(out, sine(midi(note), 0.9, 0.16, decay=2.6), i * 0.12)
    return out


def sfx_victory() -> np.ndarray:
    duration = 1.4
    out = np.zeros(int(duration * SR))
    for i, note in enumerate([72, 76, 79, 84, 88]):
        _add(out, square(midi(note), 0.24, 0.16, duty=0.5, decay=1.2), i * 0.13)
    return out


def sfx_gameover() -> np.ndarray:
    duration = 1.2
    out = np.zeros(int(duration * SR))
    for i, note in enumerate([64, 60, 55, 48]):
        _add(out, square(midi(note), 0.34, 0.18, duty=0.5, decay=1.1), i * 0.22)
    return out


def sfx_click() -> np.ndarray:
    out = np.zeros(int(0.07 * SR))
    _add(out, square(midi(100), 0.03, 0.12, duty=0.5), 0.0)
    return out


# --- Entry point ------------------------------------------------------------


def main() -> None:
    print(f"rendering audio into {OUT_DIR}")
    _write("music_menu.wav", render_music(100, 8, MENU_CHORDS), peak=0.68)
    _write("music_home.wav", render_music(110, 8, HOME_CHORDS), peak=0.72)
    _write("music_street.wav", render_music(130, 8, STREET_CHORDS), peak=0.72)
    _write("music_hallway.wav", render_music(155, 8, HALL_CHORDS, swing=True), peak=0.72)
    _write("music_drive.wav", render_drive_layer(130, 8), peak=0.6)

    _write("sfx_jump.wav", sfx_jump(), peak=0.8)
    _write("sfx_dash.wav", sfx_dash(), peak=0.8)
    _write("sfx_slide.wav", sfx_slide(), peak=0.8)
    _write("sfx_pickup.wav", sfx_pickup(), peak=0.85)
    _write("sfx_combo.wav", sfx_combo(), peak=0.85)
    _write("sfx_lane.wav", sfx_lane(), peak=0.75)
    _write("sfx_hurt.wav", sfx_hurt(), peak=0.85)
    _write("sfx_pursuer.wav", sfx_pursuer(), peak=0.85)
    _write("sfx_bell.wav", sfx_bell(), peak=0.8)
    _write("sfx_victory.wav", sfx_victory(), peak=0.85)
    _write("sfx_gameover.wav", sfx_gameover(), peak=0.85)
    _write("sfx_click.wav", sfx_click(), peak=0.7)
    print("done")


if __name__ == "__main__":
    main()

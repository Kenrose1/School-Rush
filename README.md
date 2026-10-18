# School Rush

A 2D side‑scrolling, three‑lane arcade runner for **Windows, macOS and Linux**, built in **Godot 4.4** (Compatibility renderer) from the *School Rush — General Game Design Document v1.4* by **ARE STUDIO** (Kenneth Rosell, Hezron Asutilla, Kristyl Faith Enad).

Elias woke up late. Run through the Home Area, the Neighborhood Street and the School Hallway, dodge hazards across three lanes, collect school items for a combo multiplier, and reach the classroom — or survive as long as possible in Continuous Mode while the Pursuer breathes down your neck.

---

## Run it

1. Install **Godot 4.4** (standard build, not .NET — the project uses GDScript only).
2. Open `project.godot`.
3. Press **F5**.

Or from a terminal:

```bash
godot --path .          # add --headless to only validate scripts
```

Target resolution is 1920×1080 at 60 FPS; the window opens at 1280×720 and scales with `canvas_items` stretch.

## Controls

| Action | Key |
| --- | --- |
| Move up a lane | `W` / `↑` |
| Move down a lane | `S` / `↓` |
| Jump | `Space` |
| Slide | `Left Ctrl` |
| Dash (1.5 s shield, 8 s cooldown) | `Left Shift` |
| Pause | `Esc` |
| Menus | Arrows / WASD + `Enter`, mouse |

## Modes

| Mode | Description |
| --- | --- |
| **Standard Run** | Fixed 900 m route: Home → Street → Hallway → classroom. Victory on arrival, with a Distance/Progress meter. |
| **Continuous Mode** | The three zones loop forever; speed ramps up over time. No finish line, no progress meter. |
| **Training** | Short, forgiving Home Area run (220 m) that teaches lanes, jumping, sliding, dash, hearts and the Pursuer. |

## Implemented rules (from the GDD)

- **Three lanes** (top / middle / bottom) with 0.12 s interpolated lane switching.
- **Automatic forward movement**, fixed side‑view camera, player near the left third; the world scrolls right→left so Elias advances left→right toward school.
- **3 hearts**, one per damaging hit, **1.5 s invulnerability** after each hit, **AABB hitbox 10 % smaller** than the sprite.
- **Pursuer Entity**: dormant by default; spawns behind Elias on a hit, matches his slowed speed, fades out over 2.5 s once full speed is recovered. A second hit while it is active triggers a lunge and **instant Game Over regardless of hearts**.
- **School items**: overlap pickup, no interaction button; each is worth `100 × combo`; the multiplier rises every 5 items up to **5×** and resets on a damaging hit.
- **Hazards**: 12 types across the three zones, including ground hazards (jump or dodge), overhead hazards (slide or dodge), and lane‑locked moving hazards (skateboard, vacuum, pet, motorcycle).
- **HUD**: score, hearts, combo, item count, speed meter, dash/cooldown meter, Standard‑only distance meter, pursuer warning, damage flash, i‑frame cue, countdown, zone badges and results banners.
- **Menus**: main menu with personal records, pause (resume / restart / options / main menu), options (music, SFX, screen shake, fullscreen), How to Play, results with Retry.
- **Opening cutscene**: wake up → alarm → 8:45 → dash out (skippable with `Space` / `Esc`).
- **Adaptive chiptune**: 110 BPM Home, 130 BPM Street, 155 BPM Hallway stems cross‑faded by zone, plus a percussion drive layer that fades in with speed. SFX for jump, slide, lane switch, pickup, combo, hurt, dash, bell, pursuer, game over and UI clicks.
- **Persistence**: `user://save.cfg` (ConfigFile) stores volumes, fullscreen, screen shake, personal bests and runs played. On Windows this is `%APPDATA%\Godot\app_userdata\School Rush\save.cfg`.

## Project layout

```
project.godot            Godot 4.4 config, input map, autoloads
scenes/                  main, run_world, player, hazard, collectible, pursuer, hud,
                         main_menu, cutscene
scripts/
  core/game_config.gd    all tuning constants + mode/zone enums
  autoload/              save_manager, game_state, audio_director
  entities/              player, hazard, collectible, pursuer
  world/                 run_world, spawn_director, zone_backdrop, zone_layer
  ui/                    hud, main_menu, pause_menu, options_panel, help_panel,
                         results_screen, cutscene, ui_kit
assets/audio/            generated chiptune stems + SFX (WAV)
tests/                   headless test suite
tools/gen_audio.py       offline chiptune/SFX generator
```

All visuals are drawn procedurally with Godot canvas primitives (`_draw`), so there are **no third‑party art assets and no licensing dependencies**.

## Tests

```bash
godot --headless --path . res://tests/test_runner.tscn
```

Current result: **151 checks, 0 failures**, covering the input map, lane clamping, jump arc and slide hitbox, i‑frames, combo and score math, zone mapping, 3000 fuzzed spawn patterns, pursuer state machine and lunge, save/load round‑trip, audio asset decoding, scene instantiation, a scripted run integration test, mode end conditions, **live Area2D pickup/damage plus jump‑over and slide‑under clearance**, and the full menu → run → pause → menu flow.

## Regenerating audio

```bash
python3 tools/gen_audio.py
```

Requires `numpy`. Rewrites `assets/audio/*.wav` (22.05 kHz mono 16‑bit). Tempos are rendered to exact bar lengths so the loops are seamless.

## Exporting a Windows build

1. In Godot: **Editor → Manage Export Templates → Download and Install**.
2. **Project → Export… → Windows Desktop** (preset already configured, x86_64).
3. Export to `build/windows/SchoolRush.exe` (the `build/` folder is git‑ignored).

Command line, once templates are installed:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/SchoolRush.exe
```

## Notes / limitations

- A rendered visual check was not possible in the build environment used here (headless Linux VM with no GPU/X server). The draw pass itself does run headless — every menu/HUD/zone `_draw` executes without errors and the default font loads — and gameplay is covered by physics‑level tests, but colors, spacing and text fit still deserve a final look in the Godot editor on a desktop.
- The dash key is **Left Shift**; the GDD defines the dash mechanic but does not assign a key.
- The optional in‑editor level placement plugin described in GDD Section IX is not included; hazards are spawned by the data‑driven `SpawnDirector`.

## Central tuning + shared enums for School Rush.
## Values mirror the General Game Design Document v1.4 (Section II, V, VII).
class_name GameConfig
extends RefCounted

enum Mode { STANDARD, CONTINUOUS, TRAINING }
enum Zone { HOME, STREET, HALLWAY }
enum RunState { COUNTDOWN, RUNNING, PAUSED, RESULTS }
enum Lane { TOP, MIDDLE, BOTTOM }

const MODE_NAMES := {
	Mode.STANDARD: "STANDARD RUN",
	Mode.CONTINUOUS: "CONTINUOUS MODE",
	Mode.TRAINING: "TRAINING",
}

# --- Layout -----------------------------------------------------------------
const VIEWPORT_SIZE := Vector2(1920.0, 1080.0)
const LANE_COUNT := 3
const LANE_Y := [620.0, 760.0, 900.0]
const PLAYER_X := 520.0
const LANE_SWITCH_TIME := 0.12

# --- Speed / progression ----------------------------------------------------
const BASE_SPEED := [430.0, 500.0, 570.0]      # px/s per zone
const CONTINUOUS_RAMP := 7.0                    # px/s gained per second
const SPEED_MAX := 980.0
const SPEED_MAX_MULT := 1.0
const HIT_SPEED_MULT := 0.65                    # momentum drop after a hit
const SPEED_RECOVERY := 0.11                    # multiplier regained per second
const PIXELS_PER_METER := 46.0

const ZONE_LENGTH_M := 300.0
const STANDARD_DISTANCE_M := 900.0              # classroom endpoint
const TRAINING_DISTANCE_M := 220.0

# --- Player -----------------------------------------------------------------
const MAX_HEARTS := 3
const INVULN_TIME := 1.5
const DASH_TIME := 1.5
const DASH_COOLDOWN := 8.0
const JUMP_VELOCITY := 1150.0
const GRAVITY := 4200.0
const SLIDE_TIME := 0.72
const HITBOX_SIZE := Vector2(62.0, 104.0)
const HITBOX_SCALE := 0.9                        # 10% smaller than the sprite
const PLAYER_SPRITE_SIZE := Vector2(70.0, 116.0)

# --- Collectibles / score ---------------------------------------------------
const COMBO_MAX := 5
const PICKUPS_PER_COMBO := 5
const SCORE_PER_ITEM := 100
const ITEM_PICKUP_RADIUS := 46.0

# --- Pursuer ----------------------------------------------------------------
const PURSUER_FADE_TIME := 2.5
const PURSUER_X_OFFSET := 340.0
const PURSUER_RECOVERY_RATIO := 0.999

# --- Misc -------------------------------------------------------------------
const SAVE_PATH := "user://save.cfg"
const TARGET_FPS := 60
const ZONE_ACCENT_HEX := ["#ffcf5c", "#7fd3ff", "#ff9ad5"]
const ZONE_NAMES := ["HOME AREA", "NEIGHBORHOOD STREET", "SCHOOL HALLWAY"]
const ZONE_BPM := [110, 130, 155]

static func lane_y(lane: int) -> float:
	return float(LANE_Y[clampi(lane, 0, LANE_COUNT - 1)])

static func clamp_lane(lane: int) -> int:
	return clampi(lane, 0, LANE_COUNT - 1)

static func zone_for_distance(distance_m: float) -> int:
	var index := int(floor(distance_m / ZONE_LENGTH_M))
	return clampi(index, 0, 2)

static func zone_progress(distance_m: float) -> float:
	return clampf(fposmod(distance_m, ZONE_LENGTH_M) / ZONE_LENGTH_M, 0.0, 1.0)

static func combo_for_pickups(items: int) -> int:
	return clampi(1 + items / PICKUPS_PER_COMBO, 1, COMBO_MAX)

static func score_for_item(combo: int) -> int:
	return SCORE_PER_ITEM * clampi(combo, 1, COMBO_MAX)

static func base_speed_for_zone(zone: int) -> float:
	return float(BASE_SPEED[clampi(zone, 0, 2)])

static func zone_accent(zone: int) -> Color:
	return Color(ZONE_ACCENT_HEX[clampi(zone, 0, 2)])

static func mode_name(mode: int) -> String:
	return String(MODE_NAMES.get(mode, "STANDARD RUN"))

static func format_time(seconds: float) -> String:
	var total := int(maxf(0.0, seconds))
	return "%02d:%02d" % [total / 60, total % 60]

static func format_score(score: int) -> String:
	var digits := str(maxi(0, score))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out

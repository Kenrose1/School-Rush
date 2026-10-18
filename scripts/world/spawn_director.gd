## Turn-based pattern spawner. It always leaves at least one lane free so
## every pattern is survivable, and it scales density with run difficulty.
class_name SpawnDirector
extends Node

signal hazard_requested(kind: int, lane: int, extra_speed: float)
signal item_line_requested(kind: String, lane: int, count: int)
signal tutorial_prompt(text: String)

const SPAWN_X := 2140.0
const MIN_GAP := 0.62

var zone: int = GameConfig.Zone.HOME
var difficulty: float = 0.0
var enabled: bool = true
var training: bool = false
var rng := RandomNumberGenerator.new()

var _hazard_timer: float = 1.4
var _item_timer: float = 1.0
var _tutorial_step: int = 0
var _tutorial_distances: Array[float] = [30.0, 70.0, 110.0, 140.0]


func _ready() -> void:
	rng.randomize()


func set_zone(new_zone: int) -> void:
	zone = clampi(new_zone, 0, 2)


func reset() -> void:
	_hazard_timer = 1.6
	_item_timer = 1.2
	_tutorial_step = 0


func _process(delta: float) -> void:
	if not enabled:
		return
	_hazard_timer -= delta
	_item_timer -= delta
	if _hazard_timer <= 0.0:
		spawn_pattern()
		var base := lerpf(1.45, 0.72, clampf(difficulty, 0.0, 1.0))
		if training:
			base = 1.6
		_hazard_timer = maxf(MIN_GAP, base * rng.randf_range(0.88, 1.14))
	if _item_timer <= 0.0:
		spawn_item_line()
		_item_timer = rng.randf_range(1.5, 2.4)


## Emits a guaranteed-passable hazard pattern.
func spawn_pattern() -> Dictionary:
	var pattern := generate_pattern(zone, difficulty, training, rng)
	for entry in pattern["hazards"]:
		hazard_requested.emit(int(entry[0]), int(entry[1]), float(entry[2]))
	_last_open_lane = int(pattern["open_lane"])
	return pattern


## Pure helper kept static so the headless test-suite can fuzz it.
static func generate_pattern(zone_index: int, diff: float, is_training: bool, generator: RandomNumberGenerator) -> Dictionary:
	var allowed: Array = Hazard.ZONE_KINDS[clampi(zone_index, 0, 2)]
	if is_training:
		# Training also needs overhead hazards so sliding can be practiced.
		allowed = allowed.duplicate()
		allowed.append(Hazard.Kind.BANNER)
	var blocked: Array[int] = []
	var hazards: Array = []
	var max_blocked := 2 if diff > 0.35 else 1
	if is_training:
		max_blocked = 1
	var blocked_count := 1
	if max_blocked > 1 and generator.randf() < 0.18 + diff * 0.4:
		blocked_count = 2
	var lanes: Array[int] = [0, 1, 2]
	_shuffle(lanes, generator)
	for i in blocked_count:
		blocked.append(lanes[i])
	blocked.sort()
	for lane in blocked:
		var kind: int = int(allowed[generator.randi_range(0, allowed.size() - 1)])
		var extra := 0.0
		if Hazard.MOVING_KINDS.has(kind):
			extra = generator.randf_range(60.0, 150.0) * (0.5 + diff)
		hazards.append([kind, lane, extra])
	var open_lane := 1
	for lane in [0, 1, 2]:
		if not blocked.has(lane):
			open_lane = lane
			break
	return {
		"hazards": hazards,
		"blocked": blocked,
		"open_lane": open_lane,
	}


var _last_open_lane: int = 1


func spawn_item_line() -> void:
	var lane := _last_open_lane
	if rng.randf() < 0.25:
		lane = rng.randi_range(0, 2)
	var kind: String = Collectible.KINDS[rng.randi_range(0, Collectible.KINDS.size() - 1)]
	var count := rng.randi_range(3, 5)
	item_line_requested.emit(kind, lane, count)


## Tutorial beats: short contextual prompts fired at fixed distances.
func check_tutorial(distance_m: float) -> void:
	if not training or _tutorial_step >= _tutorial_distances.size():
		return
	if distance_m >= _tutorial_distances[_tutorial_step]:
		match _tutorial_step:
			0:
				tutorial_prompt.emit("W / UP and S / DOWN switch lanes - avoid the obstacles!")
			1:
				tutorial_prompt.emit("SPACE jumps over low hazards.")
			2:
				tutorial_prompt.emit("LEFT CTRL slides under overhead hazards.")
			3:
				tutorial_prompt.emit("SHIFT dashes (1.5s shield). A second hit with the Pursuer = GAME OVER.")
		_tutorial_step += 1


static func _shuffle(array: Array[int], generator: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := generator.randi_range(0, i)
		var tmp := array[i]
		array[i] = array[j]
		array[j] = tmp

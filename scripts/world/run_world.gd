## One run of School Rush: owns the run state, scrolling, spawning, score,
## health, pursuit pressure, zone progression and mode win/lose conditions.
class_name RunWorld
extends Node2D

signal run_finished(results: Dictionary)
signal pause_requested
signal shake_requested(strength: float)

enum Phase { INTRO, RUNNING, ENDED }

const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const ITEM_SCENE := preload("res://scenes/collectible.tscn")
const COUNTDOWN_TIME := 2.6

@onready var backdrop: ZoneBackdrop = $Backdrop
@onready var entities: Node2D = $Entities
@onready var player: Player = $Player
@onready var pursuer: Pursuer = $Pursuer
@onready var hud: Hud = $HUDLayer/HUD
@onready var spawner: SpawnDirector = $SpawnDirector
@onready var camera: Camera2D = $Camera

var mode: int = GameConfig.Mode.STANDARD
var phase: int = Phase.INTRO
var countdown: float = COUNTDOWN_TIME
var distance_m: float = 0.0
var elapsed: float = 0.0
var speed: float = GameConfig.BASE_SPEED[0]
var speed_mult: float = 1.0
var score: int = 0
var item_count: int = 0
var combo: int = 1
var max_combo: int = 1
var hearts: int = GameConfig.MAX_HEARTS
var zone: int = GameConfig.Zone.HOME
var target_distance: float = GameConfig.STANDARD_DISTANCE_M
var victory: bool = false
var end_reason: String = ""
var _shake: float = 0.0
var _ended_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	player.lane_changed.connect(_on_lane_changed)
	player.slid.connect(_on_slid)
	player.dashed.connect(_on_dashed)
	player.hit_taken.connect(_on_player_hit)
	player.defeated.connect(_on_player_defeated)
	player.item_picked.connect(_on_item_picked)
	pursuer.caught_player.connect(_on_pursuer_caught)
	spawner.hazard_requested.connect(_spawn_hazard)
	spawner.item_line_requested.connect(_spawn_item_line)
	spawner.tutorial_prompt.connect(_on_tutorial_prompt)
	hud.pause_button_pressed.connect(func() -> void: pause_requested.emit())


func start_run(run_mode: int) -> void:
	mode = run_mode
	GameState.begin_run(mode)
	phase = Phase.INTRO
	countdown = COUNTDOWN_TIME
	distance_m = 0.0
	elapsed = 0.0
	score = 0
	item_count = 0
	combo = 1
	max_combo = 1
	hearts = GameConfig.MAX_HEARTS
	zone = GameConfig.Zone.HOME
	speed_mult = 1.0
	speed = GameConfig.base_speed_for_zone(zone)
	victory = false
	end_reason = ""
	_ended_timer = 0.0
	player.reset_for_run()
	player.input_enabled = true
	pursuer.deactivate()
	spawner.reset()
	spawner.training = (mode == GameConfig.Mode.TRAINING)
	spawner.set_zone(zone)
	spawner.difficulty = 0.0
	spawner.enabled = true
	_clear_entities()
	if mode == GameConfig.Mode.TRAINING:
		target_distance = GameConfig.TRAINING_DISTANCE_M
	else:
		target_distance = GameConfig.STANDARD_DISTANCE_M
	backdrop.set_zone(zone, true)
	AudioDirector.set_intensity(0.0)
	AudioDirector.play_zone_music(zone)
	hud.setup_hud(mode, target_distance)
	hud.set_countdown(3.0)
	hud.set_zone_label(GameConfig.ZONE_NAMES[zone], GameConfig.zone_accent(zone))


func _process(delta: float) -> void:
	match phase:
		Phase.INTRO:
			countdown -= delta
			hud.set_countdown(countdown)
			if countdown <= 0.0:
				phase = Phase.RUNNING
				player.input_enabled = true
				hud.show_go()
		Phase.RUNNING:
			_update_run(delta)
		Phase.ENDED:
			_ended_timer += delta


func _update_run(delta: float) -> void:
	elapsed += delta
	speed_mult = move_toward(speed_mult, 1.0, GameConfig.SPEED_RECOVERY * delta)
	var zone_base: float = GameConfig.base_speed_for_zone(zone)
	if mode == GameConfig.Mode.CONTINUOUS:
		zone_base += GameConfig.CONTINUOUS_RAMP * elapsed
	speed = clampf(zone_base * speed_mult, 150.0, GameConfig.SPEED_MAX)
	distance_m += speed * delta / GameConfig.PIXELS_PER_METER

	var new_zone: int = GameConfig.zone_for_distance(distance_m)
	if mode == GameConfig.Mode.TRAINING:
		new_zone = GameConfig.Zone.HOME
	elif mode == GameConfig.Mode.CONTINUOUS:
		new_zone = int(floor(distance_m / GameConfig.ZONE_LENGTH_M)) % 3
	if new_zone != zone:
		zone = new_zone
		backdrop.set_zone(zone)
		spawner.set_zone(zone)
		AudioDirector.play_zone_music(zone)
		hud.set_zone_label(GameConfig.ZONE_NAMES[zone], GameConfig.zone_accent(zone))
		hud.show_zone_badge(GameConfig.ZONE_NAMES[zone], GameConfig.zone_accent(zone))

	# Difficulty rises with both speed and distance.
	var diff := clampf((speed - 430.0) / (GameConfig.SPEED_MAX - 430.0), 0.0, 1.0) * 0.7
	diff += clampf(distance_m / 700.0, 0.0, 1.0) * 0.3
	if mode == GameConfig.Mode.TRAINING:
		diff = minf(diff, 0.25)
	spawner.difficulty = diff
	spawner.check_tutorial(distance_m)

	_advance_entities(delta)
	backdrop.advance(delta, speed, clampf((speed - 300.0) / 680.0, 0.0, 1.0))
	AudioDirector.set_intensity(clampf((speed - 470.0) / (GameConfig.SPEED_MAX - 470.0), 0.0, 1.0))

	pursuer.update_state(delta, speed_mult)
	pursuer.visible = pursuer.is_active()
	if pursuer.is_active() and pursuer.state != Pursuer.State.LUNGING:
		var target_y := lerpf(pursuer.position.y, player.position.y, clampf(delta * 6.0, 0.0, 1.0))
		pursuer.position = Vector2(player.position.x - GameConfig.PURSUER_X_OFFSET, target_y)
	elif not pursuer.is_active():
		pursuer.position = Vector2(player.position.x - GameConfig.PURSUER_X_OFFSET, player.position.y)

	_update_shake(delta)
	hud.update_hud(_hud_data())

	if mode != GameConfig.Mode.CONTINUOUS and distance_m >= target_distance:
		if mode == GameConfig.Mode.TRAINING:
			_finish(true, "training_complete")
		else:
			_finish(true, "arrived")


func _advance_entities(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("scrolling"):
		if not is_instance_valid(node):
			continue
		var extra := 0.0
		if node is Hazard:
			extra = (node as Hazard).extra_speed
		node.position.x -= (speed + extra) * delta
		if node.position.x < -320.0:
			node.queue_free()


func _hud_data() -> Dictionary:
	return {
		"score": score,
		"hearts": player.hearts,
		"combo": combo,
		"items": item_count,
		"speed": speed,
		"speed_max": GameConfig.SPEED_MAX,
		"distance": distance_m,
		"target": target_distance,
		"mode": mode,
		"dash": player.get_dash_ratio(),
		"dash_cooling": player.dash_cooldown,
		"pursuer": pursuer.is_active(),
		"invulnerable": player.invuln_timer > 0.0,
		"zone": zone,
		"time": elapsed,
	}


# --- Spawning ---------------------------------------------------------------

func _spawn_hazard(kind: int, lane: int, extra_speed: float) -> void:
	var hazard := HAZARD_SCENE.instantiate() as Hazard
	hazard.kind = kind
	hazard.lane = lane
	hazard.extra_speed = extra_speed
	hazard.zone = zone
	hazard.position = Vector2(SpawnDirector.SPAWN_X + randf_range(-40.0, 40.0), GameConfig.lane_y(lane))
	entities.add_child(hazard)


func _spawn_item_line(kind: String, lane: int, count: int) -> void:
	for i in count:
		var item := ITEM_SCENE.instantiate() as Collectible
		item.kind = kind
		item.lane = lane
		item.position = Vector2(SpawnDirector.SPAWN_X + 40.0 + float(i) * 76.0, GameConfig.lane_y(lane) - 74.0)
		entities.add_child(item)


func _clear_entities() -> void:
	for child in entities.get_children():
		child.queue_free()


# --- Player events ----------------------------------------------------------

func _on_lane_changed(_lane: int) -> void:
	pass


func _on_slid() -> void:
	pass


func _on_dashed() -> void:
	pass


func _on_item_picked(_kind: String, world_position: Vector2) -> void:
	if phase != Phase.RUNNING:
		return
	item_count += 1
	var new_combo := GameConfig.combo_for_pickups(item_count)
	var combo_up := new_combo > combo
	combo = new_combo
	max_combo = maxi(max_combo, combo)
	score += GameConfig.score_for_item(combo)
	hud.spawn_score_popup(world_position, GameConfig.score_for_item(combo))
	if combo_up:
		hud.show_combo_badge(combo)
		AudioDirector.play_sfx("combo")
	else:
		AudioDirector.play_sfx("pickup")


func _on_player_hit(hearts_left: int) -> void:
	if phase != Phase.RUNNING:
		return
	hearts = hearts_left
	combo = 1
	speed_mult = GameConfig.HIT_SPEED_MULT
	var fatal := pursuer.is_active()
	hud.flash_damage()
	on_shake(1.0)
	if fatal:
		pursuer.lunge()
		end_reason = "caught"
	else:
		pursuer.activate()
		hud.show_pursuer_warning()
		if mode == GameConfig.Mode.TRAINING:
			hud.show_tutorial_hint("The Pursuer is behind you! Another hit is instant defeat.")


func _on_player_defeated() -> void:
	if phase != Phase.RUNNING:
		return
	hearts = 0
	pursuer.lunge()
	end_reason = "hearts"


func _on_pursuer_caught() -> void:
	if phase != Phase.RUNNING:
		return
	if end_reason == "":
		end_reason = "caught"
	_finish(false, end_reason)


func _on_tutorial_prompt(text: String) -> void:
	hud.show_tutorial_hint(text)


# --- Flow -------------------------------------------------------------------

func request_pause() -> void:
	if phase == Phase.RUNNING:
		pause_requested.emit()


func _finish(did_win: bool, reason: String) -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	end_reason = reason
	victory = did_win
	player.input_enabled = false
	spawner.enabled = false
	AudioDirector.set_intensity(0.0)
	AudioDirector.stop_music(0.5)
	if did_win:
		AudioDirector.play_sfx("bell")
		hud.show_victory_banner()
	else:
		AudioDirector.play_sfx("gameover")
		hud.show_game_over_banner(reason)
	var results := {
		"mode": mode,
		"score": score,
		"items": item_count,
		"distance_m": distance_m,
		"time": elapsed,
		"hearts": player.hearts,
		"victory": did_win,
		"reason": reason,
		"max_combo": max_combo,
	}
	GameState.finish_run(results)
	await get_tree().create_timer(1.6).timeout
	run_finished.emit(results)


func _update_shake(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.4)
		var strength := _shake * 16.0
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO, delta * 90.0)


func on_shake(strength: float) -> void:
	if SaveManager.screen_shake:
		_shake = maxf(_shake, strength)

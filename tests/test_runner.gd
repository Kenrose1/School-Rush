## Headless test suite (GDD Section X - Test Plan).
## Run with:
##   godot --headless --path . res://tests/test_runner.tscn
extends Node

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const ITEM_SCENE := preload("res://scenes/collectible.tscn")
const PURSUER_SCENE := preload("res://scenes/pursuer.tscn")
const RUN_SCENE := preload("res://scenes/run_world.tscn")
const MENU_SCENE := preload("res://scenes/main_menu.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const CUTSCENE_SCENE := preload("res://scenes/cutscene.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	print("=== School Rush test suite ===")
	await _test_input_map()
	await _test_player_lanes()
	await _test_jump_and_slide()
	await _test_health_and_iframes()
	await _test_hitbox_and_layers()
	await _test_scoring_and_zones()
	await _test_spawn_fuzzing()
	await _test_pursuer()
	await _test_save_roundtrip()
	await _test_audio_assets()
	await _test_scenes()
	await _test_run_world_integration()
	await _test_victory_flow()
	await _test_mode_rules()
	await _test_live_collisions()
	await _test_main_flow()

	print("---")
	print("%d checks, %d failure(s)" % [_checks, _failures.size()])
	for failure in _failures:
		print("FAIL: " + failure)
	if _failures.is_empty():
		print("ALL TESTS PASSED")
	get_tree().quit(0 if _failures.is_empty() else 1)


# --- Helpers ----------------------------------------------------------------

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS  " + label)
	else:
		_failures.append(label)
		print("FAIL  " + label)


func _check_eq(actual: Variant, expected: Variant, label: String) -> void:
	_checks += 1
	if actual == expected:
		print("PASS  " + label)
	else:
		_failures.append("%s (expected %s, got %s)" % [label, str(expected), str(actual)])
		print("FAIL  %s (expected %s, got %s)" % [label, str(expected), str(actual)])


func _check_near(actual: float, expected: float, epsilon: float, label: String) -> void:
	_check(absf(actual - expected) <= epsilon, "%s (%.3f ~ %.3f)" % [label, actual, expected])


func _make_player() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	player.reset_for_run()
	return player


# --- Tests ------------------------------------------------------------------

func _test_input_map() -> void:
	for action in ["lane_up", "lane_down", "jump", "slide", "dash", "pause"]:
		_check(InputMap.has_action(action), "input action '%s' exists" % action)
	var events := InputMap.action_get_events("jump")
	_check(not events.is_empty(), "jump is bound to at least one key")


func _test_player_lanes() -> void:
	var player := await _make_player()
	_check_eq(player.lane, 1, "player starts in the middle lane")
	_check(player.move_lane(1), "move down a lane returns true")
	_check_eq(player.lane, 2, "bottom lane reached")
	_check(not player.move_lane(1), "cannot leave the bottom lane")
	_check_eq(player.lane, 2, "bottom lane is clamped")
	player.move_lane(-1)
	player.move_lane(-1)
	_check_eq(player.lane, 0, "top lane reached")
	_check(not player.move_lane(-1), "cannot leave the top lane")
	_check_eq(player.lane, 0, "top lane is clamped")
	_check_near(GameConfig.lane_y(0), 620.0, 0.01, "top lane Y")
	_check_near(GameConfig.lane_y(2), 900.0, 0.01, "bottom lane Y")
	player.queue_free()
	await get_tree().process_frame


func _test_jump_and_slide() -> void:
	var player := await _make_player()
	_check(player.try_jump(), "jump starts when grounded")
	_check(player.airborne, "player is airborne")
	_check(not player.try_jump(), "cannot double jump")
	var peak := 0.0
	for i in 120:
		player._physics_process(1.0 / 60.0)
		peak = maxf(peak, player.jump_height)
	_check(peak > 80.0 and peak < 220.0, "jump arc peaks at a sane height (%.0f px)" % peak)
	_check(not player.airborne, "player lands again")

	_check(player.try_slide(), "slide starts")
	_check(player.sliding, "player is sliding")
	var slide_shape := (player.get_node("Hitbox/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	var slide_height: float = slide_shape.size.y
	_check(slide_height < GameConfig.HITBOX_SIZE.y * 0.6, "slide lowers the hitbox")
	_check(not player.try_jump(), "cannot jump while sliding")
	for i in 60:
		player._physics_process(1.0 / 60.0)
	_check(not player.sliding, "slide ends automatically")
	var stand_shape := (player.get_node("Hitbox/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	var stand_height: float = stand_shape.size.y
	_check(stand_height > slide_height, "hitbox returns to standing height")
	player.queue_free()
	await get_tree().process_frame


func _test_health_and_iframes() -> void:
	var player := await _make_player()
	_check_eq(player.hearts, 3, "run starts with 3 hearts")
	_check(player.take_hit(), "first hit lands")
	_check_eq(player.hearts, 2, "first hit removes one heart")
	_check(player.is_invulnerable(), "hit grants invulnerability")
	_check(not player.take_hit(), "hit during i-frames is ignored")
	_check_eq(player.hearts, 2, "ignored hit costs no heart")
	for i in 100:
		player._physics_process(1.0 / 60.0)
	_check(not player.is_invulnerable(), "i-frames expire after ~1.5s")
	_check(player.take_hit(), "hit lands again after i-frames")
	_check_eq(player.hearts, 1, "second heart lost")
	for i in 100:
		player._physics_process(1.0 / 60.0)
	_check(player.take_hit(), "final hit lands")
	_check_eq(player.hearts, 0, "hearts reach zero")
	_check(player.defeated_state, "player is defeated at zero hearts")
	_check(not player.take_hit(), "no further damage after defeat")
	player.queue_free()
	await get_tree().process_frame


func _test_hitbox_and_layers() -> void:
	var player := await _make_player()
	var shape := (player.get_node("Hitbox/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	var expected := GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	_check_near(shape.size.x, expected.x, 0.5, "hitbox width is 10% smaller than the sprite")
	_check_near(shape.size.y, expected.y, 0.5, "hitbox height is 10% smaller than the sprite")
	var hitbox := player.get_node("Hitbox") as Area2D
	_check_eq(hitbox.collision_layer, 1, "player hitbox is on layer 1")
	_check_eq(hitbox.collision_mask, 6, "player hitbox detects layers 2+3 (hazards + collectibles)")

	var hazard := HAZARD_SCENE.instantiate() as Hazard
	add_child(hazard)
	await get_tree().process_frame
	_check_eq(hazard.collision_layer, 2, "hazard is on layer 2")
	_check_eq(hazard.collision_mask, 0, "hazard does not mask anything (player detects)")
	_check(hazard.is_hazard(), "hazard reports itself as a hazard")
	hazard.queue_free()

	var item := ITEM_SCENE.instantiate() as Collectible
	add_child(item)
	await get_tree().process_frame
	_check_eq(item.collision_layer, 4, "collectible is on layer 3 (bit 4)")
	_check(item.is_collectible(), "collectible reports itself as collectible")
	item.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_scoring_and_zones() -> void:
	_check_eq(GameConfig.combo_for_pickups(0), 1, "combo starts at 1x")
	_check_eq(GameConfig.combo_for_pickups(4), 1, "combo is 1x below five items")
	_check_eq(GameConfig.combo_for_pickups(5), 2, "combo reaches 2x at five items")
	_check_eq(GameConfig.combo_for_pickups(10), 3, "combo reaches 3x at ten items")
	_check_eq(GameConfig.combo_for_pickups(20), 5, "combo reaches 5x at twenty items")
	_check_eq(GameConfig.combo_for_pickups(500), 5, "combo is capped at 5x")
	_check_eq(GameConfig.score_for_item(1), 100, "item scores 100 at 1x")
	_check_eq(GameConfig.score_for_item(5), 500, "item scores 500 at 5x")

	_check_eq(GameConfig.zone_for_distance(0.0), GameConfig.Zone.HOME, "zone 0 at 0 m")
	_check_eq(GameConfig.zone_for_distance(299.0), GameConfig.Zone.HOME, "home area before 300 m")
	_check_eq(GameConfig.zone_for_distance(300.0), GameConfig.Zone.STREET, "street starts at 300 m")
	_check_eq(GameConfig.zone_for_distance(650.0), GameConfig.Zone.HALLWAY, "hallway starts at 600 m")
	_check_eq(GameConfig.STANDARD_DISTANCE_M, 900.0, "standard route is 900 m")
	_check_eq(GameConfig.MAX_HEARTS, 3, "three hearts per run")
	_check_near(GameConfig.INVULN_TIME, 1.5, 0.001, "i-frames last 1.5 s")
	_check_near(GameConfig.DASH_TIME, 1.5, 0.001, "dash shield lasts 1.5 s")
	_check_near(GameConfig.DASH_COOLDOWN, 8.0, 0.001, "dash cooldown is 8 s")
	_check_near(GameConfig.HITBOX_SCALE, 0.9, 0.0001, "hitbox is 90% of sprite size")


func _test_spawn_fuzzing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261017
	var all_ok := true
	var only_valid_kinds := true
	for i in 3000:
		var zone := i % 3
		var pattern := SpawnDirector.generate_pattern(zone, float(i % 100) / 100.0, false, rng)
		var blocked: Array = pattern["blocked"]
		if blocked.size() > 2 or blocked.size() < 1:
			all_ok = false
		if blocked.has(pattern["open_lane"]):
			all_ok = false
		var allowed: Array = Hazard.ZONE_KINDS[zone]
		for entry in pattern["hazards"]:
			if not allowed.has(int(entry[0])):
				only_valid_kinds = false
			if int(entry[1]) < 0 or int(entry[1]) > 2:
				all_ok = false
	_check(all_ok, "3000 generated patterns always leave a free lane")
	_check(only_valid_kinds, "generated hazards always match the current zone")
	var training_bad := false
	for i in 500:
		var pattern := SpawnDirector.generate_pattern(GameConfig.Zone.STREET, 0.9, true, rng)
		if (pattern["blocked"] as Array).size() > 1:
			training_bad = true
	_check(not training_bad, "training mode never blocks more than one lane")


func _test_pursuer() -> void:
	var pursuer := PURSUER_SCENE.instantiate() as Pursuer
	add_child(pursuer)
	await get_tree().process_frame
	_check(pursuer.is_dormant(), "pursuer starts dormant")
	pursuer.activate()
	_check(pursuer.is_active(), "pursuer activates after a hit")
	_check_near(pursuer.opacity, 1.0, 0.001, "pursuer is fully visible when active")
	for i in 40:
		pursuer.update_state(1.0 / 60.0, GameConfig.HIT_SPEED_MULT)
	_check(pursuer.is_active(), "pursuer stays while speed is reduced")
	_check_near(pursuer.opacity, 1.0, 0.01, "pursuer remains opaque while recovering")
	for i in 360:
		pursuer.update_state(1.0 / 60.0, 1.0)
	_check(pursuer.is_dormant(), "pursuer fades out after max speed is regained")

	var caught := [false]
	pursuer.caught_player.connect(func() -> void: caught[0] = true)
	pursuer.activate()
	pursuer.lunge()
	await get_tree().create_timer(0.4).timeout
	_check(caught[0], "pursuer lunge signals the instant-defeat catch")
	pursuer.queue_free()
	await get_tree().process_frame


func _test_save_roundtrip() -> void:
	var original_standard := SaveManager.best_score_standard
	var original_music := SaveManager.music_volume
	SaveManager.best_score_standard = 4242
	SaveManager.music_volume = 0.35
	SaveManager.save_config()
	var config := ConfigFile.new()
	_check_eq(config.load(GameConfig.SAVE_PATH), OK, "save file can be loaded")
	_check_eq(int(config.get_value("records", "standard", -1)), 4242, "best score persists")
	_check_near(float(config.get_value("audio", "music", -1.0)), 0.35, 0.001, "music volume persists")
	SaveManager.best_score_standard = original_standard
	SaveManager.music_volume = original_music
	SaveManager.save_config()
	_check(FileAccess.file_exists(GameConfig.SAVE_PATH), "save.cfg exists after writing")


func _test_audio_assets() -> void:
	for track in ["music_menu", "music_home", "music_street", "music_hallway", "music_drive"]:
		var path := "res://assets/audio/%s.wav" % track
		_check(ResourceLoader.exists(path), "audio asset exists: %s" % track)
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			_check(stream != null and stream.get_length() > 1.0, "audio asset decodes: %s" % track)
	for sfx in ["jump", "slide", "lane", "pickup", "combo", "hurt", "dash", "bell", "gameover", "click", "pursuer", "victory"]:
		var path := "res://assets/audio/sfx_%s.wav" % sfx
		_check(ResourceLoader.exists(path), "sfx asset exists: %s" % sfx)


func _test_scenes() -> void:
	for scene in [MENU_SCENE, HUD_SCENE, CUTSCENE_SCENE, RUN_SCENE]:
		var instance: Node = scene.instantiate()
		_check(instance != null, "scene instantiates: %s" % instance.scene_file_path)
		instance.queue_free()
	await get_tree().process_frame


func _test_run_world_integration() -> void:
	var world := RUN_SCENE.instantiate() as RunWorld
	add_child(world)
	await get_tree().process_frame
	world.start_run(GameConfig.Mode.STANDARD)
	_check_eq(world.phase, RunWorld.Phase.INTRO, "run begins with a countdown")
	_check_eq(world.player.hearts, 3, "integration run starts with 3 hearts")
	# Drive the countdown and ~4 seconds of gameplay manually (headless, no vsync).
	for i in 500:
		world._process(1.0 / 60.0)
		world.spawner._process(1.0 / 60.0)
	_check_eq(world.phase, RunWorld.Phase.RUNNING, "countdown hands control to the player")
	_check(world.distance_m > 10.0, "distance increases while running")
	_check(world.entities.get_child_count() > 0, "hazards/items spawn ahead of the player")
	_check(world.score == 0, "score starts at zero before collecting")
	# Collect five items: 4 x 1x + 1 x 2x = 600.
	for i in 5:
		world._on_item_picked("book", Vector2(500, 600))
	_check_eq(world.item_count, 5, "item counter tracks pickups")
	_check_eq(world.combo, 2, "combo upgrades after five pickups")
	_check_eq(world.score, 600, "score follows 100 x combo per item")
	# First hit: pursuer spawns, momentum drops, combo resets.
	world._on_player_hit(2)
	_check(world.pursuer.is_active(), "a hit activates the pursuer")
	_check_eq(world.combo, 1, "a hit resets the combo")
	_check_near(world.speed_mult, GameConfig.HIT_SPEED_MULT, 0.001, "a hit drops momentum")
	_check_eq(world.pursuer.state, Pursuer.State.ACTIVE, "pursuer enters the active state")
	# Second hit with the pursuer active: instant defeat.
	world._on_player_hit(1)
	world._on_pursuer_caught()
	_check_eq(world.phase, RunWorld.Phase.ENDED, "second hit while pursued ends the run")
	_check_eq(world.end_reason, "caught", "run records the pursuer catch")
	_check_eq(GameState.last_results.get("victory", true), false, "pursuer catch is a loss")
	world.queue_free()
	await get_tree().process_frame


func _test_victory_flow() -> void:
	var world := RUN_SCENE.instantiate() as RunWorld
	add_child(world)
	await get_tree().process_frame
	world.start_run(GameConfig.Mode.STANDARD)
	for i in 170:
		world._process(1.0 / 60.0)
	world.distance_m = GameConfig.STANDARD_DISTANCE_M - 0.5
	world.speed = 500.0
	world._update_run(0.1)
	_check_eq(world.phase, RunWorld.Phase.ENDED, "reaching 900 m ends the run")
	_check(world.victory, "classroom arrival is a victory")
	_check_eq(world.end_reason, "arrived", "victory reason is arrival")
	_check_eq(GameState.last_results.get("victory", false), true, "victory is recorded in GameState")
	world.queue_free()
	await get_tree().process_frame


func _test_main_flow() -> void:
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	_check_eq(main.screen_root.get_child_count(), 1, "game boots into the main menu")
	_check(main.run_world == null, "no run exists on the menu")
	main._on_mode_selected(GameConfig.Mode.TRAINING)
	await get_tree().process_frame
	_check(main.run_world != null, "choosing Training starts a run")
	_check(main.run_world.mode == GameConfig.Mode.TRAINING, "the selected mode reaches the run")
	main.open_pause()
	_check_eq(get_tree().paused, true, "pause menu pauses the game tree")
	_check(main.pause_menu != null, "pause overlay is created")
	main.close_pause()
	_check_eq(get_tree().paused, false, "resume unpauses the game tree")
	main.show_main_menu()
	await get_tree().process_frame
	_check_eq(main.screen_root.get_child_count(), 1, "returning to the menu rebuilds the menu")
	_check(main.run_world == null, "run is discarded when returning to the menu")
	main.queue_free()
	await get_tree().process_frame


func _test_mode_rules() -> void:
	# Continuous Mode must never end at the Standard finish line.
	var world := RUN_SCENE.instantiate() as RunWorld
	add_child(world)
	await get_tree().process_frame
	world.start_run(GameConfig.Mode.CONTINUOUS)
	for i in 170:
		world._process(1.0 / 60.0)
	world.distance_m = 910.0
	world.speed = 600.0
	world._update_run(0.1)
	_check_eq(world.phase, RunWorld.Phase.RUNNING, "continuous mode never ends at 900 m")
	_check_eq(world.zone, GameConfig.Zone.HOME, "continuous mode loops zones after 900 m")
	world.queue_free()
	await get_tree().process_frame

	# Training ends on its own short course with a completion result.
	var training := RUN_SCENE.instantiate() as RunWorld
	add_child(training)
	await get_tree().process_frame
	training.start_run(GameConfig.Mode.TRAINING)
	for i in 170:
		training._process(1.0 / 60.0)
	training.distance_m = GameConfig.TRAINING_DISTANCE_M - 0.2
	training.speed = 600.0
	training._update_run(0.1)
	_check_eq(training.phase, RunWorld.Phase.ENDED, "training ends at the short course distance")
	_check(training.victory, "training completion counts as a win")
	_check_eq(training.end_reason, "training_complete", "training records its completion reason")
	training.queue_free()
	await get_tree().process_frame

	# Hazard action requirements.
	var banner := HAZARD_SCENE.instantiate() as Hazard
	banner.kind = Hazard.Kind.BANNER
	add_child(banner)
	await get_tree().process_frame
	_check(banner.requires_slide, "banner is an overhead hazard cleared by sliding")
	banner.queue_free()
	var cone := HAZARD_SCENE.instantiate() as Hazard
	cone.kind = Hazard.Kind.CONE
	add_child(cone)
	await get_tree().process_frame
	_check(not cone.requires_slide, "cone is a ground hazard cleared by jumping")
	cone.queue_free()
	await get_tree().process_frame


func _test_live_collisions() -> void:
	# Real Area2D overlap through the physics server (player hitbox + entities).
	var world := RUN_SCENE.instantiate() as RunWorld
	add_child(world)
	await get_tree().process_frame
	world.start_run(GameConfig.Mode.STANDARD)
	world.spawner.enabled = false
	world.phase = RunWorld.Phase.RUNNING
	world.player.input_enabled = false
	await get_tree().physics_frame

	var lane := world.player.lane
	world._spawn_item_line("book", lane, 1)
	var item := world.entities.get_child(world.entities.get_child_count() - 1) as Collectible
	item.position = Vector2(world.player.position.x, GameConfig.lane_y(lane) - 74.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check_eq(world.item_count, 1, "walking into a school item collects it (Area2D overlap)")
	_check_eq(world.score, 100, "collected item awards score")

	world._spawn_hazard(Hazard.Kind.CONE, lane, 0.0)
	var hazard := world.entities.get_child(world.entities.get_child_count() - 1) as Hazard
	hazard.position = Vector2(world.player.position.x, GameConfig.lane_y(lane))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check_eq(world.player.hearts, 2, "running into a hazard costs a heart (Area2D overlap)")
	_check(world.pursuer.is_active(), "the live collision spawns the pursuer")
	world.queue_free()
	await get_tree().process_frame

	# Overhead hazard: standing collides, sliding passes underneath.
	var standing := RUN_SCENE.instantiate() as RunWorld
	add_child(standing)
	await get_tree().process_frame
	standing.start_run(GameConfig.Mode.TRAINING)
	standing.spawner.enabled = false
	standing.phase = RunWorld.Phase.RUNNING
	await get_tree().physics_frame
	standing._spawn_hazard(Hazard.Kind.BANNER, standing.player.lane, 0.0)
	var banner_up := standing.entities.get_child(standing.entities.get_child_count() - 1) as Hazard
	banner_up.position = Vector2(standing.player.position.x, GameConfig.lane_y(standing.player.lane))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check_eq(standing.player.hearts, 2, "standing into an overhead hazard costs a heart")
	standing.queue_free()
	await get_tree().process_frame

	var sliding_world := RUN_SCENE.instantiate() as RunWorld
	add_child(sliding_world)
	await get_tree().process_frame
	sliding_world.start_run(GameConfig.Mode.TRAINING)
	sliding_world.spawner.enabled = false
	sliding_world.phase = RunWorld.Phase.RUNNING
	sliding_world.player.try_slide()
	await get_tree().physics_frame
	sliding_world._spawn_hazard(Hazard.Kind.BANNER, sliding_world.player.lane, 0.0)
	var banner_low := sliding_world.entities.get_child(sliding_world.entities.get_child_count() - 1) as Hazard
	banner_low.position = Vector2(sliding_world.player.position.x, GameConfig.lane_y(sliding_world.player.lane))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check_eq(sliding_world.player.hearts, 3, "sliding under an overhead hazard is safe")
	sliding_world.queue_free()
	await get_tree().process_frame

	# Jumping clears a ground hazard: lift the hitbox above the cone.
	var jumper := RUN_SCENE.instantiate() as RunWorld
	add_child(jumper)
	await get_tree().process_frame
	jumper.start_run(GameConfig.Mode.TRAINING)
	jumper.spawner.enabled = false
	jumper.phase = RunWorld.Phase.RUNNING
	jumper.player.airborne = true
	jumper.player.jump_height = 120.0
	jumper.player.jump_speed = 0.0
	jumper.player.hitbox_updated()
	await get_tree().physics_frame
	jumper._spawn_hazard(Hazard.Kind.CONE, jumper.player.lane, 0.0)
	var cone_low := jumper.entities.get_child(jumper.entities.get_child_count() - 1) as Hazard
	cone_low.position = Vector2(jumper.player.position.x, GameConfig.lane_y(jumper.player.lane))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check_eq(jumper.player.hearts, 3, "jumping over a ground hazard is safe")
	jumper.queue_free()
	await get_tree().process_frame

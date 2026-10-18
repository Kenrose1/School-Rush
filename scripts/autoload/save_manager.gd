## Persists settings and best-run records to user://save.cfg (GDD Section X: Test Plan).
extends Node

signal settings_changed

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var screen_shake: bool = true
var fullscreen: bool = false
var tutorial_seen: bool = false

var best_score_standard: int = 0
var best_score_continuous: int = 0
var best_score_training: int = 0
var best_distance_continuous: float = 0.0
var runs_played: int = 0


func _ready() -> void:
	load_config()
	apply_window_mode()


func load_config() -> void:
	var config := ConfigFile.new()
	if config.load(GameConfig.SAVE_PATH) != OK:
		return
	music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	screen_shake = bool(config.get_value("video", "screen_shake", screen_shake))
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	tutorial_seen = bool(config.get_value("progress", "tutorial_seen", tutorial_seen))
	best_score_standard = int(config.get_value("records", "standard", best_score_standard))
	best_score_continuous = int(config.get_value("records", "continuous", best_score_continuous))
	best_score_training = int(config.get_value("records", "training", best_score_training))
	best_distance_continuous = float(config.get_value("records", "continuous_distance", best_distance_continuous))
	runs_played = int(config.get_value("records", "runs", runs_played))


func save_config() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "screen_shake", screen_shake)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("progress", "tutorial_seen", tutorial_seen)
	config.set_value("records", "standard", best_score_standard)
	config.set_value("records", "continuous", best_score_continuous)
	config.set_value("records", "training", best_score_training)
	config.set_value("records", "continuous_distance", best_distance_continuous)
	config.set_value("records", "runs", runs_played)
	var err := config.save(GameConfig.SAVE_PATH)
	if err != OK:
		push_warning("Could not write %s (error %d)" % [GameConfig.SAVE_PATH, err])
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	AudioDirector.apply_volumes()
	save_config()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	AudioDirector.apply_volumes()
	save_config()


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	save_config()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_window_mode()
	save_config()


func apply_window_mode() -> void:
	if not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		)


func best_score_for(mode: int) -> int:
	match mode:
		GameConfig.Mode.STANDARD:
			return best_score_standard
		GameConfig.Mode.CONTINUOUS:
			return best_score_continuous
		_:
			return best_score_training


## Returns true when this run set a new personal record.
func record_run(mode: int, score: int, distance_m: float) -> bool:
	runs_played += 1
	var is_best := false
	match mode:
		GameConfig.Mode.STANDARD:
			if score > best_score_standard:
				best_score_standard = score
				is_best = true
		GameConfig.Mode.CONTINUOUS:
			if score > best_score_continuous:
				best_score_continuous = score
				is_best = true
			best_distance_continuous = maxf(best_distance_continuous, distance_m)
		GameConfig.Mode.TRAINING:
			if score > best_score_training:
				best_score_training = score
				is_best = true
	save_config()
	return is_best


func reset_records() -> void:
	best_score_standard = 0
	best_score_continuous = 0
	best_score_training = 0
	best_distance_continuous = 0.0
	tutorial_seen = false
	save_config()

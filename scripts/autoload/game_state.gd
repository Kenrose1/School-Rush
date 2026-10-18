## Session-level state shared by the main flow, run world and HUD.
extends Node

signal mode_changed(mode: int)

var selected_mode: int = GameConfig.Mode.STANDARD
var last_results: Dictionary = {}
var last_run_was_best: bool = false
var skip_cutscene: bool = false


func select_mode(mode: int) -> void:
	selected_mode = mode
	mode_changed.emit(mode)


func begin_run(mode: int) -> void:
	selected_mode = mode
	last_results = {}


func finish_run(results: Dictionary) -> void:
	last_results = results.duplicate(true)
	last_run_was_best = SaveManager.record_run(
		int(results.get("mode", selected_mode)),
		int(results.get("score", 0)),
		float(results.get("distance_m", 0.0))
	)


func clear_results() -> void:
	last_results = {}
	last_run_was_best = false


func is_continuous() -> bool:
	return selected_mode == GameConfig.Mode.CONTINUOUS


func is_training() -> bool:
	return selected_mode == GameConfig.Mode.TRAINING

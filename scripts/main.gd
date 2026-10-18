## Top-level game flow: Main Menu -> (cutscene) -> Run -> Results, plus the
## pause/options/help overlays (GDD Section II - Screen Flow).
extends Node

const MENU_SCENE := preload("res://scenes/main_menu.tscn")
const CUTSCENE_SCENE := preload("res://scenes/cutscene.tscn")
const RUN_SCENE := preload("res://scenes/run_world.tscn")

@onready var screen_root: Node = $ScreenRoot
@onready var ui_layer: CanvasLayer = $UI

var run_world: RunWorld = null
var pause_menu: PauseMenu = null
var options_panel: OptionsPanel = null
var help_panel: HelpPanel = null
var results_screen: ResultsScreen = null
var _mode: int = GameConfig.Mode.STANDARD
var _in_run: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.title = "School Rush"
	AudioDirector.apply_volumes()
	show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _in_run and not get_tree().paused and pause_menu == null:
			open_pause()
			get_viewport().set_input_as_handled()


# --- Screens ----------------------------------------------------------------

func _clear_screen() -> void:
	for child in screen_root.get_children():
		screen_root.remove_child(child)
		child.queue_free()
	run_world = null
	results_screen = null
	_in_run = false


func _clear_overlays() -> void:
	for overlay in [pause_menu, options_panel, help_panel]:
		if overlay != null and is_instance_valid(overlay):
			overlay.queue_free()
	pause_menu = null
	options_panel = null
	help_panel = null


func show_main_menu() -> void:
	get_tree().paused = false
	_clear_overlays()
	_clear_screen()
	AudioDirector.set_intensity(0.0)
	AudioDirector.play_music("music_menu")
	var menu := MENU_SCENE.instantiate() as MainMenu
	menu.mode_selected.connect(_on_mode_selected)
	menu.options_requested.connect(open_options)
	menu.help_requested.connect(open_help)
	menu.quit_requested.connect(_on_quit)
	screen_root.add_child(menu)


func _on_mode_selected(mode: int) -> void:
	_mode = mode
	GameState.select_mode(mode)
	if mode == GameConfig.Mode.TRAINING:
		start_run(mode)
		return
	show_cutscene(mode)


func show_cutscene(mode: int) -> void:
	_clear_screen()
	AudioDirector.stop_music(0.3)
	var cutscene := CUTSCENE_SCENE.instantiate() as Cutscene
	cutscene.finished.connect(func() -> void:
		cutscene.queue_free()
		start_run(mode)
	)
	screen_root.add_child(cutscene)


func start_run(mode: int) -> void:
	get_tree().paused = false
	_clear_overlays()
	_clear_screen()
	AudioDirector.stop_music(0.2)
	var world := RUN_SCENE.instantiate() as RunWorld
	run_world = world
	world.run_finished.connect(_on_run_finished)
	world.pause_requested.connect(open_pause)
	screen_root.add_child(world)
	world.start_run(mode)
	_in_run = true


func _on_run_finished(results: Dictionary) -> void:
	get_tree().paused = false
	_in_run = false
	_clear_screen()
	AudioDirector.play_music("music_menu")
	var screen := ResultsScreen.new()
	results_screen = screen
	screen.setup(results, GameState.last_run_was_best)
	screen.retry_requested.connect(func() -> void: start_run(int(results.get("mode", _mode))))
	screen.main_menu_requested.connect(show_main_menu)
	screen_root.add_child(screen)


# --- Overlays ---------------------------------------------------------------

func open_pause() -> void:
	if run_world == null or pause_menu != null:
		return
	var stats := {
		"score": run_world.score,
		"items": run_world.item_count,
		"combo": run_world.combo,
		"distance": run_world.distance_m,
		"time": run_world.elapsed,
	}
	get_tree().paused = true
	pause_menu = PauseMenu.new()
	pause_menu.setup(stats)
	pause_menu.resumed.connect(close_pause)
	pause_menu.restart_requested.connect(func() -> void:
		close_pause()
		start_run(_mode)
	)
	pause_menu.options_requested.connect(open_options)
	pause_menu.main_menu_requested.connect(func() -> void:
		close_pause()
		show_main_menu()
	)
	ui_layer.add_child(pause_menu)


func close_pause() -> void:
	if pause_menu != null and is_instance_valid(pause_menu):
		pause_menu.queue_free()
	pause_menu = null
	get_tree().paused = false


func open_options() -> void:
	if options_panel != null:
		return
	options_panel = OptionsPanel.new()
	options_panel.closed.connect(func() -> void:
		var panel := options_panel
		options_panel = null
		if panel != null and is_instance_valid(panel):
			panel.queue_free()
	)
	ui_layer.add_child(options_panel)


func open_help() -> void:
	if help_panel != null:
		return
	help_panel = HelpPanel.new()
	help_panel.closed.connect(func() -> void:
		var panel := help_panel
		help_panel = null
		if panel != null and is_instance_valid(panel):
			panel.queue_free()
	)
	ui_layer.add_child(help_panel)


func _on_quit() -> void:
	SaveManager.save_config()
	get_tree().quit()

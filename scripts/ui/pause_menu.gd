## Pause Menu (GDD Section II - Screen Flow).
class_name PauseMenu
extends Control

signal resumed
signal restart_requested
signal options_requested
signal main_menu_requested

var _stats: Dictionary = {}
var _first_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_build()


func setup(stats: Dictionary) -> void:
	_stats = stats


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		resumed.emit()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var panel := UiKit.panel_container()
	panel.position = Vector2(620, 210)
	panel.size = Vector2(680, 660)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var heading := UiKit.label("PAUSED", UiKit.FONT_HEADING, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(heading)
	box.add_child(UiKit.hsep(2))
	box.add_child(UiKit.label("CURRENT RUN", 20, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(
		"SCORE %s     ITEMS %d     COMBO x%d" % [
			GameConfig.format_score(int(_stats.get("score", 0))),
			int(_stats.get("items", 0)),
			int(_stats.get("combo", 1)),
		],
		24, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER
	))
	box.add_child(UiKit.label(
		"DISTANCE %d m     TIME %s" % [
			int(_stats.get("distance", 0.0)),
			GameConfig.format_time(float(_stats.get("time", 0.0))),
		],
		22, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER
	))
	box.add_child(UiKit.spacer(12))

	var resume := UiKit.button("RESUME", true)
	var restart := UiKit.button("RESTART RUN")
	var options := UiKit.button("OPTIONS")
	var menu := UiKit.button("MAIN MENU")
	for button in [resume, restart, options, menu]:
		button.custom_minimum_size = Vector2(620, 62)
		box.add_child(button)
	resume.pressed.connect(func() -> void: resumed.emit())
	restart.pressed.connect(func() -> void: restart_requested.emit())
	options.pressed.connect(func() -> void: options_requested.emit())
	menu.pressed.connect(func() -> void: main_menu_requested.emit())
	resume.grab_focus.call_deferred()
	_first_button = resume


func focus_first() -> void:
	if _first_button != null:
		_first_button.grab_focus()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.03, 0.06, 0.72))

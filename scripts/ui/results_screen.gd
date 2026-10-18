## Results screen for both the classroom arrival (victory) and Game Over
## (GDD Section II - Replaying and Saving / Screen Flow).
class_name ResultsScreen
extends Control

signal retry_requested
signal main_menu_requested

var results: Dictionary = {}
var is_new_best: bool = false
var _time: float = 0.0
var _confetti: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_build()
	_seed_confetti()
	set_process(true)


func setup(run_results: Dictionary, new_best: bool) -> void:
	results = run_results.duplicate(true)
	is_new_best = new_best
	if is_inside_tree():
		_build()
		_seed_confetti()


func _process(delta: float) -> void:
	_time += delta
	for piece in _confetti:
		piece["y"] = float(piece["y"]) + float(piece["speed"]) * delta
		piece["x"] = float(piece["x"]) + sin(_time * 2.0 + float(piece["phase"])) * 24.0 * delta
		if float(piece["y"]) > 1120.0:
			piece["y"] = -40.0
	queue_redraw()


func _seed_confetti() -> void:
	_confetti.clear()
	if not bool(results.get("victory", false)):
		return
	for i in 60:
		_confetti.append({
			"x": randf() * 1920.0,
			"y": randf() * 1080.0 - 1080.0,
			"speed": randf_range(70.0, 190.0),
			"phase": randf() * TAU,
			"color": [UiKit.GOLD, UiKit.CYAN, UiKit.PINK, UiKit.GREEN][i % 4],
			"size": randf_range(8.0, 16.0),
		})


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var victory := bool(results.get("victory", false))
	var panel := UiKit.panel_container(UiKit.panel_style(Color(0.04, 0.05, 0.1, 0.95), UiKit.GOLD if victory else UiKit.RED))
	panel.position = Vector2(510, 170)
	panel.size = Vector2(900, 760)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	box.add_child(UiKit.label(
		"CLASSROOM REACHED!" if victory else "GAME OVER",
		UiKit.FONT_HEADING,
		UiKit.GOLD if victory else UiKit.RED,
		HORIZONTAL_ALIGNMENT_CENTER
	))
	var mode := int(results.get("mode", GameConfig.Mode.STANDARD))
	var reason := String(results.get("reason", ""))
	var subtitle := ""
	if victory:
		subtitle = "Standard Run complete." if mode == GameConfig.Mode.STANDARD else "Training complete - you're ready."
	else:
		match reason:
			"caught":
				subtitle = "Caught by the Pursuer."
			"hearts":
				subtitle = "Out of hearts."
			_:
				subtitle = "Run ended."
	box.add_child(UiKit.label(subtitle, 24, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(GameConfig.mode_name(mode), 22, UiKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.hsep())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	var rows := [
		["SCORE", GameConfig.format_score(int(results.get("score", 0)))],
		["SCHOOL ITEMS", str(int(results.get("items", 0)))],
		["BEST COMBO", "x%d" % int(results.get("max_combo", 1))],
		["DISTANCE", "%d m" % int(results.get("distance_m", 0.0))],
		["TIME", GameConfig.format_time(float(results.get("time", 0.0)))],
		["HEARTS LEFT", "%d / %d" % [int(results.get("hearts", 0)), GameConfig.MAX_HEARTS]],
	]
	for row in rows:
		grid.add_child(UiKit.label(row[0], 24, UiKit.MUTED))
		var value := UiKit.label(row[1], 26, UiKit.INK, HORIZONTAL_ALIGNMENT_RIGHT)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(value)

	if mode == GameConfig.Mode.CONTINUOUS:
		var best_distance := UiKit.label(
			"PERSONAL BEST DISTANCE  %d m" % int(SaveManager.best_distance_continuous), 22, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER
		)
		box.add_child(best_distance)
	if is_new_best:
		var badge := UiKit.label("NEW PERSONAL RECORD!", 26, UiKit.GREEN, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(badge)

	box.add_child(UiKit.spacer(10))
	var retry := UiKit.button("RETRY", true)
	var menu := UiKit.button("MAIN MENU")
	for button in [retry, menu]:
		button.custom_minimum_size = Vector2(760, 62)
		box.add_child(button)
	retry.pressed.connect(func() -> void: retry_requested.emit())
	menu.pressed.connect(func() -> void: main_menu_requested.emit())
	retry.grab_focus.call_deferred()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.03, 0.06, 0.82))
	if bool(results.get("victory", false)):
		for piece in _confetti:
			draw_rect(
				Rect2(float(piece["x"]), float(piece["y"]), float(piece["size"]), float(piece["size"]) * 0.6),
				piece["color"]
			)

## Main Menu (GDD Section II - Screen Flow): Standard Run, Continuous Mode,
## Training, Options, How to Play, Quit.
class_name MainMenu
extends Control

signal mode_selected(mode: int)
signal options_requested
signal help_requested
signal quit_requested

var _time: float = 0.0
var _title: Label
var _buttons: VBoxContainer
var _first_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_build_ui()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _title != null:
		_title.position.y = 118.0 + sin(_time * 2.0) * 6.0


func _build_ui() -> void:
	_title = UiKit.title("SCHOOL RUSH", 112, UiKit.GOLD)
	_title.position = Vector2(150, 118)
	_title.size = Vector2(900, 140)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_title)

	var tagline := UiKit.label("LATE AGAIN. RUN.", 34, UiKit.CYAN)
	tagline.position = Vector2(156, 252)
	add_child(tagline)

	var studio := UiKit.label("ARE STUDIO  -  v1.4", 22, UiKit.MUTED)
	studio.position = Vector2(156, 300)
	add_child(studio)

	var records := UiKit.panel_container(UiKit.panel_style(Color(0.05, 0.06, 0.11, 0.82), Color(1, 1, 1, 0.12)))
	records.position = Vector2(150, 372)
	records.size = Vector2(560, 190)
	add_child(records)
	var records_box := VBoxContainer.new()
	records_box.add_theme_constant_override("separation", 10)
	records.add_child(records_box)
	records_box.add_child(UiKit.label("PERSONAL RECORDS", 22, UiKit.MUTED))
	records_box.add_child(UiKit.hsep(1, Color(1, 1, 1, 0.12)))
	var standard_best := UiKit.label(
		"STANDARD RUN      %s" % GameConfig.format_score(SaveManager.best_score_standard), 26, UiKit.INK
	)
	var continuous_best := UiKit.label(
		"CONTINUOUS MODE   %s" % GameConfig.format_score(SaveManager.best_score_continuous), 26, UiKit.INK
	)
	records_box.add_child(standard_best)
	records_box.add_child(continuous_best)
	var hint := UiKit.label("W / S lanes   SPACE jump   CTRL slide   SHIFT dash", 20, UiKit.MUTED)
	hint.position = Vector2(156, 592)
	add_child(hint)

	_buttons = VBoxContainer.new()
	_buttons.position = Vector2(1120, 300)
	_buttons.size = Vector2(620, 520)
	_buttons.add_theme_constant_override("separation", 16)
	add_child(_buttons)

	var standard := UiKit.button("STANDARD RUN", true)
	var continuous := UiKit.button("CONTINUOUS MODE")
	var training := UiKit.button("TRAINING")
	var options := UiKit.button("OPTIONS")
	var help := UiKit.button("HOW TO PLAY")
	var quit := UiKit.button("QUIT")
	for button in [standard, continuous, training, options, help, quit]:
		button.custom_minimum_size = Vector2(620, 64)
		_buttons.add_child(button)
	standard.pressed.connect(func() -> void: mode_selected.emit(GameConfig.Mode.STANDARD))
	continuous.pressed.connect(func() -> void: mode_selected.emit(GameConfig.Mode.CONTINUOUS))
	training.pressed.connect(func() -> void: mode_selected.emit(GameConfig.Mode.TRAINING))
	options.pressed.connect(func() -> void: options_requested.emit())
	help.pressed.connect(func() -> void: help_requested.emit())
	quit.pressed.connect(func() -> void: quit_requested.emit())
	_first_button = standard
	standard.grab_focus.call_deferred()

	var mode_note := UiKit.label(
		"Standard = fixed route to the classroom.  Continuous = no finish line, rising speed.",
		20, UiKit.MUTED
	)
	mode_note.position = Vector2(1120, 850)
	mode_note.size = Vector2(640, 60)
	mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(mode_note)


func focus_first() -> void:
	if _first_button != null:
		_first_button.grab_focus()


func _draw() -> void:
	# Sky.
	var top := Color("#1b2a4a")
	var bottom := Color("#ff9a6b")
	for i in 16:
		var t := float(i) / 15.0
		draw_rect(Rect2(0, t * 660.0, 1920, 660.0 / 15.0 + 2), top.lerp(bottom, t))
	# Sun.
	draw_circle(Vector2(1460, 520), 170.0, Color(1, 0.78, 0.42, 0.22))
	draw_circle(Vector2(1460, 520), 120.0, Color("#ffd166"))
	for i in 7:
		var y := 500.0 + float(i) * 5.0
		draw_rect(Rect2(1350, y, 220, 2), Color("#ffb84d"))
	# Clouds.
	for i in 3:
		var x := fposmod(_time * (12.0 + i * 6.0) + float(i) * 620.0, 2200.0) - 200.0
		_draw_cloud(Vector2(x, 150.0 + float(i) * 80.0), 1.0 - i * 0.18)
	# Distant school.
	_draw_school(Vector2(1210, 720))
	# Houses.
	var scroll := fposmod(_time * 26.0, 620.0)
	for i in 4:
		_draw_house(Vector2(scroll + float(i) * 620.0 - 340.0, 760), 0.85)
	# Road + sidewalk.
	draw_rect(Rect2(0, 760, 1920, 130), Color("#c9d1dc"))
	draw_rect(Rect2(0, 890, 1920, 190), Color("#2f3646"))
	draw_rect(Rect2(0, 890, 1920, 8), Color("#8b95a6"))
	var dash := fposmod(_time * 220.0, 240.0)
	for i in 10:
		draw_rect(Rect2(dash + float(i) * 240.0 - 240.0, 980, 110, 10), Color("#ffd166"))
	# Fence + runner on the sidewalk.
	for i in 30:
		draw_rect(Rect2(float(i) * 68.0, 690, 8, 72), Color(1, 1, 1, 0.25))
	draw_rect(Rect2(0, 690, 1920, 8), Color(1, 1, 1, 0.3))
	_draw_runner(Vector2(760, 760))
	# Dark gradient behind the buttons for readability.
	draw_rect(Rect2(1040, 0, 880, 1080), Color(0.03, 0.04, 0.08, 0.55))
	draw_rect(Rect2(0, 0, 760, 1080), Color(0.03, 0.04, 0.08, 0.28))


func _draw_cloud(pos: Vector2, scale: float) -> void:
	var color := Color(1, 1, 1, 0.22)
	draw_circle(pos, 44.0 * scale, color)
	draw_circle(pos + Vector2(48, 8) * scale, 34.0 * scale, color)
	draw_circle(pos + Vector2(-46, 10) * scale, 30.0 * scale, color)
	draw_rect(Rect2(pos.x - 46 * scale, pos.y + 4 * scale, 96 * scale, 26 * scale), color)


func _draw_school(base: Vector2) -> void:
	draw_rect(Rect2(base.x - 330, base.y - 300, 660, 300), Color("#5b6b8c"))
	draw_rect(Rect2(base.x - 330, base.y - 300, 660, 20), Color("#7d90b3"))
	draw_rect(Rect2(base.x - 110, base.y - 420, 220, 140), Color("#6d7fa3"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(base.x - 140, base.y - 420), Vector2(base.x, base.y - 500), Vector2(base.x + 140, base.y - 420),
		]),
		Color("#8b3a34")
	)
	draw_circle(Vector2(base.x, base.y - 366), 34.0, Color("#f6f8ff"))
	draw_line(Vector2(base.x, base.y - 366), Vector2(base.x + 18, base.y - 384), Color("#171325"), 4.0)
	draw_rect(Rect2(base.x - 60, base.y - 150, 120, 150), Color("#3a2f22"))
	draw_rect(Rect2(base.x - 58, base.y - 148, 116, 146), Color("#7a5233"))
	for i in 4:
		var x := base.x - 290 + float(i) * 150.0
		draw_rect(Rect2(x, base.y - 240, 90, 80), Color("#bfe9ff"))
		draw_rect(Rect2(x, base.y - 240, 90, 80), Color(1, 1, 1, 0.2))
	draw_rect(Rect2(base.x - 210, base.y - 110, 60, 110), Color("#2f6fd0"))


func _draw_house(base: Vector2, scale: float) -> void:
	var width := 320.0 * scale
	var height := 250.0 * scale
	draw_rect(Rect2(base.x, base.y - height, width, height), Color("#3b4360"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(base.x - 20, base.y - height),
			Vector2(base.x + width * 0.5, base.y - height - 100 * scale),
			Vector2(base.x + width + 20, base.y - height),
		]),
		Color("#4d577a")
	)
	draw_rect(Rect2(base.x + 40, base.y - height + 60, 54, 52), Color(1, 0.9, 0.6, 0.55))
	draw_rect(Rect2(base.x + 150, base.y - height + 60, 54, 52), Color(1, 0.9, 0.6, 0.35))
	draw_rect(Rect2(base.x + 110, base.y - 90, 56, 90), Color("#2a2f45"))


func _draw_runner(pos: Vector2) -> void:
	var run := _time * 9.0
	var bob := sin(run * 2.0) * 4.0
	var leg := sin(run) * 22.0
	var y := pos.y + bob
	# Shadow.
	draw_rect(Rect2(pos.x - 42, pos.y - 4, 92, 10), Color(0, 0, 0, 0.25))
	# Legs.
	draw_line(Vector2(pos.x, y - 70), Vector2(pos.x + leg, y), Color("#1d2740"), 14.0, true)
	draw_line(Vector2(pos.x, y - 70), Vector2(pos.x - leg, y), Color("#1d2740"), 14.0, true)
	draw_rect(Rect2(pos.x + leg - 10, y - 8, 26, 10), Color("#e8453c"))
	draw_rect(Rect2(pos.x - leg - 12, y - 8, 26, 10), Color("#e8453c"))
	# Torso + backpack.
	draw_rect(Rect2(pos.x - 24, y - 132, 48, 66), Color("#f6f8ff"))
	draw_rect(Rect2(pos.x - 24, y - 132, 14, 54), Color("#2f6fd0"))
	draw_rect(Rect2(pos.x + 8, y - 132, 16, 54), Color("#2f6fd0"))
	draw_rect(Rect2(pos.x - 40, y - 128, 20, 44), Color("#f0b429"))
	# Arms.
	draw_line(Vector2(pos.x - 18, y - 122), Vector2(pos.x - 34 - leg * 0.4, y - 86), Color("#2f6fd0"), 10.0, true)
	draw_line(Vector2(pos.x + 18, y - 122), Vector2(pos.x + 34 + leg * 0.4, y - 86), Color("#2f6fd0"), 10.0, true)
	# Head.
	draw_circle(Vector2(pos.x + 6, y - 160), 26.0, Color("#171325"))
	draw_circle(Vector2(pos.x + 6, y - 160), 22.0, Color("#ffcda3"))
	draw_rect(Rect2(pos.x - 16, y - 186, 44, 14), Color("#37241a"))
	draw_rect(Rect2(pos.x + 14, y - 162, 5, 7), Color("#171325"))

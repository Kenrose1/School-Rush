## Controls Help (GDD Section V - Help System). Reachable from the main menu
## and the pause menu; no mandatory tutorial level.
class_name HelpPanel
extends Control

signal closed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		closed.emit()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var panel := UiKit.panel_container()
	panel.position = Vector2(330, 90)
	panel.size = Vector2(1260, 900)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(UiKit.label("HOW TO PLAY", UiKit.FONT_HEADING, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.hsep())

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 42)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	left.add_child(UiKit.label("CONTROLS", 26, UiKit.CYAN))
	left.add_child(UiKit.label("W / UP ARROW      move up a lane", 24))
	left.add_child(UiKit.label("S / DOWN ARROW    move down a lane", 24))
	left.add_child(UiKit.label("SPACEBAR          jump", 24))
	left.add_child(UiKit.label("LEFT CTRL         slide", 24))
	left.add_child(UiKit.label("LEFT SHIFT        dash (1.5s shield, 8s cooldown)", 24))
	left.add_child(UiKit.label("ESC               pause", 24))
	left.add_child(UiKit.spacer(18))
	left.add_child(UiKit.label("THE RUN", 26, UiKit.CYAN))
	left.add_child(_body("Elias runs forward automatically. Switch lanes, jump low hazards and slide under overhead ones. Reaching the classroom wins Standard Run."))
	left.add_child(UiKit.spacer(10))
	left.add_child(UiKit.label("MODES", 26, UiKit.CYAN))
	left.add_child(_body("Standard Run: Home > Street > Hallway, then the classroom. Continuous Mode: the three zones loop with speed rising over time. Training: a short, forgiving Home Area run."))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	right.add_child(UiKit.label("HEALTH", 26, UiKit.CYAN))
	right.add_child(_body("You have 3 hearts. Each damaging hit costs one heart and grants 1.5 seconds of invulnerability. The player hitbox is 10% smaller than the sprite so near misses are fair."))
	right.add_child(UiKit.spacer(10))
	right.add_child(UiKit.label("THE PURSUER", 26, UiKit.CYAN))
	right.add_child(_body("A hit summons the Pursuer behind you. It fades as soon as you recover full speed. If it is still on screen when you are hit again, it lunges: instant Game Over, no matter how many hearts you have left."))
	right.add_child(UiKit.spacer(10))
	right.add_child(UiKit.label("SCHOOL ITEMS & COMBO", 26, UiKit.CYAN))
	right.add_child(_body("Each school item is worth 100 points times your combo. Every 5 items raises the multiplier, up to 5x. A damaging collision resets it to 1x."))
	right.add_child(UiKit.spacer(10))
	right.add_child(UiKit.label("SCORING", 26, UiKit.CYAN))
	right.add_child(_body("Score comes from school items only. Continuous Mode rewards survival: the longer you run, the faster it gets. Records are saved automatically."))

	box.add_child(UiKit.hsep())
	var back := UiKit.button("BACK", true)
	box.add_child(back)
	back.pressed.connect(func() -> void: closed.emit())
	back.grab_focus.call_deferred()


func _body(text: String) -> Label:
	var node := UiKit.label(text, 21, UiKit.MUTED)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size = Vector2(0, 0)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.03, 0.06, 0.8))

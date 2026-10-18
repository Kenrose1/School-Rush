## Options Screen (GDD Section II - Options / Game Options).
class_name OptionsPanel
extends Control

signal closed

var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _back: Button


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
	panel.position = Vector2(560, 190)
	panel.size = Vector2(800, 700)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	box.add_child(UiKit.label("OPTIONS", UiKit.FONT_HEADING, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.hsep())

	box.add_child(UiKit.label("MUSIC VOLUME", 22, UiKit.MUTED))
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 18)
	box.add_child(music_row)
	_music_slider = HSlider.new()
	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.step = 0.05
	_music_slider.value = SaveManager.music_volume
	_music_slider.custom_minimum_size = Vector2(560, 40)
	_music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_row.add_child(_music_slider)
	_music_value = UiKit.label("%d%%" % int(SaveManager.music_volume * 100.0), 24, UiKit.INK)
	_music_value.custom_minimum_size = Vector2(90, 0)
	music_row.add_child(_music_value)
	_music_slider.value_changed.connect(_on_music_changed)

	box.add_child(UiKit.label("SOUND EFFECTS VOLUME", 22, UiKit.MUTED))
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 18)
	box.add_child(sfx_row)
	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.value = SaveManager.sfx_volume
	_sfx_slider.custom_minimum_size = Vector2(560, 40)
	_sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_row.add_child(_sfx_slider)
	_sfx_value = UiKit.label("%d%%" % int(SaveManager.sfx_volume * 100.0), 24, UiKit.INK)
	_sfx_value.custom_minimum_size = Vector2(90, 0)
	sfx_row.add_child(_sfx_value)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	box.add_child(UiKit.hsep())
	var shake := CheckBox.new()
	shake.text = "SCREEN SHAKE"
	shake.button_pressed = SaveManager.screen_shake
	shake.toggled.connect(func(on: bool) -> void: SaveManager.set_screen_shake(on))
	box.add_child(shake)

	var fullscreen := CheckBox.new()
	fullscreen.text = "FULLSCREEN"
	fullscreen.button_pressed = SaveManager.fullscreen
	fullscreen.toggled.connect(func(on: bool) -> void: SaveManager.set_fullscreen(on))
	box.add_child(fullscreen)

	box.add_child(UiKit.spacer(10))
	_back = UiKit.button("BACK", true)
	box.add_child(_back)
	_back.pressed.connect(func() -> void: closed.emit())
	_back.grab_focus.call_deferred()


func _on_music_changed(value: float) -> void:
	SaveManager.set_music_volume(value)
	_music_value.text = "%d%%" % int(value * 100.0)


func _on_sfx_changed(value: float) -> void:
	SaveManager.set_sfx_volume(value)
	_sfx_value.text = "%d%%" % int(value * 100.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.03, 0.06, 0.78))

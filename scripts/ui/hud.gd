## In-run HUD (GDD Section V - HUD / What controls).
## Drawn procedurally so it stays crisp at 1920x1080 and needs no image assets.
class_name Hud
extends Control

signal pause_button_pressed

const INK := Color("#f7f4ea")
const SHADOW := Color("#171325")
const PANEL := Color(0.06, 0.06, 0.11, 0.72)
const RED := Color("#ff4d4d")
const GOLD := Color("#ffd166")
const CYAN := Color("#7fe7ff")
const GREEN := Color("#7cf29c")

var mode: int = GameConfig.Mode.STANDARD
var target_distance: float = GameConfig.STANDARD_DISTANCE_M
var data: Dictionary = {}
var zone_name: String = "HOME AREA"
var zone_color: Color = Color("#ffcf5c")

var _countdown: float = 3.0
var _go_timer: float = 0.0
var _zone_badge_timer: float = 0.0
var _combo_timer: float = 0.0
var _damage_flash: float = 0.0
var _pursuer_warning: float = 0.0
var _tutorial_hint: String = ""
var _tutorial_timer: float = 0.0
var _popups: Array[Dictionary] = []
var _banner: String = ""
var _banner_sub: String = ""
var _banner_color: Color = GOLD
var _banner_timer: float = 0.0
var _time: float = 0.0
var _pause_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.position = Vector2(1798, 40)
	_pause_button.size = Vector2(72, 64)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.add_theme_font_size_override("font_size", 30)
	_pause_button.add_theme_color_override("font_color", INK)
	_pause_button.add_theme_color_override("font_hover_color", GOLD)
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL
	normal.border_color = Color(1, 1, 1, 0.25)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(10)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.14, 0.22, 0.9)
	hover.border_color = GOLD
	_pause_button.add_theme_stylebox_override("normal", normal)
	_pause_button.add_theme_stylebox_override("hover", hover)
	_pause_button.add_theme_stylebox_override("pressed", hover)
	_pause_button.pressed.connect(func() -> void: pause_button_pressed.emit())
	add_child(_pause_button)
	_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP


func setup_hud(run_mode: int, target: float) -> void:
	mode = run_mode
	target_distance = target
	_banner = ""
	_banner_timer = 0.0
	_popups.clear()
	_tutorial_hint = ""
	_tutorial_timer = 0.0
	_damage_flash = 0.0
	_pursuer_warning = 0.0
	_combo_timer = 0.0


func _process(delta: float) -> void:
	_time += delta
	_go_timer = maxf(0.0, _go_timer - delta)
	_zone_badge_timer = maxf(0.0, _zone_badge_timer - delta)
	_combo_timer = maxf(0.0, _combo_timer - delta)
	_damage_flash = maxf(0.0, _damage_flash - delta * 1.8)
	_tutorial_timer = maxf(0.0, _tutorial_timer - delta)
	_banner_timer = maxf(0.0, _banner_timer - delta)
	if _pursuer_warning > 0.0:
		_pursuer_warning = maxf(0.0, _pursuer_warning - delta)
	for i in range(_popups.size() - 1, -1, -1):
		var popup := _popups[i]
		popup["t"] = float(popup["t"]) + delta
		popup["pos"] = Vector2(popup["pos"]) + Vector2(0, -70.0 * delta)
		if float(popup["t"]) > 0.9:
			_popups.remove_at(i)
	queue_redraw()


# --- Called by RunWorld -----------------------------------------------------

func update_hud(run_data: Dictionary) -> void:
	data = run_data
	_pursuer_warning = maxf(_pursuer_warning, 0.0)


func set_countdown(value: float) -> void:
	_countdown = value


func show_go() -> void:
	_go_timer = 0.9


func set_zone_label(label: String, color: Color) -> void:
	zone_name = label
	zone_color = color


func show_zone_badge(label: String, color: Color) -> void:
	zone_name = label
	zone_color = color
	_zone_badge_timer = 2.4


func spawn_score_popup(world_position: Vector2, amount: int) -> void:
	var screen := get_viewport().get_canvas_transform() * world_position
	_popups.append({"pos": screen + Vector2(0, -40), "value": amount, "t": 0.0})


func show_combo_badge(combo: int) -> void:
	_combo_timer = 1.1
	data["combo"] = combo


func flash_damage() -> void:
	_damage_flash = 1.0


func show_pursuer_warning() -> void:
	_pursuer_warning = 4.0


func show_tutorial_hint(text: String) -> void:
	_tutorial_hint = text
	_tutorial_timer = 5.0


func show_victory_banner() -> void:
	_banner = "CLASSROOM REACHED!"
	_banner_sub = "You made it before the bell."
	_banner_color = GOLD
	_banner_timer = 1.7


func show_game_over_banner(reason: String) -> void:
	_banner = "GAME OVER"
	match reason:
		"caught":
			_banner_sub = "The Pursuer caught you."
		"hearts":
			_banner_sub = "You ran out of hearts."
		_:
			_banner_sub = "Run ended."
	_banner_color = RED
	_banner_timer = 1.7


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_top_left(font)
	_draw_top_center(font)
	_draw_bottom_left(font)
	_draw_bottom_right(font)
	_draw_countdown(font)
	_draw_zone_badge(font)
	_draw_pursuer_warning(font)
	_draw_tutorial(font)
	_draw_popups(font)
	_draw_banner(font)
	_draw_damage_overlay()


func _draw_top_left(font: Font) -> void:
	var score := int(data.get("score", 0))
	_label(font, Vector2(60, 74), "SCORE", 26, Color(1, 1, 1, 0.65))
	_text(font, Vector2(58, 146), GameConfig.format_score(score), 62, INK)
	# School items + combo.
	var items := int(data.get("items", 0))
	var combo := int(data.get("combo", 1))
	_draw_item_icon(Vector2(78, 196))
	_text(font, Vector2(112, 214), "x%d" % items, 36, INK)
	if combo > 1:
		var pop := 1.0 + maxf(0.0, _combo_timer) * 0.12
		var badge_rect := Rect2(232, 176, 122, 50)
		draw_rect(badge_rect.grow(3), SHADOW)
		draw_rect(badge_rect, GOLD)
		_text_centered(font, badge_rect, "COMBO x%d" % combo, 26, SHADOW)
		draw_circle(Vector2(232, 176), 10.0 * pop, Color(1, 1, 1, 0.3))
	_draw_hearts(Vector2(60, 250))


func _draw_hearts(origin: Vector2) -> void:
	var hearts := int(data.get("hearts", GameConfig.MAX_HEARTS))
	for i in GameConfig.MAX_HEARTS:
		var pos := origin + Vector2(float(i) * 54.0, 0)
		var filled := i < hearts
		_draw_heart(pos, 24.0, RED if filled else Color(0.25, 0.25, 0.32, 0.9))
		if filled:
			_draw_heart(pos + Vector2(-4, -4), 10.0, Color(1, 1, 1, 0.35))
	if hearts == 1:
		var pulse := 0.5 + 0.5 * sin(_time * 8.0)
		draw_arc(origin + Vector2(48, -8), 62.0, 0.0, TAU, 30, Color(1, 0.2, 0.2, 0.35 * pulse), 4.0)


func _draw_heart(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, size * 0.85),
		center + Vector2(-size, -size * 0.15),
		center + Vector2(-size * 0.75, -size * 0.75),
		center + Vector2(0, -size * 0.35),
		center + Vector2(size * 0.75, -size * 0.75),
		center + Vector2(size, -size * 0.15),
	])
	draw_colored_polygon(points, color)


func _draw_top_center(font: Font) -> void:
	if mode == GameConfig.Mode.CONTINUOUS:
		_text_centered_box(font, Rect2(660, 46, 600, 40), "CONTINUOUS - SURVIVE", 28, Color(1, 1, 1, 0.75))
	else:
		var progress := clampf(float(data.get("distance", 0.0)) / maxf(target_distance, 1.0), 0.0, 1.0)
		var bar := Rect2(560, 74, 800, 18)
		draw_rect(bar.grow(4), SHADOW)
		draw_rect(bar, Color(1, 1, 1, 0.16))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), zone_color)
		# Zone ticks.
		for i in range(1, 3):
			var x := bar.position.x + bar.size.x * (float(i) / 3.0)
			draw_rect(Rect2(x - 2, bar.position.y - 4, 4, bar.size.y + 8), Color(1, 1, 1, 0.5))
		# Runner marker.
		var marker := Vector2(bar.position.x + bar.size.x * progress, bar.position.y + bar.size.y * 0.5)
		draw_circle(marker, 16.0, SHADOW)
		draw_circle(marker, 12.0, INK)
		_text(font, Vector2(560, 48), "TO CLASSROOM", 22, Color(1, 1, 1, 0.7))
		_text_centered_box(
			font, Rect2(1360, 44, 200, 44),
			"%d / %d m" % [int(data.get("distance", 0.0)), int(target_distance)], 24, INK
		)
	# Zone name.
	_text_centered_box(font, Rect2(660, 120, 600, 44), zone_name, 28, zone_color)


func _draw_bottom_left(font: Font) -> void:
	var speed := float(data.get("speed", 0.0))
	var ratio := clampf(speed / GameConfig.SPEED_MAX, 0.0, 1.0)
	var bar := Rect2(60, 930, 420, 22)
	draw_rect(bar.grow(4), SHADOW)
	draw_rect(bar, Color(1, 1, 1, 0.16))
	var fill := Color("#7cf29c").lerp(Color("#ffd166"), ratio).lerp(Color("#ff5a4f"), maxf(0.0, ratio - 0.75) * 2.2)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), fill)
	for i in 5:
		var x := bar.position.x + bar.size.x * (float(i) / 5.0)
		draw_rect(Rect2(x, bar.position.y - 4, 3, bar.size.y + 8), Color(0, 0, 0, 0.35))
	_text(font, Vector2(60, 908), "SPEED", 24, Color(1, 1, 1, 0.7))
	_text(font, Vector2(360, 908), "%d" % int(speed), 26, INK)
	# Dash meter.
	var dash_ratio := float(data.get("dash", 0.0))
	var dash_bar := Rect2(60, 992, 300, 12)
	draw_rect(dash_bar.grow(3), SHADOW)
	draw_rect(dash_bar, Color(1, 1, 1, 0.14))
	var dash_color := CYAN if dash_ratio >= 1.0 else Color(0.45, 0.5, 0.62)
	draw_rect(Rect2(dash_bar.position, Vector2(dash_bar.size.x * dash_ratio, dash_bar.size.y)), dash_color)
	_text(font, Vector2(60, 974), "DASH  SHIFT", 20, Color(1, 1, 1, 0.65))
	var cooling := float(data.get("dash_cooling", 0.0))
	if cooling > 0.0:
		_text(font, Vector2(376, 1006), "%.1fs" % cooling, 20, Color(1, 1, 1, 0.6))
	elif bool(data.get("invulnerable", false)):
		_text(font, Vector2(376, 1006), "SHIELD", 20, CYAN)


func _draw_bottom_right(font: Font) -> void:
	var time_text := GameConfig.format_time(float(data.get("time", 0.0)))
	_text_right(font, Vector2(1860, 1008), time_text, 34, INK)
	_text_right(font, Vector2(1860, 970), "TIME", 22, Color(1, 1, 1, 0.6))
	var best := SaveManager.best_score_for(mode)
	_text_right(font, Vector2(1860, 936), "BEST %s" % GameConfig.format_score(best), 22, Color(1, 1, 1, 0.55))


func _draw_countdown(font: Font) -> void:
	if _go_timer > 0.0:
		var scale := 1.0 + (0.9 - _go_timer) * 0.8
		var alpha := clampf(_go_timer / 0.9, 0.0, 1.0)
		_text_centered_box(font, Rect2(0, 380, 1920, 220), "GO!", int(150 * scale), Color(1, 1, 1, alpha))
		return
	if _countdown <= 0.0:
		return
	var number := ceili(_countdown)
	if number <= 0:
		return
	var frac := 1.0 - fposmod(_countdown, 1.0)
	var size := int(160.0 + frac * 60.0)
	_text_centered_box(font, Rect2(0, 360, 1920, 260), str(number), size, Color(1, 1, 1, clampf(1.0 - frac * 0.7, 0.2, 1.0)))
	_text_centered_box(font, Rect2(0, 600, 1920, 50), "GET READY", 32, Color(1, 1, 1, 0.7))


func _draw_zone_badge(font: Font) -> void:
	if _zone_badge_timer <= 0.0:
		return
	var alpha := clampf(_zone_badge_timer / 0.6, 0.0, 1.0)
	var rect := Rect2(560, 230, 800, 92)
	draw_rect(rect, Color(0.05, 0.05, 0.1, 0.72 * alpha))
	draw_rect(Rect2(rect.position.x, rect.position.y, 8, rect.size.y), Color(zone_color.r, zone_color.g, zone_color.b, alpha))
	_text_centered(font, rect, zone_name, 42, Color(1, 1, 1, alpha))


func _draw_pursuer_warning(font: Font) -> void:
	var active := bool(data.get("pursuer", false))
	if not active and _pursuer_warning <= 0.0:
		return
	var pulse := 0.55 + 0.45 * sin(_time * 9.0)
	var rect := Rect2(560, 186, 800, 54)
	draw_rect(rect, Color(0.5, 0.05, 0.05, 0.55 + 0.2 * pulse))
	draw_rect(Rect2(rect.position.x, rect.position.y, 8, rect.size.y), RED)
	_text_centered(font, rect, "PURSUER - ONE MORE HIT ENDS THE RUN", 24, Color(1, 1, 1, 0.95))


func _draw_tutorial(font: Font) -> void:
	if _tutorial_timer <= 0.0:
		return
	var alpha := clampf(_tutorial_timer / 0.5, 0.0, 1.0)
	var rect := Rect2(340, 790, 1240, 88)
	draw_rect(rect, Color(0.04, 0.05, 0.09, 0.85 * alpha))
	draw_rect(Rect2(rect.position.x, rect.position.y, 8, rect.size.y), CYAN)
	draw_multiline_string(
		font, rect.position + Vector2(28, 40), _tutorial_hint,
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 48, 28, 3, Color(1, 1, 1, alpha)
	)
	_text(font, Vector2(rect.position.x + 28, rect.position.y + 74), "TIP", 18, Color(CYAN.r, CYAN.g, CYAN.b, alpha))


func _draw_popups(font: Font) -> void:
	for popup in _popups:
		var t := float(popup["t"])
		var alpha := clampf(1.0 - t / 0.9, 0.0, 1.0)
		_text_centered_box(
			font, Rect2(Vector2(popup["pos"]) - Vector2(70, 24), Vector2(140, 40)),
			"+%d" % int(popup["value"]), 30, Color(GOLD.r, GOLD.g, GOLD.b, alpha)
		)


func _draw_banner(font: Font) -> void:
	if _banner_timer <= 0.0 or _banner == "":
		return
	var alpha := clampf(_banner_timer / 0.4, 0.0, 1.0)
	var rect := Rect2(360, 400, 1200, 190)
	draw_rect(rect, Color(0.04, 0.04, 0.09, 0.86 * alpha))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 8)), Color(_banner_color.r, _banner_color.g, _banner_color.b, alpha))
	_text_centered(font, Rect2(rect.position.x, rect.position.y + 18, rect.size.x, 100), _banner, 62, Color(1, 1, 1, alpha))
	_text_centered(font, Rect2(rect.position.x, rect.position.y + 120, rect.size.x, 50), _banner_sub, 30, Color(1, 1, 1, 0.8 * alpha))


func _draw_damage_overlay() -> void:
	if _damage_flash > 0.0:
		draw_rect(Rect2(0, 0, 1920, 1080), Color(1, 0.08, 0.08, 0.3 * _damage_flash))
		for i in 4:
			draw_rect(
				Rect2(0, 0, 1920, 1080).grow(-float(i) * 26.0),
				Color(1, 0.1, 0.1, 0.0), false, 12.0
			)


func _draw_item_icon(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 16, pos.y - 18, 32, 30), SHADOW)
	draw_rect(Rect2(pos.x - 13, pos.y - 15, 26, 24), Color("#ff922b"))
	draw_rect(Rect2(pos.x - 4, pos.y - 15, 8, 24), Color("#e8590c"))


# --- Text helpers -----------------------------------------------------------

func _text(font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, pos + Vector2(3, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, color.a * 0.65))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_right(font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(font, pos - Vector2(width, 0), text, size, color)


func _text_centered(font: Font, rect: Rect2, text: String, size: int, color: Color) -> void:
	draw_string(
		font, rect.position + Vector2(3, rect.size.y * 0.5 + size * 0.35 + 3),
		text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Color(0, 0, 0, color.a * 0.6)
	)
	draw_string(
		font, rect.position + Vector2(0, rect.size.y * 0.5 + size * 0.35),
		text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color
	)


func _text_centered_box(font: Font, rect: Rect2, text: String, size: int, color: Color) -> void:
	_text_centered(font, rect, text, size, color)


func _label(font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	_text(font, pos, text, size, color)

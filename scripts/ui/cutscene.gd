## Opening cutscene (GDD Section III - Cut scene #1): wake up > look at the
## clock > realize he is late > dash out of the door. Skippable.
class_name Cutscene
extends Node2D

signal finished

const DURATION := 8.2

var _time: float = 0.0
var _finished: bool = false
var _sfx_fired: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioDirector.stop_music(0.4)
	set_process(true)
	AudioDirector.play_sfx("click")


func _process(delta: float) -> void:
	_time += delta
	_queue_cues()
	queue_redraw()
	if _time >= DURATION:
		_finish()


func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_finish()


func _queue_cues() -> void:
	if _time > 1.5 and not _sfx_fired.has("alarm"):
		_sfx_fired["alarm"] = true
		AudioDirector.play_sfx("bell")
	if _time > 4.9 and not _sfx_fired.has("dash"):
		_sfx_fired["dash"] = true
		AudioDirector.play_sfx("dash")
	if _time > 6.6 and not _sfx_fired.has("bell"):
		_sfx_fired["bell"] = true
		AudioDirector.play_sfx("bell")


func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()


func _draw() -> void:
	var fade := 1.0
	if _time > 7.2:
		fade = clampf(1.0 - (_time - 7.2) / 0.9, 0.0, 1.0)
	var dim := Color(1, 1, 1, fade)
	# Room.
	draw_rect(Rect2(0, 0, 1920, 1080), Color("#2b3350") * dim)
	draw_rect(Rect2(0, 620, 1920, 460), Color("#7a5233") * dim)
	for i in 12:
		draw_rect(Rect2(float(i) * 180.0, 620, 4, 460), Color("#5f3f26") * dim)
	# Wall detail + window with morning light.
	draw_rect(Rect2(0, 0, 1920, 40), Color("#1f253c") * dim)
	var window := Rect2(1250, 150, 380, 300)
	draw_rect(window.grow(12), Color("#5f3f26") * dim)
	draw_rect(window, Color("#bfe9ff") * dim)
	draw_rect(window, Color(1, 0.95, 0.7, 0.45 * fade))
	draw_rect(Rect2(window.position.x + window.size.x * 0.5 - 5, window.position.y, 10, window.size.y), Color("#5f3f26") * dim)
	# Light shaft.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1250, 450), Vector2(1630, 450), Vector2(1100, 1080), Vector2(500, 1080),
		]),
		Color(1, 0.95, 0.7, 0.08 * fade)
	)
	# Bed.
	draw_rect(Rect2(400, 640, 620, 190), Color("#6b4a2c") * dim)
	draw_rect(Rect2(420, 610, 580, 120), Color("#f4f7ff") * dim)
	draw_rect(Rect2(420, 690, 580, 90), Color("#5d8fd6") * dim)
	draw_rect(Rect2(360, 520, 50, 320), Color("#5f3f26") * dim)
	draw_rect(Rect2(380, 560, 90, 70), Color("#f4f7ff") * dim)
	# Nightstand + alarm clock.
	draw_rect(Rect2(1080, 700, 150, 130), Color("#7a5233") * dim)
	_draw_clock(Vector2(1155, 700), dim)
	# Door.
	draw_rect(Rect2(1680, 330, 180, 500), Color("#5f3f26") * dim)
	draw_rect(Rect2(1692, 342, 156, 488), Color("#a9713f") * dim)
	draw_circle(Vector2(1700, 600), 8.0, Color("#ffd166") * dim)
	_draw_character(dim)
	# Captions.
	var caption := ""
	var caption_color := Color("#ffd166")
	if _time < 1.4:
		caption = "ZZZ..."
		caption_color = Color("#9fb3d9")
	elif _time < 2.3:
		caption = "RING! RING! RING!"
		caption_color = Color("#ff5a4f")
	elif _time < 3.4:
		caption = "8:45?!"
		caption_color = Color("#ff5a4f")
	elif _time < 4.8:
		caption = "I'M LATE!"
		caption_color = Color("#ffd166")
	elif _time < 6.4:
		caption = "GO GO GO!"
		caption_color = Color("#7cf29c")
	else:
		caption = "SCHOOL RUSH"
		caption_color = Color("#7fe7ff")
	_draw_text_centered(caption, Rect2(0, 880, 1920, 90), 64, Color(caption_color.r, caption_color.g, caption_color.b, fade))
	# Skip hint.
	var hint_alpha := clampf(1.0 - _time / 1.2, 0.0, 0.55) * fade
	_draw_text_centered("SPACE / ESC  SKIP", Rect2(0, 1010, 1920, 40), 22, Color(1, 1, 1, hint_alpha))
	# "!" alert bubble.
	if _time > 2.3 and _time < 4.8:
		var bounce := absf(sin(_time * 8.0)) * 14.0
		draw_circle(Vector2(880, 380 - bounce), 44.0, Color("#171325"))
		draw_circle(Vector2(880, 380 - bounce), 36.0, Color("#ff5a4f"))
		draw_rect(Rect2(872, 348 - bounce, 16, 36), Color("#fff5f2"))
		draw_circle(Vector2(880, 398 - bounce), 8.0, Color("#fff5f2"))


func _draw_clock(pos: Vector2, dim: Color) -> void:
	var shake := 0.0
	if _time > 1.4 and _time < 2.6:
		shake = sin(_time * 60.0) * 4.0
	var center := pos + Vector2(0, -34 + shake)
	draw_circle(center, 38.0, Color("#171325") * dim)
	draw_circle(center, 32.0, Color("#f6f8ff") * dim)
	draw_line(center, center + Vector2(-16, -18), Color("#171325") * dim, 4.0)
	draw_line(center, center + Vector2(18, -6), Color("#e8453c") * dim, 4.0)
	draw_circle(center, 4.0, Color("#171325") * dim)
	draw_rect(Rect2(center.x - 30, center.y + 34, 60, 12), Color("#171325") * dim)


func _draw_character(dim: Color) -> void:
	var t := _time
	var base := Vector2(760, 810)
	var sitting := t > 2.3
	var running := t > 4.8
	var alpha: float = dim.a
	if running:
		var run_progress := clampf((t - 4.8) / 1.8, 0.0, 1.0)
		base = Vector2(760.0 + run_progress * 900.0, 810.0)
		var bob := sin(t * 22.0) * 8.0
		base.y += bob
		# Motion lines.
		for i in 5:
			draw_rect(
				Rect2(base.x - 120.0 - float(i) * 60.0, base.y - 150.0 + float(i) * 26.0, 90, 5),
				Color(1, 1, 1, 0.22 * alpha)
			)
	if not sitting:
		# Sleeping: blanket + head on pillow.
		draw_rect(Rect2(500, 640, 330, 80), Color("#5d8fd6") * alpha)
		draw_circle(Vector2(470, 610), 44.0, Color("#171325") * alpha)
		draw_circle(Vector2(470, 610), 38.0, Color("#ffcda3") * alpha)
		draw_rect(Rect2(432, 570, 76, 26), Color("#37241a") * alpha)
		for i in 3:
			var zz := fposmod(t * 40.0 + float(i) * 26.0, 90.0)
			_draw_text_at("Z", Vector2(520 + zz * 0.8, 560 - zz), 26 + i * 6, Color(1, 1, 1, 0.7 * alpha))
		return
	# Sitting / running character.
	var leg_swing := sin(t * 22.0) * 30.0 if running else 0.0
	var hip := base + Vector2(0, -96)
	draw_line(hip, hip + Vector2(-14 + leg_swing, 96), Color("#1d2740") * alpha, 20.0, true)
	draw_line(hip, hip + Vector2(14 - leg_swing, 96), Color("#1d2740") * alpha, 20.0, true)
	draw_rect(Rect2(hip.x - 26, hip.y - 66, 52, 70), Color("#f6f8ff") * alpha)
	draw_rect(Rect2(hip.x - 26, hip.y - 66, 16, 56), Color("#2f6fd0") * alpha)
	draw_rect(Rect2(hip.x + 10, hip.y - 66, 16, 56), Color("#2f6fd0") * alpha)
	draw_rect(Rect2(hip.x - 46, hip.y - 62, 22, 46), Color("#f0b429") * alpha)
	draw_line(hip + Vector2(-20, -56), hip + Vector2(-40 - leg_swing * 0.6, -10), Color("#2f6fd0") * alpha, 12.0, true)
	draw_line(hip + Vector2(20, -56), hip + Vector2(40 + leg_swing * 0.6, -10), Color("#2f6fd0") * alpha, 12.0, true)
	draw_circle(hip + Vector2(0, -92), 30.0, Color("#171325") * alpha)
	draw_circle(hip + Vector2(0, -92), 26.0, Color("#ffcda3") * alpha)
	draw_rect(Rect2(hip.x - 26, hip.y - 124, 52, 16), Color("#37241a") * alpha)
	draw_rect(Rect2(hip.x + 8, hip.y - 94, 6, 8), Color("#171325") * alpha)
	draw_rect(Rect2(hip.x - 14, hip.y - 94, 6, 8), Color("#171325") * alpha)
	if _time > 3.4 and _time < 4.8:
		draw_rect(Rect2(hip.x - 14, hip.y - 82, 28, 5), Color("#171325") * alpha)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(4, rect.size.y * 0.5 + size * 0.35 + 4), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Color(0, 0, 0, color.a * 0.7))
	draw_string(font, rect.position + Vector2(0, rect.size.y * 0.5 + size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)


func _draw_text_at(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

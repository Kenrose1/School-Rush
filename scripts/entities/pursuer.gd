## The Pursuer Entity (Momentum Hazard).
## Dormant by default; spawns behind Elias on a hit, matches his baseline
## speed, then fades as momentum is recovered. A second hit while it is on
## screen triggers an instant lunge + Game Over (GDD Section VI).
class_name Pursuer
extends Node2D

enum State { DORMANT, ACTIVE, FADING, LUNGING }

signal despawned
signal caught_player

const EYE := Color("#ff3b30")
const BODY := Color("#221a33")
const BODY_LIGHT := Color("#372a4f")

var state: int = State.DORMANT
var opacity: float = 0.0
var fade_timer: float = GameConfig.PURSUER_FADE_TIME
var speed_ratio: float = 1.0
var _time: float = 0.0
var _bob: float = 0.0


func _ready() -> void:
	z_index = 8
	visible = false
	modulate.a = 0.0


func activate() -> void:
	state = State.ACTIVE
	fade_timer = GameConfig.PURSUER_FADE_TIME
	opacity = 1.0
	visible = true
	modulate.a = 1.0
	AudioDirector.play_sfx("pursuer")


func is_active() -> bool:
	return state == State.ACTIVE or state == State.FADING or state == State.LUNGING


func is_dormant() -> bool:
	return state == State.DORMANT


## ratio: 1.0 = full sprint speed, HIT_SPEED_MULT = slowed after a hit.
func update_state(delta: float, ratio: float) -> void:
	speed_ratio = ratio
	_time += delta
	_bob = sin(_time * 6.0) * 6.0
	if state == State.ACTIVE:
		if ratio >= GameConfig.PURSUER_RECOVERY_RATIO:
			fade_timer -= delta
			if fade_timer <= 0.0:
				state = State.FADING
				opacity = 0.0
				despawned.emit()
		else:
			fade_timer = GameConfig.PURSUER_FADE_TIME
			opacity = 1.0
	elif state == State.FADING:
		opacity = move_toward(opacity, 0.0, delta * 2.0)
		if opacity <= 0.0:
			state = State.DORMANT
			visible = false
	modulate.a = opacity
	if state == State.LUNGING:
		modulate.a = 1.0
	queue_redraw()


func lunge() -> void:
	if state == State.LUNGING:
		return
	state = State.LUNGING
	opacity = 1.0
	modulate.a = 1.0
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + 280.0, 0.22).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: caught_player.emit())


func deactivate() -> void:
	state = State.DORMANT
	opacity = 0.0
	modulate.a = 0.0
	visible = false


func _draw() -> void:
	if state == State.DORMANT:
		return
	var y := _bob
	# Smoke/cloth trail.
	for i in 4:
		var t := fmod(_time * 0.8 + i * 0.25, 1.0)
		draw_circle(Vector2(60 + t * 160.0, y - 60.0 - i * 18.0), 26.0 - i * 4.0, Color(0.16, 0.1, 0.26, 0.22 * (1.0 - t)))
	# Body: tall hooded silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-58, y), Vector2(58, y), Vector2(48, y - 96),
			Vector2(30, y - 148), Vector2(0, y - 172), Vector2(-30, y - 148),
			Vector2(-48, y - 96),
		]),
		BODY
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-34, y - 8), Vector2(34, y - 8), Vector2(24, y - 104), Vector2(0, y - 140), Vector2(-24, y - 104)]),
		BODY_LIGHT
	)
	# Hood.
	draw_circle(Vector2(0, y - 150), 34.0, BODY)
	draw_circle(Vector2(0, y - 150), 24.0, Color("#120d1d"))
	# Eyes.
	var flicker := 0.7 + 0.3 * sin(_time * 14.0)
	draw_circle(Vector2(-10, y - 154), 6.0, Color(EYE.r, EYE.g, EYE.b, flicker))
	draw_circle(Vector2(11, y - 154), 6.0, Color(EYE.r, EYE.g, EYE.b, flicker))
	draw_circle(Vector2(-10, y - 154), 2.0, Color("#fff0ee"))
	draw_circle(Vector2(11, y - 154), 2.0, Color("#fff0ee"))
	# Clawed arms reaching forward.
	draw_line(Vector2(-40, y - 92), Vector2(-78, y - 54), BODY, 12.0, true)
	draw_line(Vector2(40, y - 92), Vector2(78, y - 54), BODY, 12.0, true)
	# Warning bubble.
	var bounce := sin(_time * 9.0) * 5.0
	draw_circle(Vector2(54, y - 196.0 + bounce), 24.0, Color("#171325"))
	draw_circle(Vector2(54, y - 196.0 + bounce), 20.0, Color("#ff3b30"))
	draw_rect(Rect2(50, y - 208.0 + bounce, 8, 18), Color("#fff5f2"))
	draw_circle(Vector2(54, y - 184.0 + bounce), 4.0, Color("#fff5f2"))

## Elias - the playable student.
## Three-lane movement, jump, slide, dash, 3 hearts, 1.5s i-frames,
## hitbox 10% smaller than the sprite (GDD Section II / VI).
class_name Player
extends CharacterBody2D

signal lane_changed(lane: int)
signal jumped
signal slid
signal dashed
signal hit_taken(hearts_left: int)
signal defeated
signal item_picked(kind: String, world_position: Vector2)

const OUTLINE := Color("#171325")
const SKIN := Color("#ffcda3")
const SKIN_SHADE := Color("#e5a87b")
const HAIR := Color("#37241a")
const SHIRT := Color("#f6f8ff")
const VEST := Color("#2f6fd0")
const VEST_DARK := Color("#1f4a93")
const SHORTS := Color("#1d2740")
const SHOE := Color("#e8453c")
const SOCK := Color("#f6f8ff")
const BAG := Color("#f0b429")
const BAG_DARK := Color("#c98a12")

@export var lane: int = 1
@export var max_hearts: int = GameConfig.MAX_HEARTS

var hearts: int = GameConfig.MAX_HEARTS
var invuln_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var slide_timer: float = 0.0
var jump_height: float = 0.0
var jump_speed: float = 0.0
var airborne: bool = false
var sliding: bool = false
var defeated_state: bool = false
var input_enabled: bool = true
var can_control: bool = true
var speed_ref: float = 430.0

var _run_phase: float = 0.0
var _bob: float = 0.0
var _hurt_flash: float = 0.0
var _lane_tween: Tween
var _shape: RectangleShape2D
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	_hitbox = $Hitbox
	_hitbox_shape = $Hitbox/CollisionShape2D
	_shape = RectangleShape2D.new()
	_shape.size = GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	_hitbox_shape.shape = _shape
	_hitbox.collision_layer = 1
	_hitbox.collision_mask = 2 | 4
	_hitbox.monitoring = true
	_hitbox.monitorable = true
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	position.y = GameConfig.lane_y(lane)
	hitbox_updated()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_update_jump(delta)
	_update_slide(delta)
	_run_phase += delta * (speed_ref / 92.0)
	_bob = sin(_run_phase * 2.0) * 3.0 if not airborne else 0.0
	if _hurt_flash > 0.0:
		_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if invuln_timer > 0.0 and not defeated_state:
		modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		modulate.a = 1.0
	position.x = GameConfig.PLAYER_X
	hitbox_updated()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not can_control or defeated_state:
		return
	if get_tree().paused:
		return
	if event.is_action_pressed("lane_up"):
		move_lane(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("lane_down"):
		move_lane(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		try_jump()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("slide"):
		try_slide()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dash"):
		try_dash()
		get_viewport().set_input_as_handled()


# --- Movement ---------------------------------------------------------------

func move_lane(direction: int) -> bool:
	if not can_control or defeated_state:
		return false
	var next_lane: int = GameConfig.clamp_lane(lane + direction)
	if next_lane == lane:
		return false
	lane = next_lane
	if _lane_tween != null and _lane_tween.is_valid():
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(self, "position:y", GameConfig.lane_y(lane), GameConfig.LANE_SWITCH_TIME)
	lane_changed.emit(lane)
	AudioDirector.play_sfx("lane")
	hitbox_updated()
	return true


func try_jump() -> bool:
	if not can_control or defeated_state or airborne or sliding:
		return false
	airborne = true
	jump_speed = GameConfig.JUMP_VELOCITY
	jump_height = 1.0
	jumped.emit()
	AudioDirector.play_sfx("jump")
	hitbox_updated()
	return true


func try_slide() -> bool:
	if not can_control or defeated_state or airborne:
		return false
	if sliding:
		return false
	sliding = true
	slide_timer = GameConfig.SLIDE_TIME
	slid.emit()
	AudioDirector.play_sfx("slide")
	hitbox_updated()
	return true


func try_dash() -> bool:
	if not can_control or defeated_state:
		return false
	if dash_cooldown > 0.0 or dash_timer > 0.0:
		return false
	dash_timer = GameConfig.DASH_TIME
	dash_cooldown = GameConfig.DASH_COOLDOWN
	invuln_timer = maxf(invuln_timer, GameConfig.DASH_TIME)
	dashed.emit()
	AudioDirector.play_sfx("dash")
	return true


func is_invulnerable() -> bool:
	return invuln_timer > 0.0 or dash_timer > 0.0 or defeated_state


func is_dashing() -> bool:
	return dash_timer > 0.0


func get_dash_ratio() -> float:
	if dash_timer > 0.0:
		return 1.0
	return 1.0 - clampf(dash_cooldown / GameConfig.DASH_COOLDOWN, 0.0, 1.0)


# --- Damage -----------------------------------------------------------------

## Applies one damaging collision. Returns true when the hit landed.
func take_hit() -> bool:
	if defeated_state or is_invulnerable():
		return false
	hearts = maxi(0, hearts - 1)
	invuln_timer = GameConfig.INVULN_TIME
	_hurt_flash = 0.3
	sliding = false
	slide_timer = 0.0
	if hearts <= 0:
		defeated_state = true
		defeated.emit()
	else:
		hit_taken.emit(hearts)
	AudioDirector.play_sfx("hurt")
	hitbox_updated()
	return true


func reset_for_run() -> void:
	hearts = max_hearts
	invuln_timer = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	slide_timer = 0.0
	jump_height = 0.0
	jump_speed = 0.0
	airborne = false
	sliding = false
	defeated_state = false
	lane = 1
	position.y = GameConfig.lane_y(lane)
	modulate.a = 1.0
	hitbox_updated()
	queue_redraw()


# --- Collisions -------------------------------------------------------------

func hitbox_updated() -> void:
	if _hitbox == null:
		return
	var size := GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	# The Area2D stays at the feet; the CollisionShape2D carries the offset so
	# the effective hitbox is exactly one body tall (or one crouched body).
	_hitbox.position = Vector2.ZERO
	if sliding:
		size.y *= 0.45
		_hitbox_shape.position = Vector2(0.0, -24.0 - jump_height)
	else:
		_hitbox_shape.position = Vector2(0.0, -52.0 - jump_height)
	_shape.size = size


func get_hitbox_rect() -> Rect2:
	var size := _shape.size if _shape != null else GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	var center := global_position + _hitbox_shape.position
	return Rect2(center - size * 0.5, size)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if not area.has_method("is_hazard") and not area.has_method("is_collectible"):
		return
	if area.has_method("is_collectible") and area.is_collectible():
		item_picked.emit(area.kind, area.global_position)
		area.collect()
		return
	if area.has_method("is_hazard") and area.is_hazard():
		if take_hit():
			area.on_player_hit()


func _tick_timers(delta: float) -> void:
	invuln_timer = maxf(0.0, invuln_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)


func _update_jump(delta: float) -> void:
	if not airborne:
		return
	jump_height += jump_speed * delta
	jump_speed -= GameConfig.GRAVITY * delta
	if jump_height <= 0.0 and jump_speed < 0.0:
		jump_height = 0.0
		jump_speed = 0.0
		airborne = false


func _update_slide(delta: float) -> void:
	if not sliding:
		return
	slide_timer -= delta
	if slide_timer <= 0.0:
		sliding = false
		slide_timer = 0.0


# --- Drawing (procedural 16-bit style sprite) -------------------------------

func _draw() -> void:
	var y := -jump_height + _bob
	var flicker := _hurt_flash > 0.0
	var tint := Color(1, 0.45, 0.45) if flicker else Color.WHITE

	# Ground shadow (stays on the lane).
	var shadow_alpha := clampf(1.0 - jump_height / 220.0, 0.15, 0.55)
	draw_circle(Vector2(0, 4), 34.0, Color(0.05, 0.04, 0.1, shadow_alpha * 0.6))
	draw_rect(Rect2(-34, 0, 68, 10), Color(0.05, 0.04, 0.1, shadow_alpha * 0.5))

	if sliding:
		_draw_slide(y)
	else:
		_draw_standing(y, tint)

	if is_dashing():
		_draw_dash_streaks(y)
	if invuln_timer > 0.0 and not is_dashing():
		draw_arc(Vector2(0, y - 58), 62.0, 0.0, TAU, 28, Color(0.75, 0.95, 1.0, 0.55), 4.0)


func _draw_standing(y: float, tint: Color) -> void:
	var phase := _run_phase
	var hip := Vector2(0, y - 46)
	var leg_swing := sin(phase)
	var leg_lift := 0.0 if airborne else absf(cos(phase)) * 5.0

	# Backpack (behind the body).
	_rect(Rect2(-32, y - 88, 22, 42), BAG_DARK)
	_rect(Rect2(-30, y - 86, 18, 38), BAG)

	# Back leg.
	var back_foot := hip + Vector2(-8.0 + leg_swing * 20.0, 40.0 - leg_lift)
	if airborne:
		back_foot = hip + Vector2(-14, 30)
	_limb(hip + Vector2(-6, 0), back_foot, SHORTS.darkened(0.25), 18.0, 11.0)
	_rect(Rect2(back_foot.x - 11, back_foot.y - 4, 24, 12), OUTLINE)
	_rect(Rect2(back_foot.x - 9, back_foot.y - 3, 20, 8), SHOE.darkened(0.2))

	# Torso.
	_rect(Rect2(-21, y - 84, 42, 42), OUTLINE)
	_rect(Rect2(-18, y - 82, 36, 38), SHIRT)
	# Vest / uniform.
	_rect(Rect2(-18, y - 82, 12, 30), VEST)
	_rect(Rect2(6, y - 82, 12, 30), VEST)
	_rect(Rect2(-18, y - 82, 36, 5), VEST_DARK)
	# Tie.
	_rect(Rect2(-3, y - 78, 6, 16), SHOE)
	# Backpack straps.
	_rect(Rect2(-16, y - 82, 5, 34), BAG_DARK)
	_rect(Rect2(11, y - 82, 5, 34), BAG_DARK)

	# Front leg.
	var front_foot := hip + Vector2(8.0 - leg_swing * 22.0, 40.0 - maxf(0.0, -sin(phase)) * 6.0)
	if airborne:
		front_foot = hip + Vector2(16, 16)
	_limb(hip + Vector2(5, 0), front_foot, SHORTS, 18.0, 11.0)
	_rect(Rect2(front_foot.x - 11, front_foot.y - 4, 24, 12), OUTLINE)
	_rect(Rect2(front_foot.x - 9, front_foot.y - 3, 20, 8), SHOE)
	_rect(Rect2(front_foot.x - 9, front_foot.y + 4, 20, 3), Color("#f4f4f4"))

	# Arms.
	var arm_swing := -sin(phase) * 14.0
	var shoulder := Vector2(0, y - 74)
	if airborne:
		_limb(shoulder + Vector2(-14, 10), shoulder + Vector2(-30, -8), VEST_DARK, 14.0, 8.0)
		_limb(shoulder + Vector2(14, 10), shoulder + Vector2(30, -8), VEST, 14.0, 8.0)
	else:
		_limb(shoulder + Vector2(-16, 6), shoulder + Vector2(-20, 30 + arm_swing), VEST_DARK, 14.0, 8.0)
		draw_circle(shoulder + Vector2(-20, 30 + arm_swing), 5.0, SKIN_SHADE)
		_limb(shoulder + Vector2(16, 6), shoulder + Vector2(20, 30 - arm_swing), VEST, 14.0, 8.0)
		draw_circle(shoulder + Vector2(20, 30 - arm_swing), 5.0, SKIN)

	# Head.
	var head := Vector2(0, y - 100)
	draw_circle(head, 22.0, OUTLINE)
	draw_circle(head, 19.0, SKIN)
	# Hair.
	draw_rect(Rect2(head.x - 20, head.y - 24, 40, 16), OUTLINE)
	draw_rect(Rect2(head.x - 18, head.y - 23, 36, 11), HAIR)
	draw_rect(Rect2(head.x - 22, head.y - 12, 10, 12), HAIR)
	# Face.
	draw_rect(Rect2(head.x + 3, head.y - 4, 4, 6), OUTLINE)
	draw_rect(Rect2(head.x + 12, head.y - 4, 4, 6), OUTLINE)
	draw_rect(Rect2(head.x + 6, head.y + 10, 10, 3), OUTLINE)
	if _hurt_flash > 0.0:
		draw_rect(Rect2(head.x - 18, head.y - 10, 36, 18), Color(1, 0.3, 0.3, 0.35))
	# Ear.
	draw_circle(Vector2(head.x - 18, head.y + 2), 5.0, SKIN_SHADE)


func _draw_slide(y: float) -> void:
	var base := Vector2(0, y - 30)
	# Legs extended forward.
	_rect(Rect2(base.x - 46, base.y + 8, 58, 16), OUTLINE)
	_rect(Rect2(base.x - 44, base.y + 10, 54, 11), SHORTS)
	_rect(Rect2(base.x + 10, base.y + 6, 26, 18), OUTLINE)
	_rect(Rect2(base.x + 12, base.y + 8, 23, 13), SHOE)
	# Low torso.
	_rect(Rect2(base.x - 34, base.y - 34, 62, 38), OUTLINE)
	_rect(Rect2(base.x - 31, base.y - 31, 56, 32), SHIRT)
	_rect(Rect2(base.x - 31, base.y - 31, 16, 24), VEST)
	_rect(Rect2(base.x + 12, base.y - 31, 14, 24), VEST)
	_rect(Rect2(base.x + 6, base.y - 34, 24, 8), BAG)
	# Head tucked.
	var head := Vector2(base.x + 26, base.y - 46)
	draw_circle(head, 20.0, OUTLINE)
	draw_circle(head, 17.0, SKIN)
	draw_rect(Rect2(head.x - 18, head.y - 20, 36, 12), OUTLINE)
	draw_rect(Rect2(head.x - 16, head.y - 19, 32, 8), HAIR)
	draw_rect(Rect2(head.x + 2, head.y - 2, 4, 5), OUTLINE)
	# Dust puffs.
	var puff := fmod(Time.get_ticks_msec() * 0.08, 26.0)
	draw_circle(Vector2(base.x - 52 - puff, base.y + 16), 8.0, Color(0.85, 0.85, 0.9, 0.4))
	draw_circle(Vector2(base.x - 70 - puff, base.y + 8), 5.0, Color(0.85, 0.85, 0.9, 0.3))


func _draw_dash_streaks(y: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in 7:
		var offset := fmod(t * 900.0 + i * 137.0, 420.0)
		var line_y := y - 20.0 - fmod(i * 53.0, 96.0)
		var alpha := 0.35 * (1.0 - offset / 420.0)
		draw_rect(Rect2(-offset - 40.0, line_y, 70.0, 4.0), Color(0.7, 0.95, 1.0, alpha))


func _rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)


func _limb(from: Vector2, to: Vector2, color: Color, outline_width: float, fill_width: float) -> void:
	draw_line(from, to, OUTLINE, outline_width, true)
	draw_line(from, to, color, fill_width, true)

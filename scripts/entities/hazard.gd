## Lane-locked obstacle. Ground hazards are cleared by jumping, overhead
## hazards by sliding; every hazard can also be avoided with a lane switch.
## Layer 2 / mask 0 - the player's hitbox does the detecting (GDD Section VI).
class_name Hazard
extends Area2D

enum Kind {
	TRASH_CAN, CONE, BICYCLE, MOP_BUCKET, DOOR, SKATEBOARD,
	VACUUM, LOW_BRANCH, BANNER, MOTORCYCLE, TOY, PET,
}

const ZONE_KINDS := {
	GameConfig.Zone.HOME: [Kind.TOY, Kind.VACUUM, Kind.PET, Kind.TRASH_CAN],
	GameConfig.Zone.STREET: [Kind.CONE, Kind.TRASH_CAN, Kind.BICYCLE, Kind.SKATEBOARD, Kind.MOTORCYCLE, Kind.LOW_BRANCH],
	GameConfig.Zone.HALLWAY: [Kind.MOP_BUCKET, Kind.DOOR, Kind.BANNER],
}

const OVERHEAD_KINDS := [Kind.LOW_BRANCH, Kind.BANNER]
const MOVING_KINDS := [Kind.SKATEBOARD, Kind.VACUUM, Kind.MOTORCYCLE, Kind.PET, Kind.BICYCLE]

@export var kind: int = Kind.CONE
@export var lane: int = 1
@export var extra_speed: float = 0.0

var zone: int = GameConfig.Zone.STREET
var requires_slide: bool = false
var was_hit: bool = false
var _flash: float = 0.0
var _shape: RectangleShape2D
var _collider: CollisionShape2D


func _ready() -> void:
	add_to_group("hazards")
	add_to_group("scrolling")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	position.y = GameConfig.lane_y(lane)
	requires_slide = OVERHEAD_KINDS.has(kind)
	if MOVING_KINDS.has(kind) and extra_speed <= 0.0:
		extra_speed = 90.0
	_setup_collider()
	if extra_speed > 0.0:
		add_to_group("moving_hazards")


func _setup_collider() -> void:
	_collider = $CollisionShape2D
	_shape = RectangleShape2D.new()
	_collider.shape = _shape
	match kind:
		Kind.TRASH_CAN:
			_shape.size = Vector2(66, 92)
			_collider.position = Vector2(0, -46)
		Kind.CONE:
			_shape.size = Vector2(54, 58)
			_collider.position = Vector2(0, -29)
		Kind.BICYCLE:
			_shape.size = Vector2(126, 74)
			_collider.position = Vector2(0, -37)
		Kind.MOP_BUCKET:
			_shape.size = Vector2(72, 68)
			_collider.position = Vector2(0, -34)
		Kind.DOOR:
			_shape.size = Vector2(92, 160)
			_collider.position = Vector2(0, -80)
		Kind.SKATEBOARD:
			_shape.size = Vector2(96, 34)
			_collider.position = Vector2(0, -17)
		Kind.VACUUM:
			_shape.size = Vector2(76, 38)
			_collider.position = Vector2(0, -19)
		Kind.LOW_BRANCH, Kind.BANNER:
			_shape.size = Vector2(140, 62)
			_collider.position = Vector2(0, -109)
		Kind.MOTORCYCLE:
			_shape.size = Vector2(150, 96)
			_collider.position = Vector2(0, -48)
		Kind.TOY:
			_shape.size = Vector2(54, 36)
			_collider.position = Vector2(0, -18)
		Kind.PET:
			_shape.size = Vector2(84, 58)
			_collider.position = Vector2(0, -29)
		_:
			_shape.size = Vector2(70, 70)
			_collider.position = Vector2(0, -35)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		queue_redraw()
	if kind == Kind.BANNER:
		queue_redraw()


func is_hazard() -> bool:
	return true


func on_player_hit() -> void:
	was_hit = true
	_flash = 1.0
	AudioDirector.play_sfx("hurt")
	queue_redraw()


func hazard_name() -> String:
	return Kind.keys()[kind].to_lower().replace("_", " ")


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	match kind:
		Kind.TRASH_CAN:
			_draw_trash_can()
		Kind.CONE:
			_draw_cone()
		Kind.BICYCLE:
			_draw_bicycle()
		Kind.MOP_BUCKET:
			_draw_mop_bucket()
		Kind.DOOR:
			_draw_door()
		Kind.SKATEBOARD:
			_draw_skateboard()
		Kind.VACUUM:
			_draw_vacuum()
		Kind.LOW_BRANCH:
			_draw_branch()
		Kind.BANNER:
			_draw_banner()
		Kind.MOTORCYCLE:
			_draw_motorcycle()
		Kind.TOY:
			_draw_toy()
		Kind.PET:
			_draw_pet()
	if _flash > 0.0:
		draw_circle(Vector2(0, -40), 62.0, Color(1.0, 0.35, 0.3, _flash * 0.35))


func _outline_rect(rect: Rect2, color: Color, outline: int = 4) -> void:
	draw_rect(rect.grow(outline), Color("#171325"))
	draw_rect(rect, color)


func _draw_trash_can() -> void:
	draw_rect(Rect2(-38, -8, 76, 12), Color(0.1, 0.09, 0.16, 0.35))
	_outline_rect(Rect2(-28, -78, 56, 74), Color("#5f6b7d"))
	draw_rect(Rect2(-28, -78, 56, 10), Color("#8794a8"))
	for i in 3:
		draw_rect(Rect2(-22 + i * 18, -60, 4, 46), Color("#4a5568"))
	draw_rect(Rect2(-34, -88, 68, 12), Color("#8794a8"))


func _draw_cone() -> void:
	draw_rect(Rect2(-30, -8, 60, 10), Color(0.1, 0.09, 0.16, 0.35))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-24, 0), Vector2(24, 0), Vector2(6, -66), Vector2(-6, -66)]),
		Color("#171325")
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-20, -4), Vector2(20, -4), Vector2(5, -62), Vector2(-5, -62)]),
		Color("#ff8b2b")
	)
	draw_rect(Rect2(-14, -34, 28, 9), Color("#fff3e0"))
	draw_rect(Rect2(-30, -6, 60, 8), Color("#ff8b2b"))


func _draw_bicycle() -> void:
	draw_rect(Rect2(-62, -8, 124, 10), Color(0.1, 0.09, 0.16, 0.35))
	for wheel_x in [-40.0, 40.0]:
		draw_circle(Vector2(wheel_x, -26), 21.0, Color("#171325"))
		draw_circle(Vector2(wheel_x, -26), 16.0, Color("#2c3244"))
		draw_circle(Vector2(wheel_x, -26), 6.0, Color("#9aa7bd"))
	draw_line(Vector2(-40, -26), Vector2(0, -52), Color("#e8453c"), 7.0)
	draw_line(Vector2(0, -52), Vector2(38, -26), Color("#e8453c"), 7.0)
	draw_line(Vector2(-40, -26), Vector2(8, -26), Color("#e8453c"), 7.0)
	draw_line(Vector2(30, -26), Vector2(26, -58), Color("#c8d1e0"), 5.0)
	draw_line(Vector2(16, -58), Vector2(36, -58), Color("#c8d1e0"), 5.0)
	draw_rect(Rect2(-2, -58, 20, 8), Color("#171325"))
	draw_circle(Vector2(-18, -34), 6.0, Color("#ffd166"))


func _draw_mop_bucket() -> void:
	draw_rect(Rect2(-34, -8, 68, 10), Color(0.1, 0.09, 0.16, 0.35))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-32, -56), Vector2(32, -56), Vector2(26, 0), Vector2(-26, 0)]),
		Color("#171325")
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-28, -52), Vector2(28, -52), Vector2(22, -4), Vector2(-22, -4)]),
		Color("#ffd23f")
	)
	draw_rect(Rect2(-30, -60, 60, 8), Color("#e8b21a"))
	draw_line(Vector2(18, -54), Vector2(42, -102), Color("#a9713f"), 6.0)
	draw_circle(Vector2(44, -108), 10.0, Color("#e8e2d0"))
	draw_circle(Vector2(44, -108), 10.0, Color("#f6f2e6"))


func _draw_door() -> void:
	draw_rect(Rect2(-46, -8, 92, 12), Color(0.1, 0.09, 0.16, 0.35))
	_outline_rect(Rect2(-40, -160, 80, 158), Color("#a9713f"))
	draw_rect(Rect2(-32, -148, 64, 60), Color("#c98a4b"))
	draw_rect(Rect2(-32, -78, 64, 64), Color("#c98a4b"))
	draw_circle(Vector2(26, -84), 5.0, Color("#ffd166"))
	draw_rect(Rect2(-40, -160, 80, 8), Color("#7d5228"))
	# Swinging-open sign wedge.
	draw_colored_polygon(
		PackedVector2Array([Vector2(-52, -30), Vector2(-74, -14), Vector2(-52, -14)]),
		Color("#ff5a4f")
	)


func _draw_skateboard() -> void:
	draw_rect(Rect2(-48, -6, 96, 8), Color(0.1, 0.09, 0.16, 0.35))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-48, -18), Vector2(-38, -24), Vector2(38, -24), Vector2(48, -18), Vector2(40, -12), Vector2(-40, -12)]),
		Color("#171325")
	)
	draw_rect(Rect2(-36, -22, 72, 8), Color("#d64545"))
	draw_circle(Vector2(-28, -10), 7.0, Color("#2c3244"))
	draw_circle(Vector2(28, -10), 7.0, Color("#2c3244"))
	draw_circle(Vector2(-28, -10), 3.0, Color("#ffd166"))
	draw_circle(Vector2(28, -10), 3.0, Color("#ffd166"))


func _draw_vacuum() -> void:
	draw_rect(Rect2(-38, -6, 76, 8), Color(0.1, 0.09, 0.16, 0.35))
	draw_circle(Vector2(0, -20), 20.0, Color("#171325"))
	draw_circle(Vector2(0, -20), 16.0, Color("#8b9bb4"))
	draw_circle(Vector2(0, -20), 8.0, Color("#5c6a82"))
	draw_rect(Rect2(-30, -34, 60, 6), Color("#d7e0ee"))
	draw_circle(Vector2(24, -22), 4.0, Color("#63e6a8"))
	draw_line(Vector2(-22, -12), Vector2(-34, -2), Color("#ffb703"), 3.0)


func _draw_branch() -> void:
	# Low-hanging tree branch: slide underneath.
	draw_rect(Rect2(-72, -132, 144, 16), Color("#171325"))
	draw_rect(Rect2(-72, -132, 144, 10), Color("#6b4a2c"))
	for i in 3:
		var x := -56.0 + i * 52.0
		draw_colored_polygon(
			PackedVector2Array([Vector2(x, -132), Vector2(x + 26, -132), Vector2(x + 12, -164), Vector2(x + 2, -136)]),
			Color("#2f8f4e")
		)
	draw_rect(Rect2(-22, -130, 6, 12), Color("#3e2f22"))
	draw_circle(Vector2(20, -122), 8.0, Color("#ff5a4f"))


func _draw_banner() -> void:
	draw_line(Vector2(-70, -158), Vector2(70, -158), Color("#9aa7bd"), 5.0)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-66, -156), Vector2(66, -156), Vector2(58, -104), Vector2(-58, -104)]),
		Color("#171325")
	)
	draw_rect(Rect2(-58, -152, 116, 42), Color("#ff9ad5"))
	draw_rect(Rect2(-58, -152, 116, 10), Color("#c75a9b"))
	# "SALE" style blocks instead of text.
	draw_rect(Rect2(-34, -134, 18, 12), Color("#fff"))
	draw_rect(Rect2(-10, -134, 18, 12), Color("#fff"))
	draw_rect(Rect2(14, -134, 18, 12), Color("#fff"))


func _draw_motorcycle() -> void:
	draw_rect(Rect2(-70, -6, 140, 10), Color(0.1, 0.09, 0.16, 0.35))
	for wheel_x in [-46.0, 46.0]:
		draw_circle(Vector2(wheel_x, -24), 24.0, Color("#171325"))
		draw_circle(Vector2(wheel_x, -24), 18.0, Color("#2c3244"))
		draw_circle(Vector2(wheel_x, -24), 7.0, Color("#9aa7bd"))
	draw_rect(Rect2(-34, -60, 62, 26), Color("#37b6a8"))
	draw_circle(Vector2(34, -58), 14.0, Color("#171325"))
	draw_circle(Vector2(34, -58), 10.0, Color("#4a5568"))
	draw_line(Vector2(-46, -24), Vector2(-6, -56), Color("#9aa7bd"), 6.0)
	draw_rect(Rect2(-12, -74, 34, 8), Color("#171325"))
	# Rider silhouette.
	draw_circle(Vector2(2, -92), 13.0, Color("#171325"))
	draw_rect(Rect2(-10, -84, 26, 26), Color("#171325"))


func _draw_toy() -> void:
	var colors := [Color("#ff6b6b"), Color("#4dabf7"), Color("#ffd43b")]
	for i in 3:
		var offset := Vector2(-22 + i * 18, -12 - (i % 2) * 16)
		draw_circle(offset, 12.0, Color("#171325"))
		draw_circle(offset, 9.0, colors[i])


func _draw_pet() -> void:
	draw_rect(Rect2(-40, -6, 80, 8), Color(0.1, 0.09, 0.16, 0.35))
	# Dog body + legs + tail.
	_outline_rect(Rect2(-30, -40, 54, 26), Color("#c98a4b"))
	draw_circle(Vector2(28, -46), 15.0, Color("#171325"))
	draw_circle(Vector2(28, -46), 12.0, Color("#d99a5b"))
	draw_rect(Rect2(-14, -16, 8, 14), Color("#a9713f"))
	draw_rect(Rect2(10, -16, 8, 14), Color("#a9713f"))
	draw_line(Vector2(-30, -36), Vector2(-44, -50), Color("#c98a4b"), 5.0)
	draw_circle(Vector2(30, -50), 3.0, Color("#171325"))

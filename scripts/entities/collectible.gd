## School item collectible (book, pencil, backpack, lunchbox, ruler, notebook).
## Layer 4 / mask 0. Overlap increments the counter and score, then despawns
## without touching the player's velocity (GDD Section VI).
class_name Collectible
extends Area2D

const KINDS := ["book", "pencil", "backpack", "lunchbox", "ruler", "notebook"]
const KIND_COLORS := {
	"book": Color("#4dabf7"),
	"pencil": Color("#ffd43b"),
	"backpack": Color("#ff922b"),
	"lunchbox": Color("#63e6a8"),
	"ruler": Color("#ff9ad5"),
	"notebook": Color("#b197fc"),
}

@export var kind: String = "book"
@export var lane: int = 1

var collected: bool = false
var _bob_phase: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	add_to_group("collectibles")
	add_to_group("scrolling")
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	_base_y = GameConfig.lane_y(lane) - 74.0
	position.y = _base_y
	_bob_phase = randf() * TAU
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	var collider := $CollisionShape2D
	collider.shape = shape
	z_index = 5


func _process(delta: float) -> void:
	_bob_phase += delta * 2.4
	position.y = _base_y + sin(_bob_phase) * 10.0
	queue_redraw()


func is_collectible() -> bool:
	return true


func collect() -> void:
	if collected:
		return
	collected = true
	monitoring = false
	monitorable = false
	remove_from_group("scrolling")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(queue_free)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	var pulse := 1.0 + sin(_bob_phase * 1.6) * 0.05
	draw_circle(Vector2.ZERO, 34.0 * pulse, Color(1.0, 0.96, 0.75, 0.16))
	draw_circle(Vector2.ZERO, 26.0 * pulse, Color(1.0, 0.96, 0.75, 0.24))
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 24, Color(1, 1, 1, 0.45), 2.0)
	match kind:
		"book":
			_draw_book()
		"pencil":
			_draw_pencil()
		"backpack":
			_draw_backpack()
		"lunchbox":
			_draw_lunchbox()
		"ruler":
			_draw_ruler()
		_:
			_draw_notebook()
	# Sparkle.
	var sparkle := 0.6 + 0.4 * sin(_bob_phase * 2.0)
	draw_circle(Vector2(20, -18), 3.0 * sparkle, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(-22, 12), 2.0 * sparkle, Color(1, 1, 1, 0.7))


func _draw_book() -> void:
	draw_rect(Rect2(-22, -26, 44, 52).grow(3), Color("#171325"))
	draw_rect(Rect2(-22, -26, 44, 52), Color("#2f6fd0"))
	draw_rect(Rect2(-22, -26, 8, 52), Color("#1f4a93"))
	draw_rect(Rect2(-10, -14, 26, 6), Color("#f6f8ff"))
	draw_rect(Rect2(-10, 0, 20, 4), Color("#cfe0ff"))


func _draw_pencil() -> void:
	draw_colored_polygon(
		PackedVector2Array([Vector2(-6, 26), Vector2(6, 26), Vector2(6, -18), Vector2(-6, -18)]),
		Color("#171325")
	)
	draw_rect(Rect2(-5, -18, 10, 36), Color("#ffd43b"))
	draw_rect(Rect2(-5, -18, 10, 8), Color("#ff9ad5"))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-6, -18), Vector2(6, -18), Vector2(0, -30)]),
		Color("#f2d2b0")
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-2.5, -25), Vector2(2.5, -25), Vector2(0, -30)]),
		Color("#171325")
	)


func _draw_backpack() -> void:
	draw_rect(Rect2(-20, -24, 40, 46).grow(3), Color("#171325"))
	draw_rect(Rect2(-20, -24, 40, 46), Color("#ff922b"))
	draw_rect(Rect2(-14, -6, 28, 22), Color("#e8590c"))
	draw_arc(Vector2(0, -24), 13.0, PI, TAU, 14, Color("#171325"), 5.0)
	draw_rect(Rect2(-4, -4, 8, 8), Color("#ffd43b"))


func _draw_lunchbox() -> void:
	draw_rect(Rect2(-24, -16, 48, 34).grow(3), Color("#171325"))
	draw_rect(Rect2(-24, -16, 48, 34), Color("#63e6a8"))
	draw_rect(Rect2(-24, -16, 48, 8), Color("#2f9e6f"))
	draw_arc(Vector2(0, -16), 12.0, PI, TAU, 12, Color("#171325"), 4.0)
	draw_rect(Rect2(-6, 0, 12, 8), Color("#f6f8ff"))


func _draw_ruler() -> void:
	draw_rect(Rect2(-30, -9, 60, 18).grow(3), Color("#171325"))
	draw_rect(Rect2(-30, -9, 60, 18), Color("#ff9ad5"))
	for i in 5:
		draw_rect(Rect2(-24 + i * 12, -9, 2, 8), Color("#7a3a63"))


func _draw_notebook() -> void:
	draw_rect(Rect2(-21, -27, 42, 54).grow(3), Color("#171325"))
	draw_rect(Rect2(-21, -27, 42, 54), Color("#b197fc"))
	draw_rect(Rect2(-21, -27, 7, 54), Color("#8462e0"))
	for i in 3:
		draw_rect(Rect2(-8, -14 + i * 12, 22, 4), Color("#f0ebff"))

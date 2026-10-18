## Cross-fades the procedural parallax layers when the run enters a new zone
## (Home Area -> Neighborhood Street -> School Hallway).
class_name ZoneBackdrop
extends Node2D

var current_zone: int = GameConfig.Zone.HOME
var _front: ZoneLayer
var _back: ZoneLayer
var _fade: Tween


func _ready() -> void:
	z_index = -50
	_front = ZoneLayer.new()
	_back = ZoneLayer.new()
	add_child(_front)
	add_child(_back)
	_front.setup(current_zone)
	_back.setup(current_zone)
	_front.modulate.a = 1.0
	_back.modulate.a = 0.0


func set_zone(zone: int, instant: bool = false) -> void:
	zone = clampi(zone, 0, 2)
	if zone == current_zone and not instant:
		return
	current_zone = zone
	if instant:
		_front.setup(zone)
		_back.setup(zone)
		_front.modulate.a = 1.0
		_back.modulate.a = 0.0
		return
	_back.setup(zone)
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(_back, "modulate:a", 1.0, 1.1)
	_fade.tween_property(_front, "modulate:a", 0.0, 1.1)
	_fade.chain().tween_callback(_swap_layers)


func _swap_layers() -> void:
	var old := _front
	_front = _back
	_back = old
	_front.modulate.a = 1.0
	_back.modulate.a = 0.0


func advance(delta: float, world_speed: float, speed_ratio: float) -> void:
	if _front != null:
		_front.advance(delta, world_speed, speed_ratio)
	if _back != null and _back.modulate.a > 0.01:
		_back.advance(delta, world_speed, speed_ratio)

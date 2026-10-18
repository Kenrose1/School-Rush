## One procedural parallax layer of the game world (Home / Street / Hallway).
## Two of these are cross-faded by ZoneBackdrop when the run enters a new zone.
class_name ZoneLayer
extends Node2D

const FLOOR_Y := 566.0
const WIDTH := 1920.0
const HEIGHT := 1080.0

var zone: int = GameConfig.Zone.HOME
var scroll: float = 0.0
var speed_ratio: float = 0.0
var time: float = 0.0


func _ready() -> void:
	z_index = -50


func setup(new_zone: int) -> void:
	zone = new_zone
	queue_redraw()


func advance(delta: float, world_speed: float, ratio: float) -> void:
	scroll += world_speed * delta
	speed_ratio = ratio
	time += delta
	queue_redraw()


func _draw() -> void:
	match zone:
		GameConfig.Zone.HOME:
			_draw_home()
		GameConfig.Zone.STREET:
			_draw_street()
		_:
			_draw_hallway()


# --- HOME AREA --------------------------------------------------------------

func _draw_home() -> void:
	# Wall + wallpaper.
	draw_rect(Rect2(0, 0, WIDTH, FLOOR_Y), Color("#f6e6c8"))
	for i in 10:
		var y := float(i) * 58.0
		draw_rect(Rect2(0, y, WIDTH, 2), Color("#eed4ac"))
	var stripe := fposmod(-scroll * 0.04, 96.0)
	for i in 22:
		var x := stripe + float(i) * 96.0
		draw_rect(Rect2(x, 0, 10, FLOOR_Y), Color(1, 1, 1, 0.16))
	# Warm window with morning light.
	var window_x := fposmod(-scroll * 0.12, 1240.0) + 180.0
	_draw_window(Vector2(window_x, 210), Vector2(300, 250))
	_draw_window(Vector2(window_x - 1240, 210), Vector2(300, 250))
	# Hanging frames.
	var frames := fposmod(-scroll * 0.2, 720.0)
	for i in 3:
		var x := frames + float(i) * 720.0 + 60.0
		draw_rect(Rect2(x, 150, 110, 86), Color("#8a6740"))
		draw_rect(Rect2(x + 5, 155, 100, 76), Color("#cfe3ff"))
		draw_rect(Rect2(x + 24, 190, 40, 26), Color("#7fbf5a"))
		draw_circle(Vector2(x + 72, 176), 12.0, Color("#ffd166"))
	# Far furniture.
	var far := fposmod(-scroll * 0.28, 640.0)
	_draw_bed(Vector2(far + 260, FLOOR_Y))
	_draw_bed(Vector2(far - 640 + 260, FLOOR_Y))
	# Mid furniture.
	var mid := fposmod(-scroll * 0.55, 860.0)
	for i in 3:
		var x := mid + float(i) * 860.0
		_draw_dresser(Vector2(x + 60, FLOOR_Y))
		_draw_lamp(Vector2(x + 470, FLOOR_Y))
		_draw_shoe_pile(Vector2(x + 330, FLOOR_Y))
	# Floor.
	draw_rect(Rect2(0, FLOOR_Y, WIDTH, HEIGHT - FLOOR_Y), Color("#c98a4b"))
	var plank := fposmod(-scroll, 190.0)
	for i in 14:
		var x := plank + float(i) * 190.0
		draw_rect(Rect2(x, FLOOR_Y, 4, HEIGHT - FLOOR_Y), Color("#a9713f"))
	for i in 7:
		var y := FLOOR_Y + 44.0 + float(i) * 74.0
		draw_rect(Rect2(0, y, WIDTH, 3), Color("#b87c42"))
	# Lane bands.
	_draw_lane_bands(Color("#b3763d"), Color("#d9a05f"))
	_draw_npcs_home()


func _draw_window(pos: Vector2, size: Vector2) -> void:
	draw_rect(Rect2(pos, size).grow(10), Color("#8a6740"))
	draw_rect(Rect2(pos, size), Color("#bfe9ff"))
	draw_rect(Rect2(pos, size), Color(1, 0.98, 0.8, 0.35))
	draw_rect(Rect2(pos.x + size.x * 0.5 - 4, pos.y, 8, size.y), Color("#8a6740"))
	draw_rect(Rect2(pos.x, pos.y + size.y * 0.5 - 4, size.x, 8), Color("#8a6740"))
	draw_rect(Rect2(pos.x, pos.y + size.y, size.x, 14), Color("#e8d2ae"))


func _draw_bed(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 190, pos.y - 130, 340, 130), Color("#7a5a3a"))
	draw_rect(Rect2(pos.x - 180, pos.y - 118, 320, 60), Color("#f4f7ff"))
	draw_rect(Rect2(pos.x - 180, pos.y - 70, 320, 54), Color("#5d8fd6"))
	draw_rect(Rect2(pos.x - 196, pos.y - 150, 22, 150), Color("#6b4a2c"))
	draw_rect(Rect2(pos.x + 136, pos.y - 110, 18, 110), Color("#6b4a2c"))


func _draw_dresser(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 90, pos.y - 210, 180, 210), Color("#7a5a3a"))
	draw_rect(Rect2(pos.x - 82, pos.y - 200, 164, 60), Color("#8f6a44"))
	draw_rect(Rect2(pos.x - 82, pos.y - 130, 164, 60), Color("#8f6a44"))
	draw_rect(Rect2(pos.x - 82, pos.y - 60, 164, 52), Color("#8f6a44"))
	draw_circle(Vector2(pos.x, pos.y - 170), 6.0, Color("#ffd166"))
	draw_circle(Vector2(pos.x, pos.y - 100), 6.0, Color("#ffd166"))
	draw_rect(Rect2(pos.x - 66, pos.y - 246, 44, 36), Color("#ff9ad5"))
	draw_circle(Vector2(pos.x + 6, pos.y - 246), 22.0, Color("#ffd166"))


func _draw_lamp(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 8, pos.y - 240, 16, 240), Color("#6b7280"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(pos.x - 46, pos.y - 300), Vector2(pos.x + 46, pos.y - 300),
			Vector2(pos.x + 30, pos.y - 250), Vector2(pos.x - 30, pos.y - 250),
		]),
		Color("#ffd166")
	)
	draw_circle(Vector2(pos.x, pos.y - 258), 52.0, Color(1, 0.86, 0.45, 0.16))
	draw_rect(Rect2(pos.x - 30, pos.y - 6, 60, 8), Color("#4a5568"))


func _draw_shoe_pile(pos: Vector2) -> void:
	for i in 3:
		var x := pos.x + float(i) * 26.0 - 26.0
		var y := pos.y - float(i % 2) * 12.0
		draw_rect(Rect2(x, y - 16, 40, 16), Color("#e8453c"))
		draw_rect(Rect2(x + 4, y - 12, 32, 8), Color("#f6f8ff"))


func _draw_npcs_home() -> void:
	var positions := [150.0, 780.0, 1400.0]
	var colors := [Color("#8fb3ff"), Color("#ffb3c1"), Color("#b197fc")]
	for i in positions.size():
		var x := fposmod(positions[i] - scroll * 0.3, WIDTH + 300.0) - 150.0
		_draw_npc(Vector2(x, FLOOR_Y + 40.0), colors[i], float(i) * 1.7)


# --- NEIGHBORHOOD STREET ----------------------------------------------------

func _draw_street() -> void:
	var sky_top := Color("#5fb6f2")
	var sky_bottom := Color("#d8f0ff")
	for i in 12:
		var t := float(i) / 12.0
		draw_rect(Rect2(0, t * FLOOR_Y, WIDTH, FLOOR_Y / 12.0 + 2), sky_top.lerp(sky_bottom, t))
	# Sun.
	draw_circle(Vector2(1660, 150), 74.0, Color(1, 0.95, 0.7, 0.35))
	draw_circle(Vector2(1660, 150), 52.0, Color("#fff3b0"))
	# Clouds.
	var cloud := fposmod(-scroll * 0.05, 900.0)
	for i in 3:
		_draw_cloud(Vector2(cloud + float(i) * 900.0 + 120.0, 170.0 + float(i % 2) * 90.0))
		_draw_cloud(Vector2(cloud + float(i) * 900.0 - 780.0, 130.0 + float(i % 2) * 120.0))
	# Far skyline.
	var far := fposmod(-scroll * 0.14, 480.0)
	for i in 6:
		var x := far + float(i) * 480.0 - 200.0
		_draw_far_house(Vector2(x, FLOOR_Y - 40.0))
	# Mid houses + street furniture.
	var mid := fposmod(-scroll * 0.42, 760.0)
	for i in 4:
		var x := mid + float(i) * 760.0
		_draw_house(Vector2(x + 40.0, FLOOR_Y))
		_draw_fence(Vector2(x + 330.0, FLOOR_Y))
		_draw_tree(Vector2(x + 520.0, FLOOR_Y))
		_draw_lamppost(Vector2(x + 660.0, FLOOR_Y))
	# Sidewalk + road.
	draw_rect(Rect2(0, FLOOR_Y, WIDTH, 150), Color("#cfd6df"))
	var slab := fposmod(-scroll, 120.0)
	for i in 18:
		draw_rect(Rect2(slab + float(i) * 120.0, FLOOR_Y, 4, 150), Color("#b3bcc7"))
	draw_rect(Rect2(0, FLOOR_Y + 150, WIDTH, HEIGHT - FLOOR_Y - 150), Color("#444d5e"))
	draw_rect(Rect2(0, FLOOR_Y + 150, WIDTH, 10), Color("#8b95a6"))
	# Road dashes.
	var dash := fposmod(-scroll * 1.0, 220.0)
	for i in 12:
		draw_rect(Rect2(dash + float(i) * 220.0, FLOOR_Y + 300.0, 110, 10), Color("#ffd166"))
	# Lane bands.
	_draw_lane_bands(Color("#b9c2ce"), Color("#dfe6ee"))
	_draw_npcs_street()


func _draw_cloud(pos: Vector2) -> void:
	var alpha := Color(1, 1, 1, 0.9)
	draw_circle(pos, 34.0, alpha)
	draw_circle(pos + Vector2(36, 8), 28.0, alpha)
	draw_circle(pos + Vector2(-34, 10), 24.0, alpha)
	draw_rect(Rect2(pos.x - 34, pos.y + 4, 74, 22), alpha)


func _draw_far_house(pos: Vector2) -> void:
	var color := Color("#9db8d6")
	draw_rect(Rect2(pos.x, pos.y - 150, 130, 150), color)
	draw_colored_polygon(
		PackedVector2Array([Vector2(pos.x - 12, pos.y - 150), Vector2(pos.x + 65, pos.y - 205), Vector2(pos.x + 142, pos.y - 150)]),
		Color("#8aa6c6")
	)
	draw_rect(Rect2(pos.x + 24, pos.y - 110, 26, 26), Color("#c9dcf0"))
	draw_rect(Rect2(pos.x + 78, pos.y - 110, 26, 26), Color("#c9dcf0"))


func _draw_house(pos: Vector2) -> void:
	var wall := Color("#f2d3a8")
	draw_rect(Rect2(pos.x - 120, pos.y - 300, 360, 300), wall)
	draw_rect(Rect2(pos.x - 120, pos.y - 300, 360, 12), Color("#d9b184"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(pos.x - 150, pos.y - 300), Vector2(pos.x + 60, pos.y - 400), Vector2(pos.x + 270, pos.y - 300),
		]),
		Color("#c0533f")
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(pos.x - 130, pos.y - 300), Vector2(pos.x + 60, pos.y - 386), Vector2(pos.x + 250, pos.y - 300),
		]),
		Color("#d96850")
	)
	# Door + windows.
	draw_rect(Rect2(pos.x + 38, pos.y - 150, 72, 150), Color("#7a4a2c"))
	draw_circle(Vector2(pos.x + 98, pos.y - 74), 5.0, Color("#ffd166"))
	draw_rect(Rect2(pos.x - 96, pos.y - 250, 70, 62), Color("#bfe9ff"))
	draw_rect(Rect2(pos.x - 96, pos.y - 250, 70, 62), Color(1, 1, 1, 0.25))
	draw_rect(Rect2(pos.x + 128, pos.y - 250, 70, 62), Color("#bfe9ff"))
	draw_rect(Rect2(pos.x - 100, pos.y - 254, 78, 8), Color("#f6f8ff"))
	draw_rect(Rect2(pos.x + 124, pos.y - 254, 78, 8), Color("#f6f8ff"))


func _draw_fence(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x, pos.y - 90, 150, 10), Color("#f4f7ff"))
	for i in 6:
		draw_rect(Rect2(pos.x + float(i) * 26.0, pos.y - 110, 8, 110), Color("#f4f7ff"))
	draw_rect(Rect2(pos.x, pos.y - 56, 150, 8), Color("#dfe6ee"))


func _draw_tree(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 14, pos.y - 190, 28, 190), Color("#7a5233"))
	draw_circle(Vector2(pos.x, pos.y - 240), 66.0, Color("#4f9e58"))
	draw_circle(Vector2(pos.x - 48, pos.y - 210), 42.0, Color("#5cb066"))
	draw_circle(Vector2(pos.x + 48, pos.y - 214), 46.0, Color("#3f8a4a"))
	draw_circle(Vector2(pos.x + 16, pos.y - 280), 38.0, Color("#63bd6c"))


func _draw_lamppost(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 6, pos.y - 300, 12, 300), Color("#4a5568"))
	draw_rect(Rect2(pos.x - 26, pos.y - 320, 52, 22), Color("#2f3644"))
	draw_rect(Rect2(pos.x - 20, pos.y - 316, 40, 10), Color("#ffe08a"))
	draw_circle(Vector2(pos.x, pos.y - 306), 34.0, Color(1, 0.9, 0.5, 0.12))


func _draw_npcs_street() -> void:
	var items := [
		[260.0, Color("#2f6fd0"), 0.4],
		[880.0, Color("#e8453c"), 1.1],
		[1510.0, Color("#8f6a44"), 2.3],
	]
	for entry in items:
		var x := fposmod(float(entry[0]) - scroll * 0.55, WIDTH + 300.0) - 150.0
		_draw_npc(Vector2(x, FLOOR_Y + 44.0), entry[1], float(entry[2]))


# --- SCHOOL HALLWAY ---------------------------------------------------------

func _draw_hallway() -> void:
	# Upper wall + wainscot.
	draw_rect(Rect2(0, 0, WIDTH, FLOOR_Y), Color("#d7e9e5"))
	draw_rect(Rect2(0, 300, WIDTH, FLOOR_Y - 300), Color("#9cc4bd"))
	draw_rect(Rect2(0, 300, WIDTH, 12), Color("#7ea8a1"))
	# Ceiling lights (slow parallax).
	var light_x := fposmod(-scroll * 0.06, 640.0)
	for i in 4:
		var x := light_x + float(i) * 640.0
		draw_rect(Rect2(x, 40, 260, 26), Color("#f2fbf8"))
		draw_rect(Rect2(x - 12, 30, 284, 10), Color("#6d8f8a"))
		draw_circle(Vector2(x + 130, 60), 160.0, Color(1, 1, 0.92, 0.07))
	# Far windows / doors.
	var far := fposmod(-scroll * 0.16, 520.0)
	for i in 4:
		var x := far + float(i) * 520.0
		draw_rect(Rect2(x + 90, 120, 180, 150), Color("#bfe6ff"))
		draw_rect(Rect2(x + 90, 120, 180, 150), Color(1, 1, 1, 0.3))
		draw_rect(Rect2(x + 84, 114, 192, 10), Color("#6d8f8a"))
	# Lockers (mid).
	var mid := fposmod(-scroll * 0.5, 300.0)
	for i in 8:
		var x := mid + float(i) * 300.0 - 300.0
		_draw_locker(Vector2(x, FLOOR_Y))
	# Classroom doors + bulletin boards.
	var doors := fposmod(-scroll * 0.5, 1200.0)
	for i in 3:
		var x := doors + float(i) * 1200.0
		_draw_classroom_door(Vector2(x + 520.0, FLOOR_Y))
		_draw_bulletin(Vector2(x + 120.0, 210.0))
	# Floor tiles.
	draw_rect(Rect2(0, FLOOR_Y, WIDTH, HEIGHT - FLOOR_Y), Color("#dfe7e4"))
	var tile := fposmod(-scroll, 96.0)
	for i in 22:
		var x := tile + float(i) * 96.0
		draw_rect(Rect2(x, FLOOR_Y, 3, HEIGHT - FLOOR_Y), Color("#c2cfcb"))
	for i in 7:
		var y := FLOOR_Y + 44.0 + float(i) * 74.0
		draw_rect(Rect2(0, y, WIDTH, 3), Color("#c2cfcb"))
	for i in 11:
		var x := fposmod(tile + float(i) * 192.0, WIDTH + 192.0) - 96.0
		draw_rect(Rect2(x, FLOOR_Y, 96, HEIGHT - FLOOR_Y), Color(0, 0, 0, 0.03))
	# Lane bands.
	_draw_lane_bands(Color("#c8d4d0"), Color("#eef4f1"))
	_draw_npcs_hallway()


func _draw_locker(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x, pos.y - 230, 130, 230), Color("#3f7fa8"))
	draw_rect(Rect2(pos.x + 4, pos.y - 226, 122, 222), Color("#4a90bd"))
	draw_rect(Rect2(pos.x + 4, pos.y - 226, 122, 8), Color("#2f6487"))
	for i in 4:
		draw_rect(Rect2(pos.x + 20, pos.y - 200 + float(i) * 10.0, 90, 4), Color("#2f6487"))
	draw_rect(Rect2(pos.x + 96, pos.y - 140, 10, 26), Color("#d7e9e5"))
	draw_rect(Rect2(pos.x + 58, pos.y - 70, 14, 10), Color("#2f6487"))
	draw_rect(Rect2(pos.x, pos.y - 6, 130, 6), Color("#2f6487"))


func _draw_classroom_door(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 90, pos.y - 260, 180, 260), Color("#7a5233"))
	draw_rect(Rect2(pos.x - 82, pos.y - 250, 164, 250), Color("#a9713f"))
	draw_rect(Rect2(pos.x - 58, pos.y - 220, 116, 90), Color("#cfe3ff"))
	draw_rect(Rect2(pos.x - 58, pos.y - 220, 116, 90), Color(1, 1, 1, 0.25))
	draw_circle(Vector2(pos.x + 62, pos.y - 130), 6.0, Color("#ffd166"))
	draw_rect(Rect2(pos.x - 70, pos.y - 268, 140, 16), Color("#5f3f26"))


func _draw_bulletin(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x, pos.y, 220, 150), Color("#7a5233"))
	draw_rect(Rect2(pos.x + 8, pos.y + 8, 204, 134), Color("#c98a4b"))
	var papers := [
		Vector2(24, 24), Vector2(78, 18), Vector2(136, 30), Vector2(40, 80), Vector2(120, 76),
	]
	var colors := [Color("#fff"), Color("#ffe08a"), Color("#cfe3ff"), Color("#ffc9de"), Color("#fff")]
	for i in papers.size():
		draw_rect(Rect2(pos.x + papers[i].x, pos.y + papers[i].y, 46, 50), colors[i])
		draw_circle(Vector2(pos.x + papers[i].x + 23, pos.y + papers[i].y + 6), 4.0, Color("#e8453c"))


func _draw_npcs_hallway() -> void:
	var items := [
		[340.0, Color("#2f6fd0"), 0.9],
		[1040.0, Color("#ff922b"), 1.8],
		[1670.0, Color("#63e6a8"), 3.1],
	]
	for entry in items:
		var x := fposmod(float(entry[0]) - scroll * 0.6, WIDTH + 300.0) - 150.0
		_draw_npc(Vector2(x, FLOOR_Y + 46.0), entry[1], float(entry[2]))


# --- Shared helpers ---------------------------------------------------------

func _draw_lane_bands(dark: Color, light: Color) -> void:
	for i in GameConfig.LANE_COUNT:
		var center := float(GameConfig.LANE_Y[i])
		var alpha := 0.22 if i % 2 == 0 else 0.1
		draw_rect(Rect2(0, center - 58, WIDTH, 116), Color(light.r, light.g, light.b, alpha))
		draw_rect(Rect2(0, center - 58, WIDTH, 2), Color(dark.r, dark.g, dark.b, 0.5))
	# Chevron hints for lane readability.
	var chev := fposmod(-scroll, 260.0)
	for i in 9:
		var x := chev + float(i) * 260.0
		for lane in GameConfig.LANE_COUNT:
			var y := float(GameConfig.LANE_Y[lane]) + 74.0
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(x, y), Vector2(x + 14, y), Vector2(x + 7, y + 10),
				]),
				Color(dark.r, dark.g, dark.b, 0.18)
			)


func _draw_npc(pos: Vector2, shirt: Color, phase: float) -> void:
	var bob := sin(time * 2.0 + phase) * 4.0
	var y := pos.y + bob
	# Simple back-turned student silhouette with a looping walk cycle.
	var leg := sin(time * 3.0 + phase) * 6.0
	draw_rect(Rect2(pos.x - 13, y - 84, 10, 44 + leg), Color("#1d2740"))
	draw_rect(Rect2(pos.x + 3, y - 84, 10, 44 - leg), Color("#1d2740"))
	draw_rect(Rect2(pos.x - 18, y - 132, 36, 52), shirt)
	draw_rect(Rect2(pos.x - 18, y - 132, 36, 8), shirt.darkened(0.18))
	draw_circle(Vector2(pos.x, y - 146), 17.0, Color("#ffcda3"))
	draw_rect(Rect2(pos.x - 17, y - 164, 34, 12), Color("#37241a"))
	draw_rect(Rect2(pos.x - 22, y - 126, 8, 34), shirt.darkened(0.1))
	draw_rect(Rect2(pos.x + 14, y - 126, 8, 34), shirt.darkened(0.1))
	draw_rect(Rect2(pos.x - 22, y - 40, 16, 10), Color("#171325"))
	draw_rect(Rect2(pos.x + 6, y - 40, 16, 10), Color("#171325"))

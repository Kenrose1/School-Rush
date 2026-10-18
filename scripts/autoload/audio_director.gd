## Adaptive retro chiptune playback (GDD Section V - Audio / Music).
## Music is split per zone (110 / 130 / 155 BPM) with an extra percussion
## "drive" layer that fades in as the run speed climbs.
extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const SFX_POOL_SIZE := 10

const ZONE_TRACKS := ["music_home", "music_street", "music_hallway"]
const SFX_NAMES := [
	"jump", "slide", "lane", "pickup", "combo", "hurt", "dash",
	"bell", "gameover", "click", "pursuer", "victory",
]

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _drive: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _stream_cache: Dictionary = {}
var _active_music: AudioStreamPlayer
var _idle_music: AudioStreamPlayer
var _current_track: String = ""
var _intensity: float = 0.0
var _target_intensity: float = 0.0
var _fade_tween: Tween
var _drive_volume_db: float = -60.0


func _ready() -> void:
	_ensure_buses()
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_drive = _make_music_player()
	_active_music = _music_a
	_idle_music = _music_b
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_pool.append(player)
	apply_volumes()


func _process(delta: float) -> void:
	_intensity = move_toward(_intensity, _target_intensity, delta * 1.8)
	if _drive != null:
		var target_db := -60.0 if _intensity < 0.08 else lerpf(-60.0, -9.0, clampf(_intensity, 0.0, 1.0))
		_drive_volume_db = move_toward(_drive_volume_db, target_db, delta * 26.0)
		_drive.volume_db = _drive_volume_db
		_drive.pitch_scale = 1.0 + clampf(_intensity, 0.0, 1.0) * 0.12
	if _active_music != null:
		_active_music.pitch_scale = 1.0 + clampf(_intensity, 0.0, 1.0) * 0.1


func _ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var index := AudioServer.bus_count
			AudioServer.add_bus(index)
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func apply_volumes() -> void:
	var music_bus := AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_bus := AudioServer.get_bus_index(SFX_BUS)
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(SaveManager.music_volume, 0.0001)))
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(maxf(SaveManager.sfx_volume, 0.0001)))


func play_zone_music(zone: int) -> void:
	play_music(String(ZONE_TRACKS[clampi(zone, 0, 2)]))


func play_music(track: String, fade_time: float = 0.9, loop: bool = true) -> void:
	if track == _current_track and _active_music.playing:
		return
	var stream := _load_stream("res://assets/audio/%s.wav" % track)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		if loop:
			wav.loop_end = int(wav.get_length() * float(wav.mix_rate))
	_current_track = track

	var old := _active_music
	var next := _idle_music
	next.stream = stream
	next.volume_db = -40.0
	next.play()
	_active_music = next
	_idle_music = old

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(next, "volume_db", 0.0, fade_time)
	if old.playing:
		_fade_tween.tween_property(old, "volume_db", -40.0, fade_time)
		_fade_tween.chain().tween_callback(old.stop)

	if _drive != null:
		if _drive.stream == null:
			_drive.stream = _load_stream("res://assets/audio/music_drive.wav")
		if not _drive.playing:
			_drive.volume_db = _drive_volume_db
			_drive.play()


func stop_music(fade_time: float = 0.8) -> void:
	_current_track = ""
	_target_intensity = 0.0
	if _active_music != null and _active_music.playing:
		var tween := create_tween()
		tween.tween_property(_active_music, "volume_db", -40.0, fade_time)
		tween.tween_callback(_active_music.stop)
	if _drive != null and _drive.playing:
		_drive.stop()


## 0.0 = base speed, 1.0 = top speed. Drives the percussion layer + tempo.
func set_intensity(value: float) -> void:
	_target_intensity = clampf(value, 0.0, 1.0)


func play_sfx(sfx_name: String) -> void:
	if not SFX_NAMES.has(sfx_name):
		return
	var stream: AudioStream = _sfx_cache.get(sfx_name)
	if stream == null:
		stream = _load_stream("res://assets/audio/sfx_%s.wav" % sfx_name)
		if stream == null:
			return
		_sfx_cache[sfx_name] = stream
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = randf_range(0.97, 1.03)
			player.play()
			return
	var fallback: AudioStreamPlayer = _sfx_pool[0]
	fallback.stream = stream
	fallback.play()


func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		push_warning("Missing audio asset: %s" % path)
		return null
	var stream: Resource = load(path)
	if stream is AudioStream:
		_stream_cache[path] = stream
		return stream as AudioStream
	return null


func _make_music_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = MUSIC_BUS
	player.volume_db = -40.0
	add_child(player)
	return player

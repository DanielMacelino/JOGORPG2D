extends Node

var boss_stream: AudioStreamMP3
var menu_stream: AudioStreamMP3
var match_stream: AudioStreamMP3
const MATCH_VOLUME_DB := -15.0
var click_stream: AudioStreamMP3

var music_fade: Tween
var music_player: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var feedback_streams: Dictionary = {}
var feedback_times: Dictionary = {}

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.bus = "Music"
	add_child(music_player)
	for index in 8:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.bus = "SFX"
		add_child(player)
		effect_players.append(player)
	menu_stream = load("res://assets/audio/music/musicfundo.mp3") as AudioStreamMP3
	match_stream = load("res://assets/audio/music/music_match.mp3") as AudioStreamMP3
	if match_stream != null: match_stream.loop = true
	boss_stream = load("res://assets/audio/music/musicaboss.mp3") as AudioStreamMP3
	if boss_stream != null:
		boss_stream.loop = true
	click_stream = load("res://assets/audio/sfx/clickmine.mp3") as AudioStreamMP3
	if menu_stream != null:
		menu_stream.loop = true
	get_tree().node_added.connect(_wire_button)
	_wire_existing(get_tree().root)
	apply_settings()
	feedback_streams = {
		"kill": _tone([145.0], 0.095, 0.16, true),
		"xp": _tone([540.0], 0.075, 0.0),
		"level": _tone([440.0, 554.37, 659.25], 0.38, 0.0),
		"wave": _tone([220.0, 329.63], 0.30, 0.0),
		"boss": _tone([329.63, 440.0, 554.37, 659.25], 0.65, 0.0),
		"talent": _tone([392.0, 587.33], 0.24, 0.0),
		"socket": _tone([620.0, 830.0], 0.12, 0.0),
		"fusion_start": _tone([146.83, 220.0, 293.66, 440.0], 1.5, 0.08),
		"fusion_success": _tone([523.25, 659.25, 783.99, 1046.5], 0.75, 0.0),
		"fusion_fail": _tone([329.63, 293.66, 220.0], 0.5, 0.0),
	}

func _wire_existing(node: Node) -> void:
	_wire_button(node)
	for child in node.get_children():
		_wire_existing(child)

func _wire_button(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(play_click):
		node.pressed.connect(play_click)

func play_click() -> void:
	play_effect(click_stream, -8.0)

func menu_music(enabled: bool) -> void:
	if enabled:
		play_music(menu_stream)
	else:
		if music_fade != null:
			music_fade.kill()
			music_fade = null
		music_player.stop()

func boss_music(enabled: bool) -> void:
	if enabled:
		if boss_stream != null:
			play_music(boss_stream, 0.8)
	elif music_player.stream == boss_stream:
		menu_music(false)

func match_music(enabled: bool) -> void:
	if enabled:
		play_music(match_stream, 0.8, MATCH_VOLUME_DB)
	elif music_player.stream == match_stream:
		menu_music(false)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func apply_settings() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	_set_bus_volume("Master", float(settings.get("master", 0.8)))
	_set_bus_volume("Music", float(settings.get("music", 0.65)))
	_set_bus_volume("SFX", float(settings.get("effects", 0.85)))

func play_music(stream: AudioStream, fade_seconds: float = 0.5, target_db: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	if stream == null:
		return
	if music_fade != null:
		music_fade.kill()
		music_fade = null
	music_player.stream = stream
	music_player.volume_db = -36.0 if fade_seconds > 0.0 else target_db
	music_player.play()
	if fade_seconds > 0.0:
		if music_fade != null:
			music_fade.kill()
			music_fade = null
		music_fade = create_tween()
		music_fade.tween_property(music_player, "volume_db", target_db, fade_seconds)

func play_effect(stream: AudioStream, volume_db: float = 0.0) -> void:
	for player in effect_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return

func feedback(event: String) -> void:
	var now := Time.get_ticks_msec()
	var interval := 130 if event == "kill" else (170 if event == "xp" else 300)
	if now - int(feedback_times.get(event, -1000)) < interval:
		return
	var stream: AudioStream = feedback_streams.get(event)
	if stream == null:
		return
	feedback_times[event] = now
	play_effect(stream, -12.0 if event == "kill" else (-22.0 if event == "xp" else -9.0))

func stop_all() -> void:
	if is_instance_valid(music_player):
		if music_fade != null:
			music_fade.kill()
			music_fade = null
		music_player.stop()
		music_player.stream = null
	for player in effect_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _exit_tree() -> void:
	stop_all()
	feedback_streams.clear()
	boss_stream = null
	menu_stream = null
	match_stream = null
	click_stream = null

func _tone(notes: Array, duration: float, noise_amount: float, falling: bool = false) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := roundi(duration * sample_rate)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4271
	var filtered_noise := 0.0
	for index in count:
		var t := float(index) / sample_rate
		var segment := mini(notes.size() - 1, int(t / duration * notes.size()))
		var local_t := fmod(t, duration / notes.size())
		var frequency := float(notes[segment])
		if falling:
			frequency *= 1.0 - 0.58 * t / duration
		phase += TAU * frequency / sample_rate
		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1.0, 1.0), 0.28)
		var envelope := minf(1.0, local_t / 0.004) * exp(-local_t * (25.0 if falling else 12.0))
		envelope *= minf(1.0, (duration - t) / 0.012)
		var signal_value := (sin(phase) * 0.55 + sin(phase * 2) * 0.09 + filtered_noise * noise_amount) * envelope
		pcm.encode_s16(index * 2, clampi(roundi(signal_value * 24000.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = pcm
	return stream

func _set_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_mute(index, value <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))

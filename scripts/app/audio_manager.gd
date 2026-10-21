extends Node
## Small original synthesized wood/glass tones. No network, copyrighted samples
## or unmanaged per-scene players. Pool and music player live exactly once.
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var next_voice := 0
var tones: Array[AudioStreamWAV] = []

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for note in [0, 2, 4, 7, 9, 12, 14, 16]:
		tones.append(tone(261.63 * pow(2.0, float(note) / 12.0), 0.24))
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14
		add_child(voice)
		voices.append(voice)
	music = AudioStreamPlayer.new()
	music.volume_db = -26
	music.stream = melody()
	add_child(music)
	apply_settings()

func tone(frequency: float, duration: float) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var count := int(duration * wave.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / wave.mix_rate
		var envelope := minf(t / 0.006, 1.0) * exp(-t * 17.0) * minf((duration - t) / 0.02, 1.0)
		var sample := (sin(TAU * frequency * t) + 0.15 * sin(TAU * frequency * 2.0 * t)) * envelope * 0.55
		bytes.encode_s16(i * 2, int(sample * 32767))
	wave.data = bytes
	return wave

func melody() -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var count := 22050 * 16
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var notes := [0, 7, 4, 9, 7, 4, 2, 7, 0, 4, 9, 12, 9, 7, 4, 2]
	for i in range(count):
		var t := float(i) / 22050.0
		var phase := fmod(t, 1.0)
		var f := 261.63 * pow(2.0, float(notes[int(t)]) / 12.0)
		var env := minf(phase / 0.015, 1.0) * exp(-phase * 6.0)
		bytes.encode_s16(i * 2, int(sin(TAU * f * phase) * env * 6500.0))
	wave.data = bytes
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_begin = 0
	wave.loop_end = count
	return wave

func apply_settings() -> void:
	if not is_instance_valid(music):
		return
	# A headless rules runner has no audible output. Do not enqueue playback
	# into the dummy backend, whose asynchronous shutdown can retain streams.
	if DisplayServer.get_name() == "headless":
		return
	if Save.setting("music") and not music.playing:
		music.play()
	elif not Save.setting("music"):
		music.stop()
	if not Save.setting("sfx"):
		for voice in voices:
			voice.stop()

func play(note: int = 0) -> void:
	if DisplayServer.get_name() == "headless" or not Save.setting("sfx") or voices.is_empty():
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = tones[posmod(note, tones.size())]
	voice.play()

func suspend(value: bool) -> void:
	music.stream_paused = value
	for voice in voices:
		voice.stream_paused = value

extends SceneTree
## Measures the production audio bus using a real mixer, never the headless dummy backend.
var failures: Array[String] = []
var observations: Dictionary = {}
var capture: AudioEffectCapture
var sound: Node

func _initialize() -> void:
	call_deferred("run")

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + ceili(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		await process_frame

func measure(name: String, seconds: float = 0.32) -> Dictionary:
	capture.clear_buffer()
	await wait_real(seconds)
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	var energy := 0.0
	for sample in samples:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		energy += sample.length_squared()
	var stats := {"frames": samples.size(), "peak": peak, "rms": sqrt(energy / maxf(1, samples.size() * 2)), "clipped": peak >= 1.0}
	observations[name] = stats
	if samples.size() < 100:
		failures.append(name + ": no real mixer samples")
	return stats

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Audio output acceptance requires a real audio backend")
		quit(1)
		return
	var save := root.get_node("Save")
	save.folder = "user://qa-audio-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	sound = root.get_node("Sound")
	capture = AudioEffectCapture.new()
	capture.buffer_length = 2
	AudioServer.add_bus_effect(0, capture)
	save.data.settings.music = false
	save.data.settings.sfx = false
	sound.apply_settings()
	await wait_real(0.15)
	var muted := await measure("all_muted")
	expect(muted.peak < 0.000001, "muted bus must be silent")
	save.data.settings.sfx = true
	sound.apply_settings()
	for note in range(8):
		sound.play(note)
		var tone := await measure("tone_" + str(note))
		expect(tone.peak > 0.01 and tone.peak < 0.2 and not tone.clipped, "tone must be present and have headroom")
	for note in range(8):
		sound.play(note)
	var burst := await measure("eight_voice_burst")
	expect(burst.peak > 0.02 and burst.peak < 0.95, "full voice pool must not clip")
	save.data.settings.sfx = false
	sound.apply_settings()
	sound.play(3)
	await wait_real(0.1)
	var silent_sfx := await measure("sfx_disabled")
	expect(silent_sfx.peak < 0.000001, "SFX switch must suppress new and old voices")
	save.data.settings.music = true
	sound.apply_settings()
	var music := await measure("music_enabled", 1.2)
	expect(music.peak > 0.001 and music.peak < 0.05, "music must be present and quiet")
	sound.suspend(true)
	await wait_real(0.1)
	var paused := await measure("paused")
	expect(paused.peak < 0.000001, "pause must silence the mixer")
	sound.suspend(false)
	var resumed := await measure("resumed", 1.2)
	expect(resumed.peak > 0.001, "music must resume")
	save.data.settings.music = false
	sound.apply_settings()
	await wait_real(0.1)
	var music_off := await measure("music_disabled")
	expect(music_off.peak < 0.000001, "music switch must silence the mixer")
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "scope": "Actual Windows Godot mixer output captured through AudioEffectCapture; not a claim about phone speakers or subjective preference", "mix_rate": AudioServer.get_mix_rate(), "observations": observations, "failures": failures, "voice_count": sound.voices.size()}
	FileAccess.open("res://docs/evidence/audio-output.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	await sound.shutdown()
	quit(0 if failures.is_empty() else 1)

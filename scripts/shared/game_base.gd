class_name MochiGame
extends Node2D

signal score_changed(value: int)
signal ended(message: String)
signal toast_requested(message: String)

var game_id := ""
var score := 0
var area := Vector2(640, 780)
var rng := RandomNumberGenerator.new()
var effects_rng := RandomNumberGenerator.new()
var run_seed := 0
var stopped := false
var suspended := false
var pointer_id := -1
var font: Font
var reduced_motion := false
var particles: Array[Dictionary] = []
var game_time := 0.0

func setup(id: String, bounds: Vector2, game_font: Font, seed_value: int = -1) -> void:
	game_id = id
	area = bounds
	font = game_font
	run_seed = seed_value if seed_value >= 0 else int(Time.get_unix_time_from_system() * 1000.0) % 2147483647
	rng.seed = run_seed
	effects_rng.seed = run_seed ^ 0x4D4F4348
	reduced_motion = bool(Save.setting("reduced_motion"))

func add_score(value: int) -> void:
	score += value
	score_changed.emit(score)
	Save.record(game_id, score)

func finish(message: String) -> void:
	if stopped:
		return
	stopped = true
	cancel_pointer()
	Save.record(game_id, score)
	Save.clear_session(game_id)
	ended.emit(message)

func set_suspended(value: bool) -> void:
	suspended = value
	cancel_pointer()
	process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	set_process(not value)
	set_physics_process(not value)

func cancel_pointer() -> void:
	pointer_id = -1

func press(_point: Vector2) -> void:
	pass

func drag(_point: Vector2) -> void:
	pass

func release(_point: Vector2) -> void:
	pass

func action(_name: String) -> void:
	pass

func checkpoint() -> void:
	Save.record(game_id, score)

func text_at(text: String, point: Vector2, size_px: int = 28, color: Color = MochiPalette.INK, centered: bool = false) -> void:
	var offset := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x / 2.0 if centered else 0.0
	draw_string(font, point - Vector2(offset, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func rounded(rect: Rect2, color: Color, radius: int = 24, border: Color = Color.TRANSPARENT) -> void:
	draw_style_box(MochiPalette.box(color, radius, border), rect)

func burst(point: Vector2, color: Color, amount: int = 10) -> void:
	if reduced_motion:
		return
	for i in range(mini(amount, 64 - particles.size())):
		particles.append({"p": point, "v": Vector2(effects_rng.randf_range(-110, 110), effects_rng.randf_range(-150, -40)), "life": 0.55, "c": color})

func step_effects(delta: float) -> void:
	game_time += delta
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= delta
		particles[i].v.y += delta * 330
		particles[i].p += particles[i].v * delta
		if particles[i].life <= 0:
			particles.remove_at(i)

func draw_effects() -> void:
	for particle in particles:
		var color: Color = particle.c
		color.a = particle.life / 0.55
		draw_circle(particle.p, 4, color)

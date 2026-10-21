extends RigidBody2D

var level := 0
var number := 0
var age := 0.0
var texture: Texture2D
var radius := 22.0
var consumed := false
var visual_scale := 1.0

func _ready() -> void:
	mass = 0.7 + radius / 35.0
	linear_damp = 0.5
	angular_damp = 1.5
	contact_monitor = true
	max_contacts_reported = 8
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var material := PhysicsMaterial.new()
	material.friction = 0.65
	material.bounce = 0.12
	physics_material_override = material
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	age += delta
	visual_scale = move_toward(visual_scale, 1.0, delta * 2)
	queue_redraw()

func _draw() -> void:
	if texture:
		var extent := radius * 2 * visual_scale
		var height := extent * texture.get_height() / texture.get_width()
		draw_texture_rect(texture, Rect2(-extent / 2, extent / 2 - height, extent, height), false)

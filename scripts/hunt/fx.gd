class_name Fx
extends Node3D
## Partículas de impacto e números de dano flutuantes.

var _box := BoxMesh.new()


func _ready() -> void:
	_box.size = Vector3.ONE * 0.12


func burst(pos: Vector3, color: Color, amount: int, speed := 6.0, up := 4.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(1, amount)
	p.lifetime = 0.6
	p.mesh = _box
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	p.material_override = m
	p.direction = Vector3.UP
	# Mais impulso vertical = leque mais fechado para cima.
	p.spread = clampf(100.0 - up * 8.0, 45.0, 90.0)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -14, 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func text(pos: Vector3, value: String, color := Color.WHITE, size := 64) -> void:
	var l := Label3D.new()
	l.text = value
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.9 * color.a)
	l.outline_size = 14
	l.font_size = size
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	l.position = pos + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.4, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)

class_name CameraRig
extends Node3D
## Câmera em terceira pessoa atrás do caçador (estilo Dauntless), com trava de mira na fera.

const DISTANCE := 7.0
const HEIGHT := 1.7
const PITCH_MIN := -1.0
const PITCH_MAX := 0.15

var yaw := 0.0
var pitch := -0.32
var locked := true
var target: Node3D
var lock_target: Node3D

var camera := Camera3D.new()
var _shake := 0.0


func _ready() -> void:
	camera.fov = 68.0
	camera.far = 400.0
	camera.position = Vector3(0, 0, DISTANCE)
	add_child(camera)
	camera.make_current()


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Arrastar o dedo/mouse gira a câmera; um giro forte para os lados solta a trava.
func look(delta: Vector2) -> void:
	yaw -= delta.x * 0.006
	pitch = clampf(pitch - delta.y * 0.004, PITCH_MIN, PITCH_MAX)
	if locked and absf(delta.x) > 6.0:
		locked = false


func snap_behind() -> void:
	if target:
		position = target.position + Vector3(0, HEIGHT, 0)


func tick(dt: float) -> void:
	if target == null:
		return
	var want := target.position + Vector3(0, HEIGHT, 0)
	position = position.lerp(want, 1.0 - exp(-14.0 * dt))

	var stick := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if stick.length() > 0.1:
		look(stick * 900.0 * dt)

	if locked and lock_target:
		var d := lock_target.position - target.position
		if Vector2(d.x, d.z).length() > 0.5:
			var want_yaw := atan2(-d.x, -d.z)
			yaw = lerp_angle(yaw, want_yaw, 1.0 - exp(-5.0 * dt))
			pitch = lerpf(pitch, -0.28, 1.0 - exp(-3.0 * dt))

	rotation = Vector3(pitch, yaw, 0)
	camera.position = Vector3(0, 0, DISTANCE)
	if _shake > 0.0:
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.5
		_shake = maxf(0.0, _shake - dt * 2.5)
	# Não deixa a câmera entrar no chão.
	var cam_y := camera.global_position.y
	if cam_y < 0.6:
		camera.position.y += 0.6 - cam_y

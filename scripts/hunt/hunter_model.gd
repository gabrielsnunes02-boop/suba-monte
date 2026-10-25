class_name HunterModel
extends Node3D
## Visual do caçador: personagem KayKit (CC0) com esqueleto e animações prontas.
## Toca o clipe certo para cada estado e ajusta a velocidade para caber no tempo do golpe.

const SCENE := preload("res://assets/personagens/kaykit/Knight.glb")
const SCALE := 0.95
## Acessórios do pacote que não usamos (o caçador luta com a espada de duas mãos).
const HIDDEN := ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword"]
const LOOPING := ["2H_Melee_Idle", "Running_A", "Idle"]

var anim: AnimationPlayer
var _current := ""
var _sword: MeshInstance3D
var _sword_mat: StandardMaterial3D


func setup(cape_color: Color, blade_color: Color) -> void:
	var knight := SCENE.instantiate()
	knight.scale = Vector3.ONE * SCALE
	add_child(knight)
	anim = knight.find_child("AnimationPlayer", true, false)
	for clip in LOOPING:
		if anim.has_animation(clip):
			anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var skeleton := knight.find_child("Skeleton3D", true, false)
	for n in HIDDEN:
		var node := skeleton.find_child(n, false, false) as Node3D
		if node:
			node.visible = false

	# Capa na cor do elemento da armadura.
	var cape := skeleton.find_child("Knight_Cape", false, false)
	if cape:
		for mi in cape.find_children("*", "MeshInstance3D", true, false):
			_tint(mi, cape_color)

	# Espada com brilho na cor do elemento da arma (usado no ataque carregado).
	var sword_node := skeleton.find_child("2H_Sword", false, false)
	if sword_node:
		var meshes := sword_node.find_children("*", "MeshInstance3D", true, false)
		if not meshes.is_empty():
			_sword = meshes[0]
			_sword_mat = _material_copy(_sword)
			_sword_mat.emission_enabled = true
			_sword_mat.emission = blade_color
			_sword_mat.emission_energy_multiplier = 0.0
	play("2H_Melee_Idle")


func set_blade_glow(energy: float) -> void:
	if _sword_mat:
		_sword_mat.emission_energy_multiplier = energy


func sword_position() -> Vector3:
	return _sword.global_position if _sword else global_position + Vector3(0, 1.2, 0)


func length_of(clip: String) -> float:
	return anim.get_animation(clip).length if anim.has_animation(clip) else 1.0


## Toca um clipe. `fit` > 0 ajusta a velocidade para o clipe durar `fit` segundos.
## `restart` recomeça mesmo se já estiver tocando (golpes seguidos do mesmo tipo).
func play(clip: String, fit := 0.0, restart := false, blend := 0.12, speed := 1.0) -> void:
	if not anim.has_animation(clip):
		return
	var s := speed
	if fit > 0.0:
		s = length_of(clip) / fit
	if clip == _current and not restart:
		anim.speed_scale = s
		return
	_current = clip
	anim.speed_scale = s
	anim.play(clip, blend)
	if restart:
		anim.seek(0.0, true)


## Congela o clipe atual numa fração do tempo (pose de preparo do golpe carregado).
func hold_at(clip: String, fraction: float) -> void:
	if not anim.has_animation(clip):
		return
	if _current != clip:
		_current = clip
		anim.play(clip, 0.1)
	anim.speed_scale = 0.0
	anim.seek(length_of(clip) * fraction, true)


## Continua o clipe a partir de uma fração, terminando em `fit` segundos.
func resume_from(clip: String, fraction: float, fit: float) -> void:
	if not anim.has_animation(clip):
		return
	_current = clip
	anim.play(clip, 0.05)
	anim.seek(length_of(clip) * fraction, true)
	anim.speed_scale = length_of(clip) * (1.0 - fraction) / fit


static func _material_copy(mi: MeshInstance3D) -> StandardMaterial3D:
	var src := mi.get_active_material(0)
	var m: StandardMaterial3D = src.duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
	mi.set_surface_override_material(0, m)
	return m


static func _tint(mi: MeshInstance3D, color: Color) -> void:
	var m := _material_copy(mi)
	m.albedo_color = color.lerp(Color.WHITE, 0.35)

class_name HunterModel
extends Node3D
## Visual do caçador. Dois modelos possíveis:
## - "cavaleiro": KayKit Knight (CC0), com as animações do próprio pacote;
## - "campones": Male_Peasant (esqueleto padrão do Unreal), com as animações da
##   Universal Animation Library da Quaternius (CC0).
## As animações passam de um esqueleto para outro pelo perfil humanoide da Godot (BoneMap
## nos arquivos .import). O jogador pede papéis ("idle", "light1"…) e cada personagem
## traduz para o seu clipe, ajustando a velocidade para caber no tempo do golpe.

const KNIGHT := preload("res://assets/personagens/kaykit/Knight.glb")
const PEASANT := preload("res://assets/personagens/peasant/Male_Peasant.gltf")
const SWORD := preload("res://assets/armas/kaykit/sword_2handed.gltf")
const UAL := preload("res://assets/animacoes/quaternius/UAL_Standard.glb")

## Papel → clipe, por personagem.
const ROLES := {
	"cavaleiro": {
		"idle": "2H_Melee_Idle", "run": "Running_A",
		"light0": "2H_Melee_Attack_Slice", "light1": "2H_Melee_Attack_Stab", "light2": "2H_Melee_Attack_Spin",
		"heavy": "2H_Melee_Attack_Chop", "dodge": "Dodge_Forward", "drink": "Use_Item", "hit": "Hit_A", "death": "Death_A",
	},
	"campones": {
		"idle": "Sword_Idle", "run": "Jog_Fwd",
		"light0": "Sword_Attack", "light1": "Sword_Attack", "light2": "Sword_Attack",
		"heavy": "Sword_Attack", "dodge": "Roll", "drink": "Interact", "hit": "Hit_Chest", "death": "Death01",
	},
}

## Acessórios do Knight que não usamos (o caçador luta com a espada de duas mãos).
const KNIGHT_HIDDEN := ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword"]
const LOOPING := ["2H_Melee_Idle", "Running_A", "Sword_Idle"]
## Encaixe da espada na mão do camponês (ajustado olhando o personagem segurando a arma).
const PEASANT_SWORD_OFFSET := Vector3(0.0, 0.09, 0.03)
const PEASANT_SWORD_ROTATION := Vector3(PI, 0.0, 0.0)
const PEASANT_SWORD_SCALE := 0.85

static var _libraries := {}

var anim: AnimationPlayer
var _roles: Dictionary
var _current := ""
var _sword: MeshInstance3D
var _sword_mat: StandardMaterial3D


## Biblioteca de animações de um pacote (carregada uma vez e compartilhada).
static func library(source: PackedScene) -> AnimationLibrary:
	if not _libraries.has(source):
		var node := source.instantiate()
		var ap: AnimationPlayer = node.find_child("AnimationPlayer", true, false)
		var lib: AnimationLibrary = ap.get_animation_library("").duplicate(true)
		node.free()
		for clip in LOOPING:
			if lib.has_animation(clip):
				lib.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		_libraries[source] = lib
	return _libraries[source]


func setup(character: String, cape_color: Color, blade_color: Color) -> void:
	var sword_node: Node
	_roles = ROLES.get(character, ROLES.cavaleiro)
	if character == "campones":
		var peasant := PEASANT.instantiate()
		peasant.scale = Vector3.ONE * 1.2
		add_child(peasant)
		anim = AnimationPlayer.new()
		peasant.add_child(anim)
		anim.root_node = NodePath("..")
		anim.add_animation_library("", library(UAL))
		var skeleton: Skeleton3D = peasant.find_child("GeneralSkeleton", true, false)
		var hand := BoneAttachment3D.new()
		skeleton.add_child(hand)
		hand.bone_name = "RightHand"
		var sword := SWORD.instantiate()
		sword.position = PEASANT_SWORD_OFFSET
		sword.rotation = PEASANT_SWORD_ROTATION
		sword.scale = Vector3.ONE * PEASANT_SWORD_SCALE
		hand.add_child(sword)
		sword_node = sword
	else:
		var knight := KNIGHT.instantiate()
		knight.scale = Vector3.ONE * 0.95
		add_child(knight)
		anim = knight.find_child("AnimationPlayer", true, false)
		anim.remove_animation_library("")
		anim.add_animation_library("", library(KNIGHT))
		var skeleton := knight.find_child("GeneralSkeleton", true, false)
		for n in KNIGHT_HIDDEN:
			var node := skeleton.find_child(n, false, false) as Node3D
			if node:
				node.visible = false
		# Capa na cor do elemento da armadura.
		var cape := skeleton.find_child("Knight_Cape", false, false)
		if cape:
			for mi in cape.find_children("*", "MeshInstance3D", true, false):
				_tint(mi, cape_color)
		sword_node = skeleton.find_child("2H_Sword", false, false)

	# Espada com brilho na cor do elemento da arma (usado no ataque carregado).
	if sword_node:
		var meshes := sword_node.find_children("*", "MeshInstance3D", true, false)
		if sword_node is MeshInstance3D:
			meshes.push_front(sword_node)
		if not meshes.is_empty():
			_sword = meshes[0]
			_sword_mat = _material_copy(_sword)
			_sword_mat.emission_enabled = true
			_sword_mat.emission = blade_color
			_sword_mat.emission_energy_multiplier = 0.0
	play("idle")


func set_blade_glow(energy: float) -> void:
	if _sword_mat:
		_sword_mat.emission_energy_multiplier = energy


func sword_position() -> Vector3:
	return _sword.global_position if _sword else global_position + Vector3(0, 1.2, 0)


func length_of(clip: String) -> float:
	return anim.get_animation(clip).length if anim.has_animation(clip) else 1.0


func _clip(role: String) -> String:
	return _roles.get(role, role)


## Toca o clipe de um papel. `fit` > 0 ajusta a velocidade para o clipe durar `fit` segundos.
## `restart` recomeça mesmo se já estiver tocando (golpes seguidos do mesmo tipo).
func play(role: String, fit := 0.0, restart := false, blend := 0.12, speed := 1.0) -> void:
	var clip := _clip(role)
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
func hold_at(role: String, fraction: float) -> void:
	var clip := _clip(role)
	if not anim.has_animation(clip):
		return
	if _current != clip:
		_current = clip
		anim.play(clip, 0.1)
	anim.speed_scale = 0.0
	anim.seek(length_of(clip) * fraction, true)


## Continua o clipe a partir de uma fração, terminando em `fit` segundos.
func resume_from(role: String, fraction: float, fit: float) -> void:
	var clip := _clip(role)
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

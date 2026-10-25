class_name HunterModel
extends Node3D
## Visual do caçador: personagem modular (esqueleto padrão do Unreal) animado com a
## Universal Animation Library da Quaternius (CC0). Cada visual é um conjunto de peças
## (cabeça, tronco, braços…) que compartilham o mesmo esqueleto. As animações passam de um esqueleto
## para o outro pelo perfil humanoide da Godot (BoneMap nos arquivos .import).
## O jogador pede papéis ("idle", "light1"…), traduzidos aqui para clipes, com a velocidade
## ajustada para caber no tempo do golpe.

const PARTS_DIR := "res://assets/personagens/humano/%s.gltf"
## Visual → peças. A primeira peça fornece o esqueleto; as outras são encaixadas nele.
const OUTFITS := {
	"ranger": ["Male_Ranger_Body", "Male_Ranger_Arms", "Male_Ranger_Legs", "Male_Ranger_Feet_Boots",
		"Male_Ranger_Head_Hood", "Male_Ranger_Acc_Pauldron"],
	"campones": ["Male_Peasant"],
}
const SWORD := preload("res://assets/armas/kaykit/sword_2handed.gltf")
const UAL := preload("res://assets/animacoes/quaternius/UAL_Standard.glb")

## Papel → clipe da UAL.
const ROLES := {
	"idle": "Sword_Idle", "run": "Jog_Fwd",
	"light0": "Sword_Attack", "light1": "Sword_Attack", "light2": "Sword_Attack",
	"heavy": "Sword_Attack", "dodge": "Roll", "drink": "Interact", "hit": "Hit_Chest", "death": "Death01",
}
## Clipes que a UAL não marca como repetição, mas que precisam repetir.
const LOOPING := ["Sword_Idle"]
const SCALE := 1.2
## Encaixe da espada na mão direita (ajustado olhando o personagem em guarda).
const SWORD_OFFSET := Vector3(0.0, 0.09, 0.03)
const SWORD_ROTATION := Vector3(PI, 0.0, 0.0)
const SWORD_SCALE := 0.85

static var _library: AnimationLibrary

var anim: AnimationPlayer
var _current := ""
var _sword: MeshInstance3D
var _sword_mat: StandardMaterial3D


## Biblioteca de animações da UAL (carregada uma vez e compartilhada).
static func library() -> AnimationLibrary:
	if _library == null:
		var node := UAL.instantiate()
		var ap: AnimationPlayer = node.find_child("AnimationPlayer", true, false)
		_library = ap.get_animation_library("").duplicate(true)
		node.free()
		for clip in LOOPING:
			if _library.has_animation(clip):
				_library.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	return _library


func setup(outfit: String, blade_color: Color) -> void:
	var parts: Array = OUTFITS.get(outfit, OUTFITS.ranger)
	var body: Node3D = load(PARTS_DIR % parts[0]).instantiate()
	body.scale = Vector3.ONE * SCALE
	add_child(body)
	anim = AnimationPlayer.new()
	body.add_child(anim)
	anim.root_node = NodePath("..")
	anim.add_animation_library("", library())

	var skeleton: Skeleton3D = body.find_child("GeneralSkeleton", true, false)
	for i in range(1, parts.size()):
		_attach_part(PARTS_DIR % parts[i], skeleton)
	var hand := BoneAttachment3D.new()
	skeleton.add_child(hand)
	hand.bone_name = "RightHand"
	var sword := SWORD.instantiate()
	sword.position = SWORD_OFFSET
	sword.rotation = SWORD_ROTATION
	sword.scale = Vector3.ONE * SWORD_SCALE
	hand.add_child(sword)

	# Espada com brilho na cor do elemento da arma (usado no ataque carregado).
	var meshes := sword.find_children("*", "MeshInstance3D", true, false)
	if sword is MeshInstance3D:
		meshes.push_front(sword)
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


## Toca o clipe de um papel. `fit` > 0 ajusta a velocidade para o clipe durar `fit` segundos.
## `restart` recomeça mesmo se já estiver tocando (golpes seguidos do mesmo tipo).
func play(role: String, fit := 0.0, restart := false, blend := 0.12, speed := 1.0) -> void:
	var clip: String = ROLES.get(role, role)
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


## Congela o clipe de um papel numa fração do tempo (pose de preparo do golpe carregado).
func hold_at(role: String, fraction: float) -> void:
	var clip: String = ROLES.get(role, role)
	if not anim.has_animation(clip):
		return
	if _current != clip:
		_current = clip
		anim.play(clip, 0.1)
	anim.speed_scale = 0.0
	anim.seek(length_of(clip) * fraction, true)


## Continua o clipe de um papel a partir de uma fração, terminando em `fit` segundos.
func resume_from(role: String, fraction: float, fit: float) -> void:
	var clip: String = ROLES.get(role, role)
	if not anim.has_animation(clip):
		return
	_current = clip
	anim.play(clip, 0.05)
	anim.seek(length_of(clip) * fraction, true)
	anim.speed_scale = length_of(clip) * (1.0 - fraction) / fit


## Move as malhas de uma peça para o esqueleto principal (os ossos têm os mesmos nomes).
static func _attach_part(path: String, skeleton: Skeleton3D) -> void:
	var part: Node = load(path).instantiate()
	for mi in part.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.get_parent().remove_child(m)
		skeleton.add_child(m)
		m.skeleton = NodePath("..")
	part.free()


static func _material_copy(mi: MeshInstance3D) -> StandardMaterial3D:
	var src := mi.get_active_material(0)
	var m: StandardMaterial3D = src.duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
	mi.set_surface_override_material(0, m)
	return m

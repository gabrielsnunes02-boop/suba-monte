class_name BeastModel
extends Node3D
## Modelo animado de uma fera (glTF com esqueleto, ex.: dinossauros da Quaternius, CC0).
## Ajusta o tamanho ao `comprimento` da fera, pinta com as cores dela e controla as animações
## à mão (avanço manual), para poder segurar um golpe no preparo e cortar a cauda.

const DIR := "res://assets/feras/quaternius/%s.glb"
const LOOPING := ["Idle", "Walk", "Run"]

static var _bounds := {}
static var _shader: Shader

var skeleton: Skeleton3D
var player: AnimationPlayer
var head: BoneAttachment3D
var anchors := {}
var material: ShaderMaterial
var _tail_bone := -1
var _tail_cut := false
var _current := ""


func setup(def: Dictionary) -> void:
	var file: String = def.modelo
	var scene: Node3D = load(DIR % file).instantiate()
	add_child(scene)
	var v: Dictionary = def.visual
	var b: Dictionary = _measure(file, scene)
	var s: float = v.comprimento / b.size.z
	scene.scale = Vector3.ONE * s
	scene.position = Vector3(0, -b.lo.y * s, -(b.lo.z + b.hi.z) * 0.5 * s)

	skeleton = scene.find_children("*", "Skeleton3D", true, false)[0]
	player = scene.find_children("*", "AnimationPlayer", true, false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for a in LOOPING:
		player.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	_tail_bone = skeleton.find_bone("Tail1")

	material = _make_material(v, s)
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = material

	head = _attach("Head")
	anchors = {"cabeca": head, "costas": _attach("Torso"), "cauda": _attach("Tail3")}
	play("Idle")


func _attach(bone: String) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	return ba


## Caixa do modelo já deformado pela pose inicial do Idle (os arquivos vêm com escalas
## estranhas no esqueleto, então a caixa da malha parada não serve). Guardada por arquivo.
static func _measure(file: String, scene: Node3D) -> Dictionary:
	if _bounds.has(file):
		return _bounds[file]
	var ap: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play("Idle")
	ap.advance(0.0)
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var sk: Skeleton3D = mi.get_node(mi.skeleton)
		var rel := Transform3D.IDENTITY
		var n: Node = sk
		while n != scene:
			rel = (n as Node3D).transform * rel
			n = n.get_parent()
		var mats := []
		for k in mi.skin.get_bind_count():
			var bone := mi.skin.get_bind_bone(k)
			if bone < 0:
				bone = sk.find_bone(mi.skin.get_bind_name(k))
			mats.append(rel * sk.get_bone_global_pose(bone) * mi.skin.get_bind_pose(k))
		var arr := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / verts.size()
		for i in verts.size():
			var p := Vector3.ZERO
			for k in per:
				var w := weights[i * per + k]
				if w > 0.0:
					p += (mats[bones[i * per + k]] * verts[i]) * w
			lo = lo.min(p)
			hi = hi.max(p)
	_bounds[file] = {"lo": lo, "hi": hi, "size": hi - lo}
	return _bounds[file]


## As cores dos vértices do modelo separam couro (escuro) e detalhes (barriga, placas, garras,
## em vermelho): o shader troca cada um pela cor da fera e aplica uma textura de couro pintada.
func _make_material(v: Dictionary, model_scale: float) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		var lighting := "vertex_lighting, " if Settings.preset().vertice else ""
		_shader.code = """
shader_type spatial;
render_mode %sdiffuse_lambert, specular_disabled;
uniform vec3 cor_corpo : source_color;
uniform vec3 cor_detalhe : source_color;
uniform vec4 brilho : source_color = vec4(0.0);
uniform sampler2D couro : source_color, filter_linear_mipmap, repeat_enable;
uniform float escala_couro = 1.0;
varying vec3 pos;
varying vec3 nrm;
void vertex() {
	pos = VERTEX * escala_couro;
	nrm = abs(NORMAL);
}
void fragment() {
	vec3 vc = COLOR.rgb;
	float detalhe = smoothstep(0.04, 0.18, vc.r - max(vc.g, vc.b));
	float lum = dot(vc, vec3(0.3, 0.5, 0.2));
	vec3 w = nrm / (nrm.x + nrm.y + nrm.z);
	vec3 tex = texture(couro, pos.yz).rgb * w.x + texture(couro, pos.xz).rgb * w.y + texture(couro, pos.xy).rgb * w.z;
	vec3 base = mix(cor_corpo, cor_detalhe, detalhe) * (0.75 + lum * 1.5);
	ALBEDO = base * (0.45 + tex * 1.1);
	EMISSION = brilho.rgb * brilho.a;
}
""" % lighting
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("cor_corpo", Color(v.cor_corpo))
	m.set_shader_parameter("cor_detalhe", Color(v.cor_detalhe))
	m.set_shader_parameter("couro", load(Terrain.TEX_DIR % "rocha"))
	# A textura se repete a cada ~1,5 m na fera, qualquer que seja a escala do arquivo.
	m.set_shader_parameter("escala_couro", model_scale / 1.5)
	return m


func set_glow(color: Color, energy: float) -> void:
	material.set_shader_parameter("brilho", Color(color.r, color.g, color.b, energy))


## Toca uma animação (sem reiniciar se já está tocando, a menos que `restart`).
func play(anim: String, speed := 1.0, blend := 0.15, restart := false) -> void:
	if anim != _current or restart:
		player.play(anim, blend)
		_current = anim
	player.speed_scale = speed


## Posiciona a animação numa fração da duração (para segurar o preparo de um golpe).
func seek_fraction(anim: String, fraction: float) -> void:
	play(anim, 0.0, 0.1)
	player.seek(player.current_animation_length * clampf(fraction, 0.0, 1.0), true)


func current() -> String:
	return _current


func tick(dt: float) -> void:
	player.advance(dt)
	if _tail_cut and _tail_bone >= 0:
		skeleton.set_bone_pose_scale(_tail_bone, Vector3.ZERO)


## Esconde a cauda no modelo e devolve um pedaço solto para cair no chão.
func cut_tail(v: Dictionary) -> Node3D:
	var at := (anchors.cauda as Node3D).global_position
	_tail_cut = true
	var piece := Node3D.new()
	var mesh := Models.cylinder(0.0, v.largura * 0.3, v.comprimento * 0.4, 7)
	var mi := Models.add_mesh(piece, mesh, Models.mat(Color(v.cor_corpo)), Vector3.ZERO, Vector3.ONE, Vector3(PI / 2, 0, 0))
	mi.position = Vector3(0, 0, -v.comprimento * 0.1)
	piece.position = at
	piece.rotation.y = global_rotation.y
	return piece

class_name Models
extends RefCounted
## Modelos 3D procedurais estilizados (sem assets externos). Tudo voltado para +Z.

const ARENA_RADIUS := 30.0

static var _grass_shader: Shader


static func mat(color: Color, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.85
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	# Emissão sempre ligada para permitir flash de dano e brilho de preparo.
	m.emission_enabled = true
	m.emission = emission
	m.emission_energy_multiplier = energy
	return m


static func unshaded(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m


static func add_mesh(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO,
		scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func sphere(r := 1.0, seg := 12, rings := 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = rings
	return s


static func cylinder(top: float, bottom: float, h: float, seg := 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func cone(r: float, h: float, seg := 6) -> CylinderMesh:
	return cylinder(0.0, r, h, seg)


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c


# ------------------------------------------------------------ caçador

## Retorna {root, body, arm, blade_mat, legs:[pivô, pivô]}
static func build_player(armor_color: Color, blade_color: Color) -> Dictionary:
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var armor := mat(armor_color)
	var trim := mat(armor_color.darkened(0.45))
	var skin := mat(Color("#e9b88a"))
	var dark := mat(Color("#2b2b38"))

	add_mesh(body, capsule(0.42, 1.25), armor, Vector3(0, 1.2, 0))
	add_mesh(body, box(Vector3(0.95, 0.22, 0.55)), trim, Vector3(0, 1.62, 0))  # ombreiras
	add_mesh(body, sphere(0.3), skin, Vector3(0, 2.02, 0.02))
	add_mesh(body, sphere(0.34, 10, 6), trim, Vector3(0, 2.1, -0.06), Vector3(1, 0.8, 1))  # capuz
	add_mesh(body, box(Vector3(0.7, 0.12, 0.5)), dark, Vector3(0, 0.95, 0))  # cinto
	add_mesh(body, box(Vector3(0.55, 0.75, 0.08)), trim, Vector3(0, 1.15, -0.4), Vector3.ONE, Vector3(-0.15, 0, 0))  # capa

	var legs: Array[Node3D] = []
	for side in [-1, 1]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.18 * side, 0.7, 0)
		add_mesh(pivot, cylinder(0.13, 0.11, 0.7, 6), dark, Vector3(0, -0.35, 0))
		add_mesh(pivot, box(Vector3(0.2, 0.12, 0.32)), trim, Vector3(0, -0.68, 0.06))
		body.add_child(pivot)
		legs.append(pivot)

	var arm := Node3D.new()
	arm.position = Vector3(0.5, 1.5, 0.05)
	add_mesh(arm, cylinder(0.1, 0.09, 0.55, 6), armor, Vector3(0, 0, 0.25), Vector3.ONE, Vector3(PI / 2, 0, 0))
	var blade_mat := mat(blade_color, blade_color, 0.4)
	add_mesh(arm, box(Vector3(0.1, 0.22, 1.9)), blade_mat, Vector3(0, 0, 1.45))
	add_mesh(arm, box(Vector3(0.45, 0.09, 0.1)), dark, Vector3(0, 0, 0.5))
	body.add_child(arm)

	return {"root": root, "body": body, "arm": arm, "blade_mat": blade_mat, "legs": legs}


# ------------------------------------------------------------ feras

## Retorna {pose, head, tail_root, tail_segments, legs, spikes, eyes_mat, body_mats, part_mats, anchors}
static func build_beast(def: Dictionary, root: Node3D) -> Dictionary:
	var v: Dictionary = def.visual
	var L: float = v.comprimento
	var H: float = v.altura
	var W: float = v.largura
	var leg_h: float = v.pernas
	var pose := Node3D.new()
	root.add_child(pose)

	var body_mat := mat(Color(v.cor_corpo))
	var detail_mat := mat(Color(v.cor_detalhe))
	var part_mats := {
		"cabeca": mat(Color(v.cor_corpo)),
		"costas": mat(Color(v.cor_detalhe)),
		"cauda": mat(Color(v.cor_corpo)),
	}
	var body_y := leg_h + H / 2.0

	add_mesh(pose, sphere(1.0, 14, 9), body_mat, Vector3(0, body_y, 0), Vector3(W / 2, H / 2, L / 2))
	add_mesh(pose, sphere(1.0, 12, 7), detail_mat, Vector3(0, body_y - H * 0.22, 0.1), Vector3(W * 0.42, H * 0.32, L * 0.4))

	# Cabeça
	var head := Node3D.new()
	head.position = Vector3(0, body_y + H * 0.15, L / 2.0)
	add_mesh(head, sphere(1.0, 12, 8), part_mats.cabeca, Vector3(0, 0, 0.25), Vector3(W * 0.36, H * 0.36, maxf(0.6, L * 0.16)))
	add_mesh(head, box(Vector3(W * 0.42, H * 0.26, L * 0.2)), part_mats.cabeca, Vector3(0, -H * 0.08, 0.35 + L * 0.14))
	var eyes_mat := unshaded(Color(v.cor_olhos))
	for s in [-1, 1]:
		add_mesh(head, sphere(0.09, 6, 4), eyes_mat, Vector3(s * W * 0.24, H * 0.12, 0.45 + L * 0.06))
	if v.espinhos != "placas":
		for s in [-1, 1]:
			add_mesh(head, cone(0.16, 0.55, 4), detail_mat, Vector3(s * W * 0.22, H * 0.42, 0.1), Vector3.ONE, Vector3(0, 0, -s * 0.3))
	pose.add_child(head)

	# Costas
	var back := Node3D.new()
	back.position = Vector3(0, body_y + H * 0.42, 0)
	var spikes: Array[MeshInstance3D] = []
	var n := int(round(L * 1.6))
	for i in n:
		var t := 0.5 if n == 1 else float(i) / (n - 1)
		var z := (t - 0.5) * L * 0.75
		var h := cos((t - 0.5) * PI) * H * 0.12
		var m: MeshInstance3D
		if v.espinhos == "chamas":
			m = add_mesh(back, cone(0.2, 0.8 + sin(t * PI) * 0.6, 5), mat(Color("#ff9a3c"), Color("#ff4a12"), 1.4), Vector3(0, h + 0.3, z))
		elif v.espinhos == "placas":
			m = add_mesh(back, box(Vector3(W * 0.9, 0.22, L / n)), part_mats.costas, Vector3(0, h - 0.05, z), Vector3.ONE, Vector3((t - 0.5) * 0.9, 0, 0))
		else:
			m = add_mesh(back, cone(0.16, 0.5, 3), part_mats.costas, Vector3(0, h + 0.25, z))
		spikes.append(m)
	pose.add_child(back)

	# Cauda
	var tail_root := Node3D.new()
	tail_root.position = Vector3(0, body_y + H * 0.1, -L / 2.0 + 0.2)
	var segs: Array[Node3D] = []
	var parent: Node3D = tail_root
	var seg_len := L * 0.17
	var count: int = v.cauda_segmentos
	for i in count:
		var seg := Node3D.new()
		seg.position = Vector3(0, 0, 0.0 if i == 0 else -seg_len)
		var r := maxf(0.12, W * 0.28 * (1.0 - float(i) / (count + 1)))
		add_mesh(seg, sphere(1.0, 8, 6), part_mats.cauda, Vector3(0, 0, -seg_len / 2), Vector3(r, r, seg_len * 0.65))
		if i == count - 1:
			if v.espinhos == "placas":
				add_mesh(seg, sphere(0.45, 6, 4), detail_mat, Vector3(0, 0, -seg_len))
			else:
				var tip_mat := mat(Color("#ff9a3c"), Color("#ff4a12"), 1.6) if v.espinhos == "chamas" else detail_mat
				add_mesh(seg, cone(0.22, 0.7, 5), tip_mat, Vector3(0, 0, -seg_len), Vector3.ONE, Vector3(-PI / 2, 0, 0))
		parent.add_child(seg)
		segs.append(seg)
		parent = seg
	pose.add_child(tail_root)

	# Pernas
	var legs: Array[Node3D] = []
	for sz in [1, -1]:
		for sx in [-1, 1]:
			var pivot := Node3D.new()
			pivot.position = Vector3(sx * W * 0.36, leg_h + 0.1, sz * L * 0.28)
			add_mesh(pivot, cylinder(0.24, 0.18, leg_h + 0.2, 7), body_mat, Vector3(0, -(leg_h + 0.2) / 2, 0))
			add_mesh(pivot, box(Vector3(0.42, 0.16, 0.55)), detail_mat, Vector3(0, -leg_h - 0.05, 0.08))
			pose.add_child(pivot)
			legs.append(pivot)

	var anchors := {"cabeca": head, "costas": back, "cauda": segs[mini(2, segs.size() - 1)]}
	return {
		"pose": pose, "head": head, "tail_root": tail_root, "tail_segments": segs, "legs": legs,
		"spikes": spikes, "eyes_mat": eyes_mat,
		"body_mats": [body_mat, detail_mat, part_mats.cabeca, part_mats.costas, part_mats.cauda],
		"part_mats": part_mats, "anchors": anchors,
	}


# ------------------------------------------------------------ cenário

static func build_arena(parent: Node3D, biome: Dictionary, rng: RandomNumberGenerator) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(biome.ceu_topo)
	sky_mat.sky_horizon_color = Color(biome.ceu_horizonte)
	sky_mat.ground_horizon_color = Color(biome.ceu_horizonte)
	sky_mat.ground_bottom_color = Color(biome.ceu_topo).darkened(0.3)
	sky_mat.sun_angle_max = 30.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(biome.ceu_horizonte)
	e.fog_density = 0.004
	e.fog_sky_affect = 0.3
	e.glow_enabled = true
	e.glow_intensity = 0.4
	e.glow_bloom = 0.05
	env.environment = e
	parent.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff1d6")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	parent.add_child(sun)

	# Ilha flutuante
	var ground_mat := mat(Color(biome.chao))
	add_mesh(parent, cylinder(ARENA_RADIUS + 4, ARENA_RADIUS - 1, 2.0, 40), ground_mat, Vector3(0, -1.0, 0))
	add_mesh(parent, cone(ARENA_RADIUS - 1, 26.0, 12), mat(Color("#5a4a3c")), Vector3(0, -15.0, 0), Vector3.ONE, Vector3(PI, 0, 0))
	for i in 7:
		var a := rng.randf() * TAU
		add_mesh(parent, cone(3.0 + rng.randf() * 3.0, 10.0 + rng.randf() * 8.0, 6), mat(Color("#6b5847")),
			Vector3(cos(a) * (ARENA_RADIUS - 6), -6.0, sin(a) * (ARENA_RADIUS - 6)), Vector3.ONE, Vector3(PI, 0, 0))

	_build_grass(parent, Color(biome.grama), rng)

	# Lago decorativo (fora da área central)
	var water := add_mesh(parent, cylinder(6.0, 6.0, 0.05, 32), _water_mat(), Vector3(-17, 0.03, 9))
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Árvores e pedras na borda
	var trunk := mat(Color("#5b3b22"))
	var leaf := mat(Color(biome.arvore))
	var leaf2 := mat(Color(biome.arvore).lightened(0.15))
	var rock := mat(Color(biome.pedra))
	for i in 30:
		var a := rng.randf() * TAU
		var r := ARENA_RADIUS - 4 + rng.randf() * 6
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		if rng.randf() < 0.6:
			var tree := Node3D.new()
			tree.position = pos
			var h := 2.5 + rng.randf() * 2.5
			add_mesh(tree, cylinder(0.22, 0.38, h, 6), trunk, Vector3(0, h / 2, 0), Vector3.ONE, Vector3(0, 0, rng.randf_range(-0.15, 0.15)))
			add_mesh(tree, sphere(1.6 + rng.randf(), 8, 6), leaf, Vector3(0, h + 0.8, 0), Vector3(1.2, 0.8, 1.2))
			add_mesh(tree, sphere(1.0 + rng.randf() * 0.6, 8, 6), leaf2, Vector3(0.6, h + 1.5, 0.3), Vector3(1.1, 0.8, 1.1))
			parent.add_child(tree)
		else:
			add_mesh(parent, sphere(0.8 + rng.randf() * 1.4, 6, 4), rock, pos + Vector3(0, 0.2, 0),
				Vector3(1.0, 0.7, 1.2), Vector3(rng.randf(), rng.randf(), rng.randf()))

	# O Monte ao fundo
	var mountain := Node3D.new()
	add_mesh(mountain, cone(40.0, 75.0, 9), mat(Color("#7d7f95")), Vector3(0, 12, 0))
	add_mesh(mountain, cone(13.0, 25.0, 9), mat(Color("#f4f6ff")), Vector3(0, 37.5, 0))
	mountain.position = Vector3(-25, -25, -110)
	parent.add_child(mountain)

	# Ilhas distantes
	for i in 6:
		var a := rng.randf() * TAU
		var d := 70.0 + rng.randf() * 40.0
		var isle := Node3D.new()
		var s := 4.0 + rng.randf() * 6.0
		add_mesh(isle, cylinder(s, s * 0.8, 1.5, 10), mat(Color(biome.grama).darkened(0.1)), Vector3.ZERO)
		add_mesh(isle, cone(s * 0.8, s * 2.2, 8), mat(Color("#5a4a3c")), Vector3(0, -s * 1.1 - 0.7, 0), Vector3.ONE, Vector3(PI, 0, 0))
		isle.position = Vector3(cos(a) * d, rng.randf_range(-15.0, 10.0), sin(a) * d)
		parent.add_child(isle)


static func _water_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.6, 0.85, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic_specular = 0.8
	return m


static func _build_grass(parent: Node3D, color: Color, rng: RandomNumberGenerator) -> void:
	if _grass_shader == null:
		_grass_shader = Shader.new()
		_grass_shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;
uniform vec4 base_color : source_color;
uniform vec4 tip_color : source_color;
void vertex() {
	float h = clamp((VERTEX.y + 0.225) / 0.45, 0.0, 1.0);
	vec3 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	VERTEX.x += sin(TIME * 1.8 + world.x * 0.4 + world.z * 0.3) * 0.12 * h * h;
	COLOR = vec4(h);
}
void fragment() {
	ALBEDO = mix(base_color.rgb, tip_color.rgb, COLOR.r);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _grass_shader
	sm.set_shader_parameter("base_color", color.darkened(0.35))
	sm.set_shader_parameter("tip_color", color.lightened(0.15))

	var blade := PrismMesh.new()
	blade.size = Vector3(0.08, 0.45, 0.02)
	blade.left_to_right = 0.5
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	var total := 6000
	mm.instance_count = total
	for i in total:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * (ARENA_RADIUS + 2.0)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.7, 1.5))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(cos(a) * r, 0.2, sin(a) * r)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = sm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


static func build_gather_node(kind: String) -> Node3D:
	var g := Node3D.new()
	if kind == "minerio":
		add_mesh(g, sphere(0.55, 6, 4), mat(Color("#6b6b78")), Vector3(0, 0.3, 0), Vector3(1, 0.7, 1))
		for i in 3:
			add_mesh(g, sphere(0.2, 4, 2), mat(Color("#7fd6ff"), Color("#3aa8ff"), 1.5),
				Vector3((i - 1) * 0.3, 0.75, (i % 2) * 0.2), Vector3(1, 2.2, 1))
	else:
		for i in 5:
			add_mesh(g, cone(0.25, 1.0, 3), mat(Color("#7ad65a"), Color("#3f8f2a"), 0.4),
				Vector3(cos(i * 1.3) * 0.25, 0.5, sin(i * 1.3) * 0.25), Vector3.ONE, Vector3(cos(i) * 0.4, 0, sin(i) * 0.4))
	return g


## Indicador de ataque no chão: contorno + preenchimento que cresce até o golpe.
static func build_telegraph(tipo: String, raio: float, angulo: float, comprimento: float) -> Dictionary:
	var group := Node3D.new()
	var mesh: Mesh
	if tipo == "investida":
		var pm := PlaneMesh.new()
		pm.size = Vector2(raio * 2.0, comprimento)
		pm.center_offset = Vector3(0, 0, comprimento / 2.0)
		mesh = pm
	else:
		mesh = _sector_mesh(raio, 360.0 if tipo == "circulo" else angulo)
	var outline := add_mesh(group, mesh, _telegraph_mat(Color(1, 0.15, 0.15, 0.25)))
	var fill := add_mesh(group, mesh, _telegraph_mat(Color(1, 0.25, 0.1, 0.5)))
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fill.position.y = 0.01
	group.position.y = 0.08
	return {"group": group, "fill": fill}


static func _telegraph_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


## Leque no plano XZ centrado em +Z.
static func _sector_mesh(radius: float, angle_deg: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(minf(angle_deg, 360.0)) / 2.0
	var steps := maxi(8, int(angle_deg / 8.0))
	for i in steps:
		var a0 := -half + (2.0 * half) * float(i) / steps
		var a1 := -half + (2.0 * half) * float(i + 1) / steps
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a1), 0, cos(a1)) * radius)
		st.add_vertex(Vector3(sin(a0), 0, cos(a0)) * radius)
	return st.commit()

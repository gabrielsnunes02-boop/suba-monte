class_name Terrain
extends RefCounted
## Terreno no estilo dos jogos de PSP: texturas pintadas, luz "assada" nas cores dos vértices
## (calculada uma vez ao montar a arena) e materiais sem luz em tempo real, que são baratos.
## A arena é um vale fechado por paredões de rocha, com neblina escondendo o fundo.

const TEX_DIR := "res://assets/mundo/terreno/%s.png"
## Até onde vai o chão e onde começam os paredões.
const GROUND_EXTENT := Models.ARENA_RADIUS + 18.0
const CLIFF_RADIUS := Models.ARENA_RADIUS + 11.0
const BACK_RADIUS := Models.ARENA_RADIUS + 38.0
## Direção de onde vem o sol (à frente e à direita de quem começa olhando para a fera).
const SUN_DIR := Vector3(0.55, 0.62, -0.5)

static var _ground_shader: Shader
static var _rock_shader: Shader
static var _shaft_shader: Shader


## Altura do chão: plano na área da luta e subindo em direção aos paredões.
static func height(noise: FastNoiseLite, x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var rise := smoothstep(Models.ARENA_RADIUS - 1.0, CLIFF_RADIUS + 2.0, d)
	return rise * rise * 5.0 + noise.get_noise_2d(x, z) * 1.6 * rise


static func make_noise(seed_value: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = 0.06
	n.fractal_octaves = 3
	return n


## Monta chão, paredões e raios de sol. `trees` traz (x, raio da copa, z) de cada árvore, para
## as sombras pintadas no chão; `lake` é (x, z, raio) do lago.
static func build(parent: Node3D, biome: Dictionary, noise: FastNoiseLite, trees: Array, lake: Vector3,
		rng: RandomNumberGenerator) -> void:
	var light := Color(biome.luz)
	var shade := Color(biome.sombra)
	var ground := MeshInstance3D.new()
	ground.mesh = _ground_mesh(noise, trees, lake, rng)
	ground.material_override = _ground_material(biome, light, shade)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ground)

	var rock := _rock_material(biome, light, shade)
	for ring in [[CLIFF_RADIUS, 72, 16.0, 12.0, 9], [BACK_RADIUS, 44, 34.0, 20.0, 5]]:
		var cliff := MeshInstance3D.new()
		cliff.mesh = _cliff_mesh(noise, ring[0], ring[1], ring[2], ring[3], ring[4], rng)
		cliff.material_override = rock
		cliff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(cliff)

	_add_shafts(parent, Color(biome.raio), rng)


# ------------------------------------------------------------ chão

static func _ground_mesh(noise: FastNoiseLite, trees: Array, lake: Vector3, rng: RandomNumberGenerator) -> ArrayMesh:
	var cells := 72
	var step := GROUND_EXTENT * 2.0 / cells
	var path_phase := rng.randf() * TAU
	var patches := make_noise(rng.randi())
	patches.frequency = 0.045
	var dapple := make_noise(rng.randi())
	dapple.frequency = 0.09
	var sun := SUN_DIR.normalized()
	var shadow_dir := Vector2(-sun.x, -sun.z).normalized()

	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var heights := PackedFloat32Array()
	var row := cells + 1
	for j in row:
		for i in row:
			var x := -GROUND_EXTENT + i * step
			var z := -GROUND_EXTENT + j * step
			heights.append(height(noise, x, z))
	for j in row:
		for i in row:
			var x := -GROUND_EXTENT + i * step
			var z := -GROUND_EXTENT + j * step
			var h := heights[j * row + i]
			var hx := heights[j * row + mini(i + 1, cells)] - heights[j * row + maxi(i - 1, 0)]
			var hz := heights[mini(j + 1, cells) * row + i] - heights[maxi(j - 1, 0) * row + i]
			var normal := Vector3(-hx, 2.0 * step, -hz).normalized()
			var d := Vector2(x, z).length()

			# Terra: uma trilha sinuosa que atravessa o vale, manchas pisadas e a margem do lago.
			var path_x := sin(z * 0.07 + path_phase) * 7.0 + sin(z * 0.17) * 2.0
			var path := 1.0 - smoothstep(1.6, 4.2, absf(x - path_x))
			var patch := smoothstep(0.15, 0.45, patches.get_noise_2d(x, z))
			var lake_d := Vector2(x - lake.x, z - lake.y).length()
			var shore := 1.0 - smoothstep(lake.z - 0.5, lake.z + 2.5, lake_d)
			var slope := smoothstep(0.85, 0.65, normal.y)
			var dirt := clampf(maxf(maxf(path, patch * 0.85), maxf(shore, slope)), 0.0, 1.0)

			# Luz pintada: sol pela inclinação, sombras das árvores, pé dos paredões e manchas de sol.
			var lit := clampf(normal.dot(sun) * 0.6 + 0.45, 0.0, 1.0)
			for t: Vector3 in trees:
				var off := Vector2(x - t.x, z - t.z) - shadow_dir * 2.5
				lit *= 1.0 - 0.55 * exp(-off.length_squared() / (t.y * t.y))
			lit *= lerpf(1.0, 0.55, smoothstep(CLIFF_RADIUS - 6.0, CLIFF_RADIUS, d))
			lit = clampf(lit + maxf(dapple.get_noise_2d(x, z), 0.0) * 0.5, 0.0, 1.0)

			verts.append(Vector3(x, h, z))
			uvs.append(Vector2(x, z) * 0.22)
			colors.append(Color(dirt, lit, 0.0, 1.0))
	var idx := PackedInt32Array()
	for j in cells:
		for i in cells:
			var a := j * row + i
			idx.append_array([a, a + 1, a + row, a + 1, a + row + 1, a + row])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


static func _ground_material(biome: Dictionary, light: Color, shade: Color) -> ShaderMaterial:
	if _ground_shader == null:
		_ground_shader = Shader.new()
		_ground_shader.code = """
shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform sampler2D tex_grama : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_terra : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint_grama : source_color;
uniform vec3 tint_terra : source_color;
uniform vec3 luz : source_color;
uniform vec3 sombra : source_color;
void fragment() {
	vec4 g = texture(tex_grama, UV);
	vec4 t = texture(tex_terra, UV * 1.15);
	// Variação grande para esconder a repetição da textura.
	float macro = texture(tex_grama, UV * 0.13 + vec2(0.31, 0.17)).g;
	vec3 grama = g.rgb * tint_grama * (0.7 + macro * 1.1);
	// Borda irregular entre grama e terra, guiada pelas alturas pintadas das texturas.
	float m = clamp((COLOR.r - 0.5) * 4.0 + (t.a - g.a) * 1.5 + 0.5, 0.0, 1.0);
	vec3 c = mix(grama, t.rgb * tint_terra, m);
	ALBEDO = c * mix(sombra, luz, COLOR.g);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _ground_shader
	m.set_shader_parameter("tex_grama", load(TEX_DIR % "grama"))
	m.set_shader_parameter("tex_terra", load(TEX_DIR % "terra"))
	m.set_shader_parameter("tint_grama", Color(biome.tint_grama))
	m.set_shader_parameter("tint_terra", Color(biome.tint_terra))
	m.set_shader_parameter("luz", light)
	m.set_shader_parameter("sombra", shade)
	return m


# ------------------------------------------------------------ paredões

## Anel de rocha recortada em volta da arena, com musgo onde a pedra fica de frente para o céu.
static func _cliff_mesh(noise: FastNoiseLite, radius: float, segments: int, base_h: float, var_h: float,
		rows: int, rng: RandomNumberGenerator) -> ArrayMesh:
	var jag := make_noise(rng.randi())
	jag.frequency = 0.3
	jag.fractal_octaves = 2
	var tops := make_noise(rng.randi())
	tops.frequency = 0.9
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var u_turns := roundf(TAU * radius / 14.0)
	var bottom := -3.0
	var grid: Array[PackedVector3Array] = []
	for s in segments + 1:
		var a := float(s % segments) / segments * TAU
		var dir := Vector3(cos(a), 0, sin(a))
		var top := base_h + (tops.get_noise_1d(a * 3.0) * 0.5 + 0.5) * var_h
		var col := PackedVector3Array()
		for r in rows + 1:
			var f := float(r) / rows
			var y := lerpf(bottom, top, f)
			# Inclina para dentro no alto e recorta a silhueta com ruído.
			# Ruído esticado na vertical: forma colunas e saliências, como paredões de verdade.
			var rr := radius - f * f * 5.0 + jag.get_noise_2d(a * radius * 0.45, y * 0.12) * 5.0 \
				+ jag.get_noise_2d(a * radius * 1.3, y * 0.6) * 1.2
			col.append(dir * rr + Vector3(0, y, 0))
		grid.append(col)
	for s in segments:
		for r in rows:
			var quad := [grid[s][r], grid[s + 1][r], grid[s][r + 1], grid[s + 1][r + 1]]
			var us := [float(s) / segments * u_turns, float(s + 1) / segments * u_turns]
			var uv := [Vector2(us[0], quad[0].y / 14.0), Vector2(us[1], quad[1].y / 14.0),
				Vector2(us[0], quad[2].y / 14.0), Vector2(us[1], quad[3].y / 14.0)]
			for k in [0, 2, 1, 1, 2, 3]:
				st.set_uv(uv[k])
				st.add_vertex(quad[k])
	# Sem índice: cada face tem a própria normal e a luz assada fica facetada (pedra lascada).
	st.generate_normals()
	var arr := st.commit_to_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var colors := PackedColorArray()
	var sun := SUN_DIR.normalized()
	for k in verts.size():
		var n := normals[k]
		var v := verts[k]
		# Normais viradas para o centro da arena (a face que o jogador vê).
		var lit := clampf(n.dot(sun) * 0.8 + 0.55, 0.3, 1.0)
		lit *= lerpf(0.55, 1.0, smoothstep(bottom, bottom + 8.0, v.y))
		var moss := smoothstep(0.35, 0.75, n.y) + smoothstep(2.0, -1.0, v.y) * 0.8
		colors.append(Color(clampf(moss, 0.0, 1.0), lit, 0.0, 1.0))
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_NORMAL] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


static func _rock_material(biome: Dictionary, light: Color, shade: Color) -> ShaderMaterial:
	if _rock_shader == null:
		_rock_shader = Shader.new()
		_rock_shader.code = """
shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled;
uniform sampler2D tex_rocha : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_grama : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint_rocha : source_color;
uniform vec3 tint_grama : source_color;
uniform vec3 luz : source_color;
uniform vec3 sombra : source_color;
void fragment() {
	vec3 r = texture(tex_rocha, UV).rgb * tint_rocha;
	vec4 g = texture(tex_grama, UV * 2.0);
	float m = clamp((COLOR.r - 0.5) * 3.0 + (g.a - 0.5) * 1.5 + 0.5, 0.0, 1.0);
	vec3 c = mix(r, g.rgb * tint_grama * 0.85, m);
	ALBEDO = c * mix(sombra, luz, COLOR.g);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _rock_shader
	m.set_shader_parameter("tex_rocha", load(TEX_DIR % "rocha"))
	m.set_shader_parameter("tex_grama", load(TEX_DIR % "grama"))
	m.set_shader_parameter("tint_rocha", Color(biome.tint_rocha))
	m.set_shader_parameter("tint_grama", Color(biome.tint_grama))
	m.set_shader_parameter("luz", light)
	m.set_shader_parameter("sombra", shade)
	return m


# ------------------------------------------------------------ raios de sol

## Feixes de luz entre as árvores: planos cruzados somando cor, sem textura.
static func _add_shafts(parent: Node3D, color: Color, rng: RandomNumberGenerator) -> void:
	if _shaft_shader == null:
		_shaft_shader = Shader.new()
		_shaft_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 cor : source_color;
void fragment() {
	float across = sin(UV.x * 3.14159);
	float along = smoothstep(0.0, 0.45, UV.y) * smoothstep(1.0, 0.55, UV.y);
	ALBEDO = cor.rgb * across * across * across * along * cor.a;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _shaft_shader
	m.set_shader_parameter("cor", color)
	var quad := QuadMesh.new()
	quad.size = Vector2(7.0, 30.0)
	var sun := SUN_DIR.normalized()
	var side := sun.cross(Vector3.UP).normalized()
	var tilt := Basis(side, sun, side.cross(sun))
	for i in 4:
		var a := rng.randf() * TAU
		var r := rng.randf_range(Models.ARENA_RADIUS - 6.0, Models.ARENA_RADIUS + 6.0)
		var holder := Node3D.new()
		holder.position = Vector3(cos(a) * r, 0, sin(a) * r) + sun * 15.0
		# Deita o feixe na direção do sol e cruza dois planos para ter volume de qualquer ângulo.
		holder.basis = tilt
		for k in 2:
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			mi.material_override = m
			mi.rotation = Vector3(0, k * PI / 2.0, 0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(mi)
		holder.scale = Vector3.ONE * rng.randf_range(0.7, 1.3)
		parent.add_child(holder)

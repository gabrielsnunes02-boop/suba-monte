class_name MenuScene
extends SubViewportContainer
## Cena 3D atrás dos menus: a fera em destaque no menu principal (luz fria de recorte, como
## a arte do Dauntless) e o mapa de ilhas flutuantes na escolha da caçada.

var viewport := SubViewport.new()
var world := Node3D.new()
var camera := Camera3D.new()
var _mode := ""
var _content: Node3D
var _beast: BeastModel
var _pivot: Node3D
var _islands := {}
var _selected := ""
var _cam_target := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	# Em aparelhos fracos a cena 3D do menu é desenhada em meia resolução.
	stretch_shrink = 1 if Settings.preset().escala_3d >= 1.0 else 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(viewport)
	viewport.add_child(world)
	camera.fov = 50.0
	camera.far = 200.0
	world.add_child(camera)


func _clear() -> void:
	if _content:
		_content.queue_free()
	_content = Node3D.new()
	world.add_child(_content)
	_beast = null
	_islands = {}


func _environment(top: Color, horizon: Color, fog: Color, density: float) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = horizon
	sky_mat.ground_horizon_color = horizon
	sky_mat.ground_bottom_color = horizon.darkened(0.5)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = horizon
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.fog_enabled = true
	e.fog_light_color = fog
	e.fog_density = density
	e.fog_sky_affect = 0.4
	env.environment = e
	_content.add_child(env)


func _light(dir: Vector3, color: Color, energy: float) -> void:
	var l := DirectionalLight3D.new()
	l.light_color = color
	l.light_energy = energy
	_content.add_child(l)
	l.basis = Basis.looking_at(-dir.normalized())


# ------------------------------------------------------------ fera em destaque

func show_beast(beast_id: String) -> void:
	if _mode == "fera:" + beast_id:
		return
	_mode = "fera:" + beast_id
	_clear()
	camera.fov = 50.0
	var def := GameData.beast_by_id(beast_id)
	_environment(Color("#0a1a2c"), Color("#123a55"), Color("#0e2c44"), 0.02)
	# Luz principal fria pela frente e recorte turquesa por trás (silhueta brilhante).
	_light(Vector3(-0.6, 0.7, 0.8), Color("#cfe6ff"), 0.9)
	_light(Vector3(0.7, 0.4, -0.9), Color("#5ff0ff"), 1.6)
	_pivot = Node3D.new()
	_content.add_child(_pivot)
	_beast = BeastModel.new()
	_pivot.add_child(_beast)
	_beast.setup(def)
	_beast.play("Idle")
	# Chão escuro com um halo para "assentar" a fera.
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = Models.cylinder(1.0, 1.0, 0.05, 32)
	floor_mesh.material_override = Models.unshaded(Color("#0b2235"))
	floor_mesh.scale = Vector3(def.visual.comprimento * 0.9, 1, def.visual.comprimento * 0.9)
	_content.add_child(floor_mesh)
	var L: float = def.visual.comprimento
	var H: float = def.visual.altura
	_pivot.rotation.y = -0.9
	# A fera fica à direita da tela; os botões ocupam a esquerda.
	camera.h_offset = -L * 0.32
	_cam_target = Vector3(L * 0.15, H * 0.75, L * 1.05)
	_cam_look = Vector3(0, H * 0.5, 0)
	camera.look_at_from_position(_cam_target, _cam_look)


# ------------------------------------------------------------ mapa de ilhas

const ISLAND_POS := [Vector3(-11, 0, -4), Vector3(-2, 1.5, -9), Vector3(7, 0.5, -5), Vector3(-8, -0.5, 6),
	Vector3(2, 1, 4), Vector3(11, 2, 8)]


func show_map(selected: String, unlocked: Callable) -> void:
	if not _mode.begins_with("mapa"):
		_mode = "mapa"
		_clear()
		_environment(Color("#1d5b93"), Color("#5f9ccc"), Color("#4f8cc0"), 0.012)
		camera.fov = 38.0
		_light(Vector3(0.4, 1.0, 0.5), Color("#fff4e0"), 1.0)
		_build_clouds()
		for i in GameData.BEASTS.size():
			var b: Dictionary = GameData.BEASTS[i]
			var isle := _island(b, unlocked.call(b))
			isle.position = ISLAND_POS[i % ISLAND_POS.size()]
			_content.add_child(isle)
			_islands[b.id] = isle
		camera.h_offset = 2.5
		_selected = selected
		_aim()
		camera.look_at_from_position(_cam_target, _cam_look)
	_selected = selected
	_aim()


## Câmera do alto, puxada para a ilha escolhida (a lista e o painel cobrem as laterais).
func _aim() -> void:
	var p: Vector3 = ISLAND_POS[GameData.BEASTS.find(GameData.beast_by_id(_selected)) % ISLAND_POS.size()]
	_cam_look = p * 0.45
	_cam_target = _cam_look + Vector3(0, 30, 21)


func _island(b: Dictionary, open: bool) -> Node3D:
	var bio: Dictionary = b.bioma
	var isle := Node3D.new()
	var r: float = 1.7 + b.tier * 0.45
	var grass := StandardMaterial3D.new()
	grass.albedo_texture = load(Terrain.TEX_DIR % "grama")
	grass.albedo_color = Color(bio.tint_grama) if open else Color("#5a6470")
	grass.uv1_triplanar = true
	grass.uv1_scale = Vector3.ONE * 0.4
	var rock := StandardMaterial3D.new()
	rock.albedo_texture = load(Terrain.TEX_DIR % "rocha")
	rock.albedo_color = Color(bio.tint_rocha) if open else Color("#4a5058")
	rock.uv1_triplanar = true
	rock.uv1_scale = Vector3.ONE * 0.3
	Models.add_mesh(isle, Models.cylinder(r, r * 0.9, 0.6, 14), grass)
	Models.add_mesh(isle, Models.cylinder(r * 0.9, 0.2, r * 1.7, 9), rock, Vector3(0, -r * 0.85 - 0.3, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(b.id)
	var trees: Array = bio.arvores
	for k in 5:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.4, r - 0.5)
		var mi := MeshInstance3D.new()
		mi.mesh = Models.kit_mesh(trees[k % trees.size()], 0.12)
		mi.scale = Vector3.ONE * rng.randf_range(0.18, 0.3)
		mi.position = Vector3(cos(a) * d, 0.3, sin(a) * d)
		mi.rotation.y = rng.randf() * TAU
		isle.add_child(mi)
	var label := Label3D.new()
	label.text = b.nome if open else "%s\nRank %d" % [b.nome, b.rank_minimo]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.016
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color.WHITE if open else Color("#9aa4b0")
	label.position = Vector3(0, 2.6, 0)
	label.no_depth_test = true
	isle.add_child(label)
	isle.set_meta("base_y", 0.0)
	return isle


func _build_clouds() -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var mi := MeshInstance3D.new()
		mi.mesh = Models.sphere(1.0, 16, 8)
		mi.material_override = m
		mi.scale = Vector3(rng.randf_range(4, 8), rng.randf_range(0.6, 1.2), rng.randf_range(3, 6))
		mi.position = Vector3(rng.randf_range(-22, 22), rng.randf_range(-9, -6), rng.randf_range(-16, 16))
		_content.add_child(mi)


func _process(dt: float) -> void:
	_t += dt
	if _beast:
		_beast.tick(dt)
		_pivot.rotation.y += dt * 0.15
	for id in _islands:
		var isle: Node3D = _islands[id]
		var base: Vector3 = ISLAND_POS[GameData.BEASTS.find(GameData.beast_by_id(id)) % ISLAND_POS.size()]
		var lift := 1.2 if id == _selected else 0.0
		isle.position.y = lerpf(isle.position.y, base.y + lift + sin(_t * 1.3 + base.x) * 0.15, minf(1.0, dt * 4.0))
		isle.scale = isle.scale.lerp(Vector3.ONE * (1.15 if id == _selected else 1.0), minf(1.0, dt * 4.0))
	if _mode == "mapa":
		var t := minf(1.0, dt * 3.0)
		var pos := camera.global_position.lerp(_cam_target, t)
		var look := (camera.global_position - camera.global_basis.z * 10.0).lerp(_cam_look, t)
		camera.look_at_from_position(pos, look)

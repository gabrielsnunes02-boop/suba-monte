class_name Hunt
extends Node3D
## Uma caçada: ilha, caçador, fera, câmera, HUD e controles. Emite `finished` com o resultado.

signal finished(result: Dictionary)

var world := Node3D.new()
var fx := Fx.new()
var rng := RandomNumberGenerator.new()
var player := HunterPlayer.new()
var beast := Beast.new()
var camera_rig := CameraRig.new()
var hud := Hud.new()
var touch := TouchControls.new()
var weapon: Dictionary
var weapon_level: int
var armor: Dictionary
var armor_level: int

var _beast_def: Dictionary
var _nodes: Array[Dictionary] = []
var _gathered := {}
var _part_drops := {}
var _parts_broken := 0
var _faints := 0
var _elapsed := 0.0
var _ended := false
var _hitstop_until := 0
var _slow_until := 0
var _slow_scale := 1.0


func setup(profile: Dictionary, fera_id: String) -> void:
	_beast_def = GameData.beast_by_id(fera_id)
	weapon = GameData.GEAR[profile.equipado.arma]
	weapon_level = profile.equipamentos.get(profile.equipado.arma, 0)
	armor = GameData.GEAR[profile.equipado.armadura]
	armor_level = profile.equipamentos.get(profile.equipado.armadura, 0)
	rng.randomize()


func _ready() -> void:
	add_child(world)
	var deco_rng := RandomNumberGenerator.new()
	deco_rng.seed = hash(_beast_def.id)
	Models.build_arena(world, _beast_def.bioma, deco_rng)
	_spawn_nodes()
	world.add_child(fx)

	player.setup(self)
	player.position = Vector3(0, 0, 14)
	world.add_child(player)
	beast.setup(self, _beast_def)
	world.add_child(beast)

	camera_rig.target = player
	camera_rig.lock_target = beast
	camera_rig.yaw = 0.0
	world.add_child(camera_rig)
	camera_rig.snap_behind()

	hud.build(_beast_def, weapon, weapon_level)
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.pause_requested.connect(func(): _set_paused(true))
	hud.resume_requested.connect(func(): _set_paused(false))
	hud.quit_requested.connect(func():
		_set_paused(false)
		_finish(false))
	add_child(hud)

	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 0
	add_child(touch_layer)
	touch.camera_rig = camera_rig
	touch_layer.add_child(touch)
	touch.set_potions(player.potions)

	banner("Cace: %s" % _beast_def.nome)


func _process(dt: float) -> void:
	_update_time_scale()
	if _ended:
		return
	_elapsed += dt
	if Input.is_action_just_pressed("lock_on"):
		camera_rig.locked = not camera_rig.locked
		touch.queue_redraw()
	if Input.is_action_just_pressed("pause"):
		_set_paused(true)
	player.tick(dt)
	beast.tick(dt)
	camera_rig.tick(dt)
	_update_nodes()
	hud.refresh(dt, player, beast, _faints, _elapsed)
	touch.set_potions(player.potions)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_inside_tree() and not _ended:
			_set_paused(true)


# ------------------------------------------------------------ efeitos de tempo e câmera

func shake(amount: float) -> void:
	camera_rig.add_shake(amount)


func hitstop(seconds: float) -> void:
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + int(seconds * 1000.0))


func slowmo(seconds: float, scale_f: float) -> void:
	_slow_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	_slow_scale = scale_f


func _update_time_scale() -> void:
	var now := Time.get_ticks_msec()
	if now < _hitstop_until:
		Engine.time_scale = 0.05
	elif now < _slow_until:
		Engine.time_scale = _slow_scale
	else:
		Engine.time_scale = 1.0


func banner(text: String, color := Color.WHITE) -> void:
	hud.banner(text, color)


# ------------------------------------------------------------ eventos

## A fera tenta acertar o jogador. Retorna true se o golpe foi consumido (acertou ou foi esquivado).
func hit_player(raw: float, element: String, from: Vector3) -> bool:
	var r := player.take_hit(raw, element, from)
	if r == "esquivou" and player.state == HunterPlayer.State.ESQUIVA:
		slowmo(0.35, 0.3)
		fx.text(player.position + Vector3(0, 2.7, 0), "ESQUIVA PERFEITA", Color("#7dd3fc"), 60)
		if player.has_perk("esquiva_afiada"):
			player.sharp = true
	return r != "nada"


func on_player_down() -> void:
	_faints += 1
	if _faints >= GameData.PLAYER.desmaios_maximos:
		banner("A caçada falhou...", Color("#ff5a5a"))
		get_tree().create_timer(2.2, true, false, true).timeout.connect(func(): _finish(false))
		return
	banner("Você desmaiou! (%d/%d)" % [_faints, GameData.PLAYER.desmaios_maximos], Color("#ff5a5a"))
	get_tree().create_timer(2.5, true, false, true).timeout.connect(_respawn_player)


func _respawn_player() -> void:
	if _ended:
		return
	var away := (player.position - beast.position) * Vector3(1, 0, 1)
	if away.length_squared() < 0.01:
		away = Vector3.BACK
	player.respawn(away.normalized() * (Models.ARENA_RADIUS - 8.0))
	camera_rig.snap_behind()


func on_beast_dead() -> void:
	get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): _finish(true))


func on_part_broken(drop: String) -> void:
	_parts_broken += 1
	_part_drops[drop] = _part_drops.get(drop, 0) + 1


func _set_paused(on: bool) -> void:
	if _ended:
		return
	get_tree().paused = on
	hud.show_pause(on)
	touch.release_all()


# ------------------------------------------------------------ coleta

func _spawn_nodes() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in 10:
		var kind := "minerio" if i % 2 == 0 else "fibra"
		var a := float(i) / 10.0 * TAU + r.randf() * 0.4
		var d := 12.0 + r.randf() * (Models.ARENA_RADIUS - 16.0)
		var obj := Models.build_gather_node(kind)
		obj.position = Vector3(cos(a) * d, 0, sin(a) * d)
		world.add_child(obj)
		_nodes.append({"kind": kind, "obj": obj, "taken": false})


func _update_nodes() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for n in _nodes:
		var obj: Node3D = n.obj
		if n.taken:
			obj.scale *= 0.85
			continue
		obj.rotation.y = sin(t + obj.position.x) * 0.2
		if player.state != HunterPlayer.State.CAIDO and obj.position.distance_to(player.position) < 1.6:
			n.taken = true
			var qtd := 1 + rng.randi_range(0, 1)
			_gathered[n.kind] = _gathered.get(n.kind, 0) + qtd
			fx.text(obj.position + Vector3(0, 1.8, 0), "+%d %s" % [qtd, GameData.material_name(n.kind)], Color("#6ee7a0"), 48)
			fx.burst(obj.position + Vector3(0, 0.8, 0), Color("#7fd6ff") if n.kind == "minerio" else Color("#7ad65a"), 12, 3.0)


# ------------------------------------------------------------ fim

func _finish(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	Engine.time_scale = 1.0
	get_tree().paused = false
	touch.release_all()
	var loot := _gathered.duplicate()
	var moedas := 0
	var xp := 10
	if victory:
		loot = Formulas.merge_counts(Formulas.merge_counts(loot, Formulas.roll_loot(_beast_def.loot, rng)), _part_drops)
		moedas = rng.randi_range(_beast_def.moedas[0], _beast_def.moedas[1])
		xp = _beast_def.xp + _parts_broken * 10
	finished.emit({
		"fera_id": _beast_def.id,
		"vitoria": victory,
		"tempo": int(_elapsed),
		"partes_quebradas": _parts_broken,
		"loot": loot,
		"moedas": moedas,
		"xp": xp,
	})


func _exit_tree() -> void:
	Engine.time_scale = 1.0

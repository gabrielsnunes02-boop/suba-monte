class_name Beast
extends Node3D
## IA da fera: perseguir, preparar (com aviso no chão), atacar, recuperar, fúria, atordoamento e partes.

enum State { OCIOSO, PERSEGUIR, PREPARAR, ATACAR, RECUPERAR, RUGIR, ATORDOADO, MORTO }

const DASH_TIME := 0.9
const DASH_SPEED_MULT := 3.2
const FURY_HP := 0.4
const STUN_TIME := 3.5

var hunt: Hunt
var def: Dictionary
var facing := PI
var hp: float
var max_hp: float
var fury := false
var state := State.OCIOSO
## id → {def, dano, ferida, quebrada}
var parts := {}
var radius: float
var half_len: float

var _m: Dictionary
var _t := 0.0
var _think := 1.0
var _attack: Dictionary = {}
var _last_attack := ""
var _telegraph: Dictionary = {}
var _dash_dir := Vector3.ZERO
var _dash_speed := 0.0
var _dash_hit := false
var _stagger := 0.0
var _stagger_limit: float
var _walk_phase := 0.0
var _flash := 0.0
var _wander := Vector3.ZERO
var _dead_notified := false
var _roar_is_fury := false
var _severed_tail: Node3D
var _tail_vy := 0.0
## Modelo animado (quando a fera tem `modelo`); senão o corpo é procedural.
var _model: BeastModel
var _anim_state := -1


func setup(h: Hunt, d: Dictionary) -> void:
	hunt = h
	def = d
	position = Vector3(0, 0, -12)
	max_hp = d.vida
	hp = max_hp
	_stagger_limit = d.limite_atordoamento
	radius = d.visual.largura / 2.0 + 0.25
	half_len = d.visual.comprimento * 0.4
	for p in d.partes:
		parts[p.id] = {"def": p, "dano": 0.0, "ferida": false, "quebrada": false}
	if d.has("modelo"):
		var pose := Node3D.new()
		add_child(pose)
		_model = BeastModel.new()
		pose.add_child(_model)
		_model.setup(d)
		_m = {"pose": pose, "head": _model.head, "anchors": _model.anchors}
	else:
		_m = Models.build_beast(d, self)


func alive() -> bool:
	return state != State.MORTO


## Nome do ataque em preparo/execução, para o HUD.
func busy() -> String:
	if not _attack.is_empty() and (state == State.PREPARAR or state == State.ATACAR):
		return _attack.nome
	return ""


func tick(dt: float) -> void:
	_t += dt
	var player := hunt.player
	var fury_mul := 1.25 if fury else 1.0
	var to_p := (player.position - position) * Vector3(1, 0, 1)
	var dist := to_p.length()
	var angle_to_p := atan2(to_p.x, to_p.z)
	var diff := wrapf(angle_to_p - facing, -PI, PI)
	var moving := 0.0

	match state:
		State.OCIOSO:
			if _wander == Vector3.ZERO or position.distance_to(_wander) < 1.0:
				var a := hunt.rng.randf() * TAU
				_wander = Vector3(cos(a) * 10.0, 0, sin(a) * 10.0 - 6.0)
			var w := _wander - position
			_turn(atan2(w.x, w.z), dt, 1.5)
			_move_forward(def.velocidade * 0.35 * dt)
			moving = 0.35
			if dist < 15.0:
				_start_roar(false)

		State.PERSEGUIR:
			_turn(angle_to_p, dt, 2.6 * fury_mul)
			if dist > half_len + 2.2 and absf(diff) < 1.3:
				var sp: float = def.velocidade * fury_mul * maxf(0.3, cos(diff))
				_move_forward(sp * dt)
				moving = sp / def.velocidade
			_think -= dt
			if _think <= 0.0 and player.state != HunterPlayer.State.CAIDO:
				_think = 0.25 + hunt.rng.randf() * 0.35
				var a := _choose_attack(dist, diff)
				if not a.is_empty():
					_start_attack(a)

		State.PREPARAR:
			var wind: float = _attack.preparo * (0.8 if fury else 1.0)
			var p := minf(1.0, _t / wind)
			if p < 0.55:
				_turn(angle_to_p, dt, 3.5 * fury_mul)
			if not _telegraph.is_empty():
				var g: Node3D = _telegraph.group
				g.global_position = Vector3(position.x, 0.08, position.z)
				g.rotation.y = facing
				var f: Node3D = _telegraph.fill
				f.scale = Vector3(1, 1, maxf(p, 0.01)) if _attack.tipo == "investida" else Vector3(maxf(p, 0.01), 1, maxf(p, 0.01))
			_set_glow(0.6 + 1.4 * absf(sin(_t * 14.0)), Color("#ff2020"))
			if p >= 1.0:
				_release(dist, diff)

		State.ATACAR:
			if _attack.tipo == "investida":
				position += _dash_dir * _dash_speed * dt
				moving = 2.5
				if not _dash_hit and distance_to_point(player.position) < _attack.raio * 0.5 + 0.6:
					_dash_hit = hunt.hit_player(_attack.dano * (1.15 if fury else 1.0), def.elemento, position)
				if hunt.rng.randf() < 0.4:
					hunt.fx.burst(position + Vector3(0, 0.3, 0), Color("#c8b08a"), 2, 2.0, 1.5)
				var out := Vector2(position.x, position.z).length() > Models.ARENA_RADIUS - 3.0
				if _t >= DASH_TIME or out:
					_set_state(State.RECUPERAR)
			elif _t >= 0.28:
				_set_state(State.RECUPERAR)

		State.RECUPERAR:
			if _t >= _attack.recuperacao:
				_set_state(State.PERSEGUIR)

		State.RUGIR:
			_turn(angle_to_p, dt, 2.0)
			if _t > 0.25 and _t - dt <= 0.25:
				hunt.shake(0.6)
				hunt.fx.burst(_m.head.global_position, Color("#ff3030") if fury else Color.WHITE, 18, 7.0, 3.0)
				if _roar_is_fury:
					hunt.banner("%s ENFURECEU!" % def.nome.to_upper(), Color("#ff5a5a"))
			if _t >= 1.3:
				_set_state(State.PERSEGUIR)

		State.ATORDOADO:
			if _t >= STUN_TIME:
				_set_state(State.PERSEGUIR)

		State.MORTO:
			if not _dead_notified and _t > 2.0:
				_dead_notified = true
				hunt.on_beast_dead()

	var flat := Vector2(position.x, position.z)
	if flat.length() > Models.ARENA_RADIUS - 2.0:
		flat = flat.normalized() * (Models.ARENA_RADIUS - 2.0)
		position.x = flat.x
		position.z = flat.y
	position = Models.push_from_obstacles(position, radius)

	_walk_phase += dt * 9.0 * moving
	_animate(dt, moving)


# ------------------------------------------------------------ IA

func _choose_attack(dist: float, diff: float) -> Dictionary:
	var options := []
	var total := 0.0
	for a in def.ataques:
		if a.so_furia and not fury:
			continue
		if dist < a.alcance_min or dist > a.alcance_max:
			continue
		var full: bool = a.tipo == "circulo" or a.angulo >= 360.0
		if not full and absf(diff) > 0.6:
			continue
		var w := 1.0
		if full:
			w = 1.8 if absf(diff) > 1.2 else 0.5
		if a.so_furia:
			w *= 1.4
		if a.id == _last_attack:
			w *= 0.4
		options.append([a, w])
		total += w
	if options.is_empty():
		return {}
	var roll := hunt.rng.randf() * total
	for o in options:
		roll -= o[1]
		if roll <= 0.0:
			return o[0]
	return options[-1][0]


func _start_attack(a: Dictionary) -> void:
	_attack = a
	_last_attack = a.id
	_set_state(State.PREPARAR)
	_dash_speed = def.velocidade * DASH_SPEED_MULT * (1.25 if fury else 1.0)
	_telegraph = Models.build_telegraph(a.tipo, a.raio, a.angulo, _dash_speed * DASH_TIME)
	hunt.world.add_child(_telegraph.group)


func _release(dist: float, diff: float) -> void:
	_clear_telegraph()
	_set_glow(0.0)
	_set_state(State.ATACAR)
	var a := _attack
	var dmg: float = a.dano * (1.15 if fury else 1.0)
	var color := GameData.element_color(def.elemento)
	if a.tipo == "investida":
		_dash_dir = Vector3(sin(facing), 0, cos(facing))
		_dash_hit = false
		return
	var hit := false
	if a.tipo == "circulo":
		hit = dist <= a.raio
		hunt.fx.burst(position + Vector3(0, 0.4, 0), color, 40, a.raio * 1.6, 3.0)
		hunt.shake(0.5)
	else:
		var half := deg_to_rad(a.angulo) / 2.0
		hit = dist <= a.raio + 0.4 and (a.angulo >= 360.0 or absf(diff) <= half + 0.15)
		var front := position + Vector3(sin(facing), 0, cos(facing)) * (half_len + 1.0)
		hunt.fx.burst((position if a.angulo >= 360.0 else front) + Vector3(0, 0.8, 0), color, 14, 6.0, 2.0)
		hunt.shake(0.2)
	if hit:
		hunt.hit_player(dmg, def.elemento, position)


func _start_roar(is_fury: bool) -> void:
	_clear_telegraph()
	_set_glow(0.0)
	_roar_is_fury = is_fury
	_set_state(State.RUGIR)


func _set_state(s: State) -> void:
	state = s
	_t = 0.0
	if s != State.PREPARAR:
		_clear_telegraph()


func _clear_telegraph() -> void:
	if _telegraph.is_empty():
		return
	_telegraph.group.queue_free()
	_telegraph = {}


func _turn(target: float, dt: float, rate: float) -> void:
	var d := wrapf(target - facing, -PI, PI)
	facing += signf(d) * minf(absf(d), rate * dt)


func _move_forward(step: float) -> void:
	position.x += sin(facing) * step
	position.z += cos(facing) * step


# ------------------------------------------------------------ colisão (cápsula ao longo da espinha)

func _closest_on_spine(p: Vector3) -> Vector3:
	var f := Vector3(sin(facing), 0, cos(facing))
	var r := (p - position) * Vector3(1, 0, 1)
	var t := clampf(r.dot(f), -half_len, half_len)
	return Vector3(position.x, 0, position.z) + f * t


## Distância de um ponto até a superfície do corpo (negativo = dentro).
func distance_to_point(p: Vector3) -> float:
	var c := _closest_on_spine(p)
	return Vector2(p.x - c.x, p.z - c.z).length() - radius


func push_out(n: Node3D, r: float) -> void:
	if state == State.MORTO and _t > 1.0:
		return
	var c := _closest_on_spine(n.position)
	var d := Vector2(n.position.x - c.x, n.position.z - c.z)
	var min_d := radius + r
	if d.length() >= min_d:
		return
	if d.length() < 0.0001:
		d = Vector2(cos(facing), -sin(facing))
	d = d.normalized() * min_d
	n.position.x = c.x + d.x
	n.position.z = c.z + d.y


# ------------------------------------------------------------ receber dano

## Retorna {} se errou, ou {"part": id} ("" = corpo, sem parte).
func find_hit_part(strike: Vector3) -> Dictionary:
	if not alive():
		return {}
	var v: Dictionary = def.visual
	var radii := {"cabeca": maxf(1.0, v.largura * 0.5), "costas": v.comprimento * 0.3, "cauda": 1.1}
	var best := ""
	var best_d := INF
	for id in parts:
		if id == "cauda" and parts.cauda.quebrada:
			continue
		var w: Vector3 = _m.anchors[id].global_position
		var d: float = Vector2(w.x - strike.x, w.z - strike.z).length() - radii[id]
		if d < best_d:
			best_d = d
			best = id
	if best != "" and best_d <= 1.3:
		return {"part": best}
	if distance_to_point(strike) <= 0.9:
		return {"part": ""}
	return {}


func apply_damage(part_id: String, dmg: float, stagger_amt: float) -> void:
	if not alive():
		return
	hp = maxf(0.0, hp - dmg)
	_flash = 1.0

	if part_id != "":
		var p: Dictionary = parts[part_id]
		p.dano += dmg
		var at: Vector3 = _m.anchors[part_id].global_position
		if not p.ferida and p.dano >= p.def.vida * 0.5:
			p.ferida = true
			hunt.fx.text(at + Vector3(0, 1.2, 0), "FERIDA", Color("#fdba74"), 52)
		if not p.quebrada and p.dano >= p.def.vida:
			p.quebrada = true
			_break_part(part_id, at)

	if state == State.OCIOSO:
		_start_roar(false)

	if hp <= 0.0:
		_clear_telegraph()
		_set_glow(0.0)
		_set_state(State.MORTO)
		hunt.slowmo(0.8, 0.3)
		hunt.banner("%s ABATIDA!" % def.nome.to_upper(), Color("#ffd166"))
		return

	_stagger += stagger_amt
	if _stagger >= _stagger_limit and state != State.ATORDOADO:
		_stagger = 0.0
		_stagger_limit *= 1.35
		_clear_telegraph()
		_set_glow(0.0)
		_set_state(State.ATORDOADO)
		hunt.banner("ATORDOADA! Ataque agora!", Color("#6ee7a0"))
		hunt.shake(0.4)
		return

	if not fury and hp <= max_hp * FURY_HP and state != State.ATORDOADO:
		fury = true
		if _model == null:
			_m.eyes_mat.albedo_color = Color("#ff2a2a")
		_start_roar(true)


func _break_part(id: String, at: Vector3) -> void:
	var part: Dictionary = parts[id]
	hunt.fx.burst(at, Color.WHITE, 26, 9.0, 6.0)
	hunt.fx.burst(at, GameData.element_color(def.elemento), 18, 7.0, 5.0)
	hunt.shake(0.45)
	hunt.hitstop(0.12)
	hunt.on_part_broken(part.def.drop)
	if id == "cauda" and _model:
		_severed_tail = _model.cut_tail(def.visual)
		hunt.world.add_child(_severed_tail)
		_tail_vy = 4.0
		hunt.banner("CAUDA CORTADA!", Color("#6ee7a0"))
	elif _model:
		hunt.banner("%s QUEBRADA!" % part.def.nome.to_upper(), Color("#6ee7a0"))
	elif id == "cauda":
		var tail: Node3D = _m.tail_root
		var xf := tail.global_transform
		tail.get_parent().remove_child(tail)
		hunt.world.add_child(tail)
		tail.global_transform = xf
		_severed_tail = tail
		_tail_vy = 4.0
		hunt.banner("CAUDA CORTADA!", Color("#6ee7a0"))
	else:
		if id == "costas":
			for i in _m.spikes.size():
				if i % 2 == 0:
					_m.spikes[i].visible = false
		_m.part_mats[id].albedo_color = _m.part_mats[id].albedo_color.darkened(0.35)
		hunt.banner("%s QUEBRADA!" % part.def.nome.to_upper(), Color("#6ee7a0"))


func _set_glow(energy: float, color := Color("#ff2020")) -> void:
	if _model:
		_model.set_glow(color, energy * 0.45)
		return
	for m in _m.body_mats:
		m.emission = color
		m.emission_energy_multiplier = energy


# ------------------------------------------------------------ animação

func _animate(dt: float, moving: float) -> void:
	rotation.y = facing

	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 9.0)
		if state != State.PREPARAR:
			_set_glow(_flash * 0.7, Color.WHITE)
	elif fury and state != State.PREPARAR:
		_set_glow(0.3 + 0.2 * sin(_t * 6.0), Color("#ff3010"))

	if _model:
		_animate_model(dt, moving)
		return

	var leg_swing := sin(_walk_phase) * minf(0.7, 0.35 + moving * 0.2) if moving > 0.05 else 0.0
	var legs: Array = _m.legs
	for i in legs.size():
		legs[i].rotation.x = (1.0 if i == 0 or i == 3 else -1.0) * leg_swing

	var time := Time.get_ticks_msec() / 1000.0
	var segs: Array = _m.tail_segments
	for i in segs.size():
		segs[i].rotation.y = sin(time * 2.2 + i * 0.6) * (0.12 + i * 0.03)

	var pose_y := 0.0
	var pose_x := 0.0
	var pose_z := 0.0
	var head_x := 0.0
	var spin := 0.0
	var p := 0.0
	if not _attack.is_empty():
		p = minf(1.0, _t / (_attack.preparo * (0.8 if fury else 1.0)))
	var is_spin: bool = not _attack.is_empty() and _attack.tipo == "setor" and _attack.angulo >= 360.0

	match state:
		State.PREPARAR:
			if _attack.tipo == "investida":
				pose_y = -0.25 * p
				pose_x = 0.15 * p
				head_x = 0.3 * p
			elif _attack.tipo == "circulo":
				pose_y = 0.4 * p
				pose_x = -0.35 * p
				head_x = -0.5 * p
			elif is_spin:
				spin = -0.6 * p
				pose_y = -0.15 * p
			else:
				pose_x = -0.25 * p
				head_x = -0.6 * p
		State.ATACAR:
			if _attack.tipo == "circulo":
				pose_y = 0.4 * maxf(0.0, 1.0 - _t * 6.0)
			elif is_spin:
				spin = -0.6 + (TAU + 0.6) * minf(1.0, _t / 0.25)
			elif _attack.tipo == "setor":
				pose_x = 0.25
				head_x = 0.5
		State.RECUPERAR:
			pose_y = sin(_t * 8.0) * 0.04
			head_x = 0.25
		State.RUGIR:
			head_x = -0.8 * minf(1.0, _t * 4.0)
			pose_x = -0.2 * minf(1.0, _t * 4.0)
		State.ATORDOADO:
			var fade := (STUN_TIME - _t) / 0.3 if _t > STUN_TIME - 0.3 else 1.0
			pose_z = minf(1.0, _t * 4.0) * 1.25 * fade
			for i in legs.size():
				legs[i].rotation.x = sin(_t * 10.0 + i) * 0.5
		State.MORTO:
			pose_z = minf(1.0, _t * 1.5) * 1.5
			_m.eyes_mat.albedo_color = Color("#333333")

	var pose: Node3D = _m.pose
	pose.position.y = pose_y + (sin(pose_z) * def.visual.pernas * 0.3 if pose_z != 0.0 else 0.0)
	pose.rotation = Vector3(pose_x, spin, pose_z)
	_m.head.rotation.x = head_x

	_update_severed_tail(dt)


func _update_severed_tail(dt: float) -> void:
	if _severed_tail and _severed_tail.position.y > 0.3:
		_tail_vy -= 18.0 * dt
		_severed_tail.position.y = maxf(0.3, _severed_tail.position.y + _tail_vy * dt)
		_severed_tail.rotation.y += 3.0 * dt
		_severed_tail.rotation.z += 1.5 * dt


## Escolhe a animação do modelo pelo estado; inclinações e giros continuam no nó `pose`.
func _animate_model(dt: float, moving: float) -> void:
	var entered := _anim_state != state
	_anim_state = state
	var p := 0.0
	if not _attack.is_empty():
		p = minf(1.0, _t / (_attack.preparo * (0.8 if fury else 1.0)))
	var tipo: String = _attack.get("tipo", "")
	var is_spin: bool = tipo == "setor" and _attack.get("angulo", 0.0) >= 360.0
	var pose_y := 0.0
	var pose_x := 0.0
	var pose_z := 0.0
	var spin := 0.0
	match state:
		State.OCIOSO, State.PERSEGUIR:
			if moving > 0.75:
				_model.play("Run", clampf(moving, 0.8, 1.6))
			elif moving > 0.05:
				_model.play("Walk", clampf(moving * 1.6, 0.6, 1.4))
			else:
				_model.play("Idle")
		State.PREPARAR:
			# Segura o começo do golpe enquanto o aviso enche no chão.
			if tipo == "investida":
				_model.play("Idle", 0.5)
				pose_y = -0.25 * p
				pose_x = 0.12 * p
			elif tipo == "circulo":
				_model.seek_fraction("Jump", p * 0.3)
			elif is_spin:
				_model.play("Idle", 0.5)
				spin = -0.6 * p
			else:
				_model.seek_fraction("Attack", p * 0.4)
		State.ATACAR:
			if tipo == "investida":
				_model.play("Run", 1.7)
			elif tipo == "circulo":
				if entered:
					_model.play("Jump", 1.6)
			elif is_spin:
				spin = -0.6 + (TAU + 0.6) * minf(1.0, _t / 0.25)
			elif entered:
				_model.play("Attack", 1.8)
		State.RECUPERAR:
			if _model.current() == "Run" or _model.current() == "Idle":
				_model.play("Idle", 0.8)
			elif not _model.player.is_playing() or _model.player.speed_scale == 0.0:
				_model.play("Idle", 0.8)
		State.RUGIR:
			if entered:
				_model.play("Attack", 0.6, 0.2, true)
			pose_x = -0.15 * minf(1.0, _t * 4.0)
		State.ATORDOADO:
			_model.play("Idle", 0.3)
			var fade := (STUN_TIME - _t) / 0.3 if _t > STUN_TIME - 0.3 else 1.0
			pose_z = minf(1.0, _t * 4.0) * 1.25 * fade
		State.MORTO:
			if entered:
				_model.play("Death", 1.0, 0.1, true)
	_model.tick(dt)
	var pose: Node3D = _m.pose
	pose.position.y = pose_y + (sin(pose_z) * def.visual.pernas * 0.4 if pose_z != 0.0 else 0.0)
	pose.rotation = Vector3(pose_x, spin, pose_z)
	_update_severed_tail(dt)

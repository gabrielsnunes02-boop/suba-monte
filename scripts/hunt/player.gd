class_name HunterPlayer
extends Node3D
## O caçador: combo leve, ataque carregado, esquiva com invencibilidade, poções.

enum State { LIVRE, ATAQUE, CARREGANDO, PESADO, ESQUIVA, BEBENDO, ATINGIDO, CAIDO }

const LIGHT := [
	{"dur": 0.42, "hit_at": 0.14},
	{"dur": 0.42, "hit_at": 0.14},
	{"dur": 0.56, "hit_at": 0.22},
]
const HEAVY_DUR := 0.62
const HEAVY_HIT_AT := 0.22
const CHARGE_TIME := 1.0
const DODGE_DUR := 0.42
const DODGE_IFRAMES := 0.32
const DODGE_SPEED := 13.0
const DRINK_DUR := 0.9
const STAGGER_DUR := 0.45
const SOFT_LOCK_RANGE := 9.0
const REACH := 1.9
## Fração do golpe pesado em que o personagem fica parado carregando.
const HEAVY_WINDUP := 0.28

var hunt: Hunt
var facing := PI
var max_hp: float
var hp: float
var stamina: float = GameData.PLAYER.stamina
var potions: int = GameData.PLAYER.pocoes
var state := State.LIVRE
## "Esquiva Afiada": próximo golpe garantido crítico.
var sharp := false

var _perks: Array[String] = []
var _model: HunterModel
var _t := 0.0
var _time := 0.0
var _last_damaged_at := -99.0
var _stamina_delay := 0.0
var _combo := 0
var _combo_queued := false
var _hit_done := false
var _charge := 0.0
var _heal_left := 0.0
var _dodge_dir := Vector3.FORWARD
var _knock := Vector3.ZERO


func setup(h: Hunt) -> void:
	hunt = h
	for p in [h.weapon.perk, h.armor.perk]:
		if p != "":
			_perks.append(p)
	max_hp = roundf(GameData.PLAYER.vida * (1.2 if has_perk("pele_grossa") else 1.0))
	hp = max_hp
	var blade_color := Color("#c9d1dc") if h.weapon.elemento == "neutro" else GameData.element_color(h.weapon.elemento)
	_model = HunterModel.new()
	add_child(_model)
	_model.setup(Settings.outfit(), blade_color)


func has_perk(p: String) -> bool:
	return _perks.has(p)


func is_invulnerable() -> bool:
	return (state == State.ESQUIVA and _t < DODGE_IFRAMES) or state == State.CAIDO


func forward() -> Vector3:
	return Vector3(sin(facing), 0, cos(facing))


func tick(dt: float) -> void:
	_time += dt
	_t += dt

	var pressed := Input.is_action_just_pressed("attack")
	var held := Input.is_action_pressed("attack")
	var dodge := Input.is_action_just_pressed("dodge")
	var potion := Input.is_action_just_pressed("potion")

	if _stamina_delay > 0.0:
		_stamina_delay -= dt
	elif state != State.ESQUIVA:
		stamina = minf(GameData.PLAYER.stamina, stamina + GameData.PLAYER.regen_stamina * dt)

	# Movimento relativo à câmera.
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var mag := minf(1.0, iv.length())
	var mv := Vector3(iv.x, 0, iv.y).rotated(Vector3.UP, hunt.camera_rig.yaw)
	var moving := mag > 0.15
	if moving:
		mv = mv.normalized()

	var speed_mul := 0.0
	match state:
		State.LIVRE:
			speed_mul = 1.0
			if moving:
				_turn_to(atan2(mv.x, mv.z), dt, 16.0)
			if dodge:
				_try_dodge(mv, moving)
			elif pressed:
				_start_light(0)
			elif potion:
				_try_drink()

		State.ATAQUE:
			var s: Dictionary = LIGHT[_combo]
			if _t < s.hit_at:
				position += forward() * 2.6 * dt
			if not _hit_done and _t >= s.hit_at:
				_strike(GameData.MOTION_LEVE[_combo], false)
			if pressed and _t > s.dur * 0.3:
				_combo_queued = true
			if dodge and _t > s.hit_at:
				_try_dodge(mv, moving)
			elif _t >= s.dur:
				if _combo_queued and _combo < 2:
					_start_light(_combo + 1)
				elif held:
					_set_state(State.CARREGANDO)
				else:
					_set_state(State.LIVRE)

		State.CARREGANDO:
			speed_mul = 0.3
			if moving:
				_turn_to(atan2(mv.x, mv.z), dt, 6.0)
			_charge = minf(1.0, _t / CHARGE_TIME)
			_model.set_blade_glow(_charge * 3.0)
			if _charge >= 1.0 and randf() < 0.25:
				hunt.fx.burst(_model.sword_position(), Color("#fff3b0"), 2, 2.0, 2.0)
			if dodge:
				_model.set_blade_glow(0.0)
				_try_dodge(mv, moving)
			elif not held:
				_soft_lock()
				_set_state(State.PESADO)

		State.PESADO:
			if _t < HEAVY_HIT_AT:
				position += forward() * 1.5 * dt
			if not _hit_done and _t >= HEAVY_HIT_AT:
				_strike(lerpf(GameData.MOTION_PESADO_MIN, GameData.MOTION_PESADO_MAX, _charge), true)
				_model.set_blade_glow(0.0)
			if dodge and _t > HEAVY_HIT_AT + 0.1:
				_try_dodge(mv, moving)
			elif _t >= HEAVY_DUR:
				_set_state(State.LIVRE)

		State.ESQUIVA:
			var k := maxf(0.0, 1.0 - _t / DODGE_DUR)
			position += _dodge_dir * DODGE_SPEED * pow(k, 1.2) * dt
			if _t >= DODGE_DUR:
				_set_state(State.LIVRE)

		State.BEBENDO:
			speed_mul = 0.35
			if moving:
				_turn_to(atan2(mv.x, mv.z), dt, 8.0)
			var heal := minf(_heal_left, GameData.PLAYER.cura_pocao / DRINK_DUR * dt)
			_heal_left -= heal
			hp = minf(max_hp, hp + heal)
			if randf() < 0.3:
				hunt.fx.burst(global_position + Vector3(0, 1.2, 0), Color("#7dff8a"), 2, 1.5, 3.0)
			if _t >= DRINK_DUR:
				_set_state(State.LIVRE)

		State.ATINGIDO:
			position += _knock * dt
			_knock *= pow(0.02, dt)
			if _t >= STAGGER_DUR:
				_set_state(State.LIVRE)

		State.CAIDO:
			pass

	if speed_mul > 0.0 and moving:
		position += mv * GameData.PLAYER.velocidade * speed_mul * mag * dt

	# Limites da ilha e colisão com a fera.
	var flat := Vector2(position.x, position.z)
	if flat.length() > Models.ARENA_RADIUS - 1.0:
		flat = flat.normalized() * (Models.ARENA_RADIUS - 1.0)
		position.x = flat.x
		position.z = flat.y
	position.y = 0.0
	if state != State.CAIDO:
		hunt.beast.push_out(self, 0.5)

	_animate(moving and speed_mul > 0.0, mag)


## Golpe da fera chega no jogador. Retorna "acertou", "esquivou" ou "nada".
func take_hit(raw: float, element: String, from: Vector3) -> String:
	if state == State.CAIDO:
		return "nada"
	if is_invulnerable():
		return "esquivou"
	var def := Formulas.gear_value(hunt.armor, hunt.armor_level)
	var dmg := Formulas.compute_incoming(raw, def, Formulas.elemental_resistance(hunt.armor.elemento, element))
	hp = maxf(0.0, hp - dmg)
	_last_damaged_at = _time
	_heal_left = 0.0
	_model.set_blade_glow(0.0)
	hunt.fx.text(global_position + Vector3(0, 2.5, 0), "-%d" % dmg, Color("#ff6b6b"))
	hunt.fx.burst(global_position + Vector3(0, 1.2, 0), Color("#ff4040"), 10, 5.0)
	hunt.shake(0.35)
	_knock = (global_position - from) * Vector3(1, 0, 1)
	if _knock.length_squared() < 0.01:
		_knock = Vector3.BACK
	_knock = _knock.normalized() * 11.0
	if hp <= 0.0:
		_set_state(State.CAIDO)
		hunt.on_player_down()
	else:
		_set_state(State.ATINGIDO)
	return "acertou"


func respawn(at: Vector3) -> void:
	position = at
	hp = max_hp
	stamina = GameData.PLAYER.stamina
	_set_state(State.LIVRE)


# ------------------------------------------------------------ ações

func _set_state(s: State) -> void:
	state = s
	_t = 0.0
	_hit_done = false
	if s != State.ATAQUE:
		_combo_queued = false
	if s == State.CARREGANDO:
		_charge = 0.0
	_enter_animation(s)


func _start_light(step: int) -> void:
	_soft_lock()
	_combo = step
	_set_state(State.ATAQUE)


func _try_dodge(mv: Vector3, moving: bool) -> void:
	var cost: float = GameData.PLAYER.custo_esquiva * (0.75 if has_perk("folego_longo") else 1.0)
	if stamina < cost:
		hunt.fx.text(global_position + Vector3(0, 2.5, 0), "sem fôlego", Color("#c8c3dd"), 44)
		return
	stamina -= cost
	_stamina_delay = GameData.PLAYER.atraso_regen
	_dodge_dir = mv if moving else -forward()
	facing = atan2(_dodge_dir.x, _dodge_dir.z)
	_set_state(State.ESQUIVA)


func _try_drink() -> void:
	if potions <= 0 or hp >= max_hp:
		hunt.fx.text(global_position + Vector3(0, 2.5, 0), "sem poções" if potions <= 0 else "vida cheia", Color("#c8c3dd"), 44)
		return
	potions -= 1
	_heal_left = GameData.PLAYER.cura_pocao
	_set_state(State.BEBENDO)


func _soft_lock() -> void:
	var b := hunt.beast
	if not b.alive():
		return
	var d := b.position - position
	if Vector2(d.x, d.z).length() - b.radius < SOFT_LOCK_RANGE:
		facing = atan2(d.x, d.z)


func _turn_to(target: float, dt: float, rate: float) -> void:
	var d := wrapf(target - facing, -PI, PI)
	facing += signf(d) * minf(absf(d), rate * dt)


func _strike(motion: float, heavy: bool) -> void:
	_hit_done = true
	var beast := hunt.beast
	var point := position + forward() * REACH + Vector3(0, 1.2, 0)
	var hit := beast.find_hit_part(point)
	if hit.is_empty():
		return
	var part_id: String = hit.part
	var wounded: bool = part_id != "" and beast.parts[part_id].ferida
	var bonus := 0.0
	if wounded and has_perk("quebra_ossos"):
		bonus += 0.3
	if has_perk("cacador_paciente") and _time - _last_damaged_at > 3.0:
		bonus += 0.2
	if has_perk("ultimo_folego") and hp < max_hp * 0.3:
		bonus += 0.25
	var crit := sharp or hunt.rng.randf() < Formulas.CRIT_CHANCE
	sharp = false
	var el_mult := Formulas.element_multiplier(hunt.weapon.elemento, beast.def.elemento)
	var dmg := Formulas.compute_damage(Formulas.gear_value(hunt.weapon, hunt.weapon_level), motion, bonus, crit,
		el_mult, Formulas.WOUND_MULT if wounded else 1.0, beast.def.defesa)
	var stagger := dmg * (0.7 if heavy else 0.25) if part_id == "cabeca" else 0.0
	beast.apply_damage(part_id, dmg, stagger)

	var col := Color.WHITE
	if crit:
		col = Color("#ffd166")
	elif el_mult > 1.0:
		col = Color("#ffa94d")
	elif el_mult < 1.0:
		col = Color("#9aa0b4")
	hunt.fx.text(point + Vector3(0, 1.0, 0), "%d%s" % [dmg, "!" if crit else ""], col, 84 if crit else 64)
	hunt.fx.burst(point, GameData.element_color(hunt.weapon.elemento), 16 if heavy else 8, 8.0 if heavy else 5.0)
	hunt.hitstop(0.09 if heavy else 0.045)
	hunt.shake(0.3 if heavy else 0.1)


# ------------------------------------------------------------ animação

## Clipes de uma vez só começam ao entrar no estado.
func _enter_animation(s: State) -> void:
	match s:
		State.ATAQUE:
			_model.play("light%d" % _combo, LIGHT[_combo].dur, true, 0.05)
		State.CARREGANDO:
			_model.hold_at("heavy", HEAVY_WINDUP)
		State.PESADO:
			_model.resume_from("heavy", HEAVY_WINDUP, HEAVY_DUR)
		State.ESQUIVA:
			_model.play("dodge", DODGE_DUR, true, 0.05)
		State.BEBENDO:
			_model.play("drink", DRINK_DUR, true)
		State.ATINGIDO:
			_model.play("hit", STAGGER_DUR, true, 0.05)
		State.CAIDO:
			_model.play("death", 1.2, true, 0.05)


## Clipes contínuos (parado/correndo) e direção do corpo, a cada quadro.
func _animate(walking: bool, mag: float) -> void:
	_model.rotation.y = facing
	# Terceiro golpe do combo: corte girando (uma volta inteira até o momento do acerto).
	if state == State.ATAQUE and _combo == 2:
		_model.rotation.y += TAU * smoothstep(0.0, LIGHT[2].hit_at * 1.3, _t)
	if state == State.LIVRE:
		if walking:
			_model.play("run", 0.0, false, 0.15, clampf(mag * 1.15, 0.6, 1.25))
		else:
			_model.play("idle", 0.0, false, 0.2)

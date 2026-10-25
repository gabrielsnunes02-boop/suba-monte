class_name Formulas
extends RefCounted
## Regras numéricas puras (sem cena), cobertas por tests/run_tests.gd.

const CRIT_CHANCE := 0.05
const CRIT_MULT := 1.5
const PERK_BONUS_CAP := 1.0
const WOUND_MULT := 1.3


## Forte ×1,5 · neutro ×1 · fraco ×0,75. Neutro nunca tem vantagem nem desvantagem.
static func element_multiplier(attack: String, defender: String) -> float:
	if attack == "neutro" or defender == "neutro":
		return 1.0
	if GameData.BEATS.get(attack, "") == defender:
		return 1.5
	if GameData.BEATS.get(defender, "") == attack:
		return 0.75
	return 1.0


## Quanto a armadura muda o dano de um elemento (resistência ou fraqueza).
static func elemental_resistance(armor: String, incoming: String) -> float:
	if armor == "neutro" or incoming == "neutro":
		return 1.0
	if armor == incoming:
		return 0.8
	if GameData.BEATS.get(incoming, "") == armor:
		return 1.2
	return 1.0


static func compute_damage(base: float, motion: float, perk_bonus: float, crit: bool, element_mult: float,
		part_mult: float, defense: float) -> int:
	var perks := 1.0 + clampf(perk_bonus, 0.0, PERK_BONUS_CAP)
	var crit_mult := CRIT_MULT if crit else 1.0
	var raw := base * motion * perks * crit_mult * element_mult * part_mult * (1.0 - defense)
	return maxi(1, roundi(raw))


static func compute_incoming(raw_damage: float, armor_defense: float, resist_mult: float) -> int:
	return maxi(1, roundi(raw_damage * (1.0 - armor_defense) * resist_mult))


## Cada nível de upgrade dá +8% sobre o valor base.
static func gear_value(gear: Dictionary, level: int) -> float:
	var v: float = gear.base * (1.0 + 0.08 * level)
	return float(roundi(v)) if gear.slot == "arma" else minf(0.6, v)


## Custo para ir de `level` para `level + 1`. Vazio se já está no máximo.
static func upgrade_cost(gear: Dictionary, level: int) -> Dictionary:
	if level >= GameData.MAX_UPGRADE:
		return {}
	var mats := {gear.material_upgrade: level + 1}
	if level >= 5:
		mats[gear.material_raro] = mats.get(gear.material_raro, 0) + 1
	return {"moedas": roundi(100.0 * pow(1.35, level)), "materiais": mats}


## XP para sair do rank n para o n + 1.
static func xp_for_rank(n: int) -> int:
	return roundi(100.0 * pow(n, 1.6))


static func apply_xp(rank: int, xp: int, gained: int) -> Dictionary:
	var r := rank
	var x := xp + gained
	var subiu := 0
	while x >= xp_for_rank(r):
		x -= xp_for_rank(r)
		r += 1
		subiu += 1
	return {"rank": r, "xp": x, "subiu": subiu}


static func roll_loot(table: Array, rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	for e in table:
		if rng.randf() < e.chance:
			out[e.item] = out.get(e.item, 0) + rng.randi_range(e.qtd[0], e.qtd[1])
	return out


static func merge_counts(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = out.get(k, 0) + b[k]
	return out

class_name ProfileLogic
extends RefCounted
## Perfil do jogador (moedas, rank, inventário, equipamentos) e as ações da forja.
## Funções puras: recebem um perfil e devolvem uma cópia nova.

const SAVE_PATH := "user://perfil.json"
const VERSION := 1


static func new_profile() -> Dictionary:
	return {
		"versao": VERSION,
		"moedas": 200,
		"rank": 1,
		"xp": 0,
		"inventario": {"minerio": 4, "fibra": 4},
		"equipamentos": {"espada_ferro": 0, "roupa_couro": 0},
		"equipado": {"arma": "espada_ferro", "armadura": "roupa_couro"},
		"bestiario": {},
	}


static func has_all(inv: Dictionary, need: Dictionary) -> bool:
	for k in need:
		if inv.get(k, 0) < need[k]:
			return false
	return true


static func _spend(inv: Dictionary, need: Dictionary) -> Dictionary:
	var out := inv.duplicate()
	for k in need:
		out[k] = out.get(k, 0) - need[k]
		if out[k] <= 0:
			out.erase(k)
	return out


static func can_craft(p: Dictionary, gear_id: String) -> bool:
	var g: Dictionary = GameData.GEAR[gear_id]
	return not p.equipamentos.has(gear_id) and p.moedas >= g.custo and has_all(p.inventario, g.receita)


static func craft(p: Dictionary, gear_id: String) -> Dictionary:
	assert(can_craft(p, gear_id), "Não é possível fabricar este item.")
	var g: Dictionary = GameData.GEAR[gear_id]
	var out := p.duplicate(true)
	out.moedas -= g.custo
	out.inventario = _spend(p.inventario, g.receita)
	out.equipamentos[gear_id] = 0
	return out


static func can_upgrade(p: Dictionary, gear_id: String) -> bool:
	if not p.equipamentos.has(gear_id):
		return false
	var cost := Formulas.upgrade_cost(GameData.GEAR[gear_id], p.equipamentos[gear_id])
	return not cost.is_empty() and p.moedas >= cost.moedas and has_all(p.inventario, cost.materiais)


static func upgrade(p: Dictionary, gear_id: String) -> Dictionary:
	assert(can_upgrade(p, gear_id), "Não é possível melhorar este item.")
	var cost := Formulas.upgrade_cost(GameData.GEAR[gear_id], p.equipamentos[gear_id])
	var out := p.duplicate(true)
	out.moedas -= cost.moedas
	out.inventario = _spend(p.inventario, cost.materiais)
	out.equipamentos[gear_id] += 1
	return out


static func equip(p: Dictionary, gear_id: String) -> Dictionary:
	assert(p.equipamentos.has(gear_id), "Item não possuído.")
	var out := p.duplicate(true)
	out.equipado[GameData.GEAR[gear_id].slot] = gear_id
	return out


## result: {fera_id, vitoria, tempo, partes_quebradas, loot, moedas, xp}
static func apply_hunt_result(p: Dictionary, r: Dictionary) -> Dictionary:
	var out := p.duplicate(true)
	var xp := Formulas.apply_xp(p.rank, p.xp, r.xp)
	var prev: Dictionary = p.bestiario.get(r.fera_id, {"abates": 0, "partes_quebradas": 0, "melhor_tempo": -1})
	var entry := prev.duplicate()
	entry.partes_quebradas = prev.partes_quebradas + r.partes_quebradas
	if r.vitoria:
		entry.abates = prev.abates + 1
		entry.melhor_tempo = r.tempo if prev.melhor_tempo < 0 else mini(prev.melhor_tempo, r.tempo)
	out.moedas += r.moedas
	out.rank = xp.rank
	out.xp = xp.xp
	out.inventario = Formulas.merge_counts(p.inventario, r.loot)
	out.bestiario[r.fera_id] = entry
	return {"profile": out, "subiu_rank": xp.subiu}


# ------------------------------------------------------------ persistência (offline)

static func load_profile() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return new_profile()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return new_profile()
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("versao", 0)) != VERSION:
		return new_profile()
	return _normalize(data)


static func save_profile(p: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(p))


static func reset_profile() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	return new_profile()


## JSON devolve números como float; o perfil usa inteiros.
static func _normalize(d: Dictionary) -> Dictionary:
	var p := new_profile()
	for k in ["moedas", "rank", "xp"]:
		p[k] = int(d.get(k, p[k]))
	for section in ["inventario", "equipamentos"]:
		var src: Dictionary = d.get(section, {})
		var dst := {}
		for k in src:
			if section == "inventario" or GameData.GEAR.has(k):
				dst[k] = int(src[k])
		if not dst.is_empty():
			p[section] = dst
	var eq: Dictionary = d.get("equipado", {})
	for slot in ["arma", "armadura"]:
		if p.equipamentos.has(eq.get(slot, "")):
			p.equipado[slot] = eq[slot]
	var best: Dictionary = d.get("bestiario", {})
	for k in best:
		p.bestiario[k] = {
			"abates": int(best[k].get("abates", 0)),
			"partes_quebradas": int(best[k].get("partes_quebradas", 0)),
			"melhor_tempo": int(best[k].get("melhor_tempo", -1)),
		}
	return p

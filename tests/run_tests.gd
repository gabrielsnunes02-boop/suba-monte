extends SceneTree
## Testes das regras do jogo. Rode com:
##   godot --headless --path . --script res://tests/run_tests.gd

var _failures := 0
var _count := 0


func _init() -> void:
	_test_elements()
	_test_damage()
	_test_upgrade()
	_test_progression()
	_test_profile_flow()
	_test_profile_normalize()
	print("%d verificações, %d falha(s)" % [_count, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_count += 1
	if not cond:
		_failures += 1
		printerr("FALHOU: " + what)


func _test_elements() -> void:
	check(Formulas.element_multiplier("fogo", "natureza") == 1.5, "fogo > natureza")
	check(Formulas.element_multiplier("natureza", "agua") == 1.5, "natureza > agua")
	check(Formulas.element_multiplier("agua", "fogo") == 1.5, "agua > fogo")
	check(Formulas.element_multiplier("natureza", "fogo") == 0.75, "natureza < fogo")
	check(Formulas.element_multiplier("fogo", "fogo") == 1.0, "mesmo elemento neutro")
	check(Formulas.element_multiplier("neutro", "agua") == 1.0, "neutro sem vantagem")
	check(GameData.weakness_of("fogo") == "agua", "fraqueza do fogo")
	check(GameData.weakness_of("neutro") == "", "neutro sem fraqueza")
	check(Formulas.elemental_resistance("fogo", "fogo") == 0.8, "armadura resiste ao próprio elemento")
	check(Formulas.elemental_resistance("fogo", "agua") == 1.2, "armadura sofre com quem a vence")
	for b in GameData.BEASTS:
		var weak := GameData.weakness_of(b.elemento)
		var has_counter := false
		for id in GameData.GEAR:
			var g: Dictionary = GameData.GEAR[id]
			if g.slot == "arma" and g.elemento == weak:
				has_counter = true
		check(has_counter, "%s tem arma counter" % b.id)


func _test_damage() -> void:
	check(Formulas.compute_damage(40, 1, 0, false, 1, 1, 0) == 40, "dano base")
	check(Formulas.compute_damage(40, 1, 0, true, 1, 1, 0) == 60, "crítico")
	check(Formulas.compute_damage(40, 1, 0, false, 1.5, 1.3, 0.1) == 70, "elemento + ferida + defesa")
	check(Formulas.compute_damage(40, 1, 5, false, 1, 1, 0) == 80, "perks limitados a +100%")
	check(Formulas.compute_damage(0, 1, 0, false, 1, 1, 0) == 1, "dano mínimo 1")


func _test_upgrade() -> void:
	var g: Dictionary = GameData.GEAR.lamina_brasa
	var c0 := Formulas.upgrade_cost(g, 0)
	var c5 := Formulas.upgrade_cost(g, 5)
	check(c0.materiais == {"couro_brasa": 1}, "custo +0")
	check(c5.materiais == {"couro_brasa": 6, "coracao_brasa": 1}, "custo +5 pede raro")
	check(c5.moedas > c0.moedas, "custo cresce")
	check(Formulas.upgrade_cost(g, GameData.MAX_UPGRADE).is_empty(), "nível máximo")
	check(Formulas.gear_value(GameData.GEAR.espada_ferro, 0) == 40.0, "valor +0")
	check(Formulas.gear_value(GameData.GEAR.espada_ferro, 10) == 72.0, "valor +10")


func _test_progression() -> void:
	var r := Formulas.apply_xp(1, 0, Formulas.xp_for_rank(1) + Formulas.xp_for_rank(2) + 5)
	check(r == {"rank": 3, "xp": 5, "subiu": 2}, "sobe vários ranks")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var loot := Formulas.roll_loot(GameData.BEASTS[0].loot, rng)
	check(loot.get("couro_brasa", 0) >= 2, "loot garantido")


func _test_profile_flow() -> void:
	var p := ProfileLogic.new_profile()
	check(not ProfileLogic.can_craft(p, "lamina_brasa"), "não fabrica sem material")
	p = ProfileLogic.apply_hunt_result(p, {"fera_id": "onca_brasa", "vitoria": true, "tempo": 120,
		"partes_quebradas": 2, "loot": {"couro_brasa": 5, "garra_brasa": 2}, "moedas": 400, "xp": 80}).profile
	check(p.bestiario.onca_brasa.abates == 1, "bestiário conta abate")
	check(ProfileLogic.can_craft(p, "lamina_brasa"), "fabrica após caçar")
	p = ProfileLogic.craft(p, "lamina_brasa")
	check(p.equipamentos.lamina_brasa == 0, "item fabricado")
	check(not p.inventario.has("garra_brasa"), "materiais gastos")
	check(not ProfileLogic.can_craft(p, "lamina_brasa"), "não fabrica duas vezes")
	p = ProfileLogic.upgrade(p, "lamina_brasa")
	check(p.equipamentos.lamina_brasa == 1, "upgrade")
	p = ProfileLogic.equip(p, "lamina_brasa")
	check(p.equipado.arma == "lamina_brasa", "equipado")


func _test_profile_normalize() -> void:
	var raw = JSON.parse_string(JSON.stringify(ProfileLogic.new_profile()))
	var p := ProfileLogic._normalize(raw)
	check(typeof(p.moedas) == TYPE_INT, "moedas voltam como int")
	check(typeof(p.inventario.minerio) == TYPE_INT, "inventário volta como int")

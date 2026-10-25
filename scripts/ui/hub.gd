class_name Hub
extends Control
## Acampamento: caçar, forja, equipamento, inventário e resultado da caçada.

signal hunt_requested(fera_id: String)
signal profile_changed(profile: Dictionary)

const C_BG := Color("#14121c")
const C_CARD := Color("#26223a")
const C_LINE := Color("#3a3454")
const C_TEXT := Color("#f1ecff")
const C_MUTED := Color("#a69fc0")
const C_ACCENT := Color("#ff8a3d")
const C_GOLD := Color("#ffd166")
const C_GOOD := Color("#6ee7a0")
const C_BAD := Color("#ff6b6b")

var profile: Dictionary
var _screen := "home"
var _result: Dictionary = {}
var _subiu := 0
var _content: VBoxContainer
var _wallet: Label
var _back: Button
var _logo: Label
var _scroll: ScrollContainer
var _reset_armed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = make_theme()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	col.add_child(top)
	_back = Button.new()
	_back.text = "‹ Acampamento"
	_back.flat = true
	_back.add_theme_color_override("font_color", C_GOLD)
	_back.pressed.connect(func(): go("home"))
	top.add_child(_back)
	_logo = _label("SUBA MONTE  ·  Caçadores da Montanha", 26, C_TEXT)
	top.add_child(_logo)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_wallet = _label("", 20, C_GOLD)
	top.add_child(_wallet)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	_scroll.add_child(_content)
	render()


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#1e1b29")
	normal.border_color = C_LINE
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	var hover := normal.duplicate()
	hover.bg_color = Color("#2a2640")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#332e4d")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("#1a1824")
	disabled.border_color = Color("#2a2640")
	for s in ["normal", "focus"]:
		t.set_stylebox(s, "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
	t.set_color("font_color", "Label", C_TEXT)
	var panel := StyleBoxFlat.new()
	panel.bg_color = C_CARD
	panel.border_color = C_LINE
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(16)
	panel.content_margin_left = 20
	panel.content_margin_right = 20
	panel.content_margin_top = 16
	panel.content_margin_bottom = 16
	t.set_stylebox("panel", "PanelContainer", panel)
	return t


func show_result(result: Dictionary, subiu: int) -> void:
	_result = result
	_subiu = subiu
	render()


func go(screen: String) -> void:
	_screen = screen
	_result = {}
	_reset_armed = false
	render()
	_scroll.scroll_vertical = 0


func _set_profile(p: Dictionary, msg := "") -> void:
	profile = p
	profile_changed.emit(p)
	render()
	if msg != "":
		_toast(msg)


# ------------------------------------------------------------ helpers de UI

func _label(text: String, size := 20, color := C_TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _card(accent := Color(0, 0, 0, 0)) -> Array:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if accent.a > 0:
		var sb: StyleBoxFlat = theme.get_stylebox("panel", "PanelContainer").duplicate()
		sb.border_color = accent
		sb.border_width_left = 6
		pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	return [pc, v]


func _button(text: String, cb: Callable, primary := false, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)
	b.disabled = not enabled
	if primary and enabled:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_ACCENT
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 20
		sb.content_margin_right = 20
		var sbp := sb.duplicate()
		sbp.bg_color = C_ACCENT.darkened(0.15)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("focus", sb)
		b.add_theme_stylebox_override("pressed", sbp)
		b.add_theme_color_override("font_color", Color("#1b0f05"))
		b.add_theme_color_override("font_hover_color", Color("#1b0f05"))
		b.add_theme_color_override("font_pressed_color", Color("#1b0f05"))
	b.pressed.connect(cb)
	return b


func _el(el: String) -> String:
	return GameData.ELEMENTS[el].nome


func _stat(g: Dictionary, level: int) -> String:
	var v := Formulas.gear_value(g, level)
	return "Poder %d" % int(v) if g.slot == "arma" else "Defesa %d%%" % roundi(v * 100.0)


func _recipe_row(need: Dictionary, coins: int) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 16)
	for k in need:
		var have: int = profile.inventario.get(k, 0)
		row.add_child(_label("%s %d/%d" % [GameData.material_name(k), have, need[k]], 18, C_GOOD if have >= need[k] else C_BAD))
	row.add_child(_label("Moedas %d" % coins, 18, C_GOOD if profile.moedas >= coins else C_BAD))
	return row


func _toast(msg: String) -> void:
	var l := _label(msg, 22, C_TEXT)
	var pc := PanelContainer.new()
	pc.add_child(l)
	pc.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pc.position = Vector2(-200, -90)
	pc.custom_minimum_size = Vector2(400, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(pc)
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(pc, "modulate:a", 0.0, 0.3)
	tw.tween_callback(pc.queue_free)


# ------------------------------------------------------------ telas

func render() -> void:
	if _content == null:
		return
	for c in _content.get_children():
		c.queue_free()
	var home := _screen == "home" and _result.is_empty()
	_back.visible = not home
	_logo.visible = home
	_wallet.text = "Rank %d    Moedas %d" % [profile.rank, profile.moedas]
	if not _result.is_empty():
		_render_result()
	else:
		match _screen:
			"home": _render_home()
			"cacar": _render_hunts()
			"forja": _render_forge()
			"equip": _render_equip()
			"inventario": _render_inventory()


func _render_home() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_content.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.3
	left.add_theme_constant_override("separation", 12)
	row.add_child(left)
	var hero: Array = _card(C_ACCENT)
	left.add_child(hero[0])
	hero[1].add_child(_label("O Monte espera, caçador.", 32, C_TEXT))
	hero[1].add_child(_label("Cace feras, quebre suas partes, forje o equipamento delas e suba cada vez mais alto.", 20, C_MUTED, true))
	var need := Formulas.xp_for_rank(profile.rank)
	hero[1].add_child(_label("Rank %d  ·  %d/%d XP" % [profile.rank, profile.xp, need], 18, C_MUTED))
	var xpbar := Hud.bar(C_ACCENT, Color("#1e1b29"), 12)
	xpbar.value = float(profile.xp) / need
	hero[1].add_child(xpbar)
	var hunt_btn := _button("CAÇAR", func(): go("cacar"), true)
	hunt_btn.custom_minimum_size = Vector2(0, 84)
	hunt_btn.add_theme_font_size_override("font_size", 30)
	left.add_child(hunt_btn)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	for item in [["Forja", "forja"], ["Equipamento", "equip"], ["Inventário", "inventario"]]:
		var b := _button(item[0], go.bind(item[1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	left.add_child(grid)

	var load_card: Array = _card()
	load_card[0].size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(load_card[0])
	load_card[1].add_child(_label("LOADOUT", 16, C_MUTED))
	for slot in ["arma", "armadura"]:
		var id: String = profile.equipado[slot]
		var g: Dictionary = GameData.GEAR[id]
		var lvl: int = profile.equipamentos[id]
		load_card[1].add_child(_label("%s +%d" % [g.nome, lvl], 22, C_TEXT))
		load_card[1].add_child(_label("%s · %s" % [_stat(g, lvl), _el(g.elemento)], 18, GameData.element_color(g.elemento)))
		if g.perk != "":
			load_card[1].add_child(_label("%s: %s" % [GameData.PERKS[g.perk].nome, GameData.PERKS[g.perk].descricao], 16, C_GOLD, true))

	var gfx := HBoxContainer.new()
	gfx.alignment = BoxContainer.ALIGNMENT_CENTER
	gfx.add_theme_constant_override("separation", 10)
	gfx.add_child(_label("Gráficos:", 18, C_MUTED))
	for q in Settings.NOMES.size():
		var on := Settings.quality() == q
		var b := _button(Settings.NOMES[q], func():
			Settings.set_quality(q)
			render(), on)
		b.custom_minimum_size = Vector2(130, 50)
		gfx.add_child(b)
	gfx.add_child(_label("Se travar, use Baixo.", 16, C_MUTED))
	_content.add_child(gfx)

	var who := HBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 10)
	who.add_child(_label("Personagem:", 18, C_MUTED))
	for id in Settings.PERSONAGENS:
		var b := _button(Settings.PERSONAGENS[id], func():
			Settings.set_character(id)
			render(), Settings.character() == id)
		b.custom_minimum_size = Vector2(160, 50)
		who.add_child(b)
	_content.add_child(who)

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_child(_label("Progresso salvo neste aparelho.", 16, C_MUTED))
	var reset := Button.new()
	reset.flat = true
	reset.text = "Toque de novo para apagar tudo" if _reset_armed else "Apagar progresso"
	reset.add_theme_font_size_override("font_size", 16)
	reset.add_theme_color_override("font_color", C_BAD if _reset_armed else C_MUTED)
	reset.pressed.connect(func():
		if _reset_armed:
			_reset_armed = false
			_set_profile(ProfileLogic.reset_profile(), "Progresso apagado")
		else:
			_reset_armed = true
			render())
	foot.add_child(reset)
	_content.add_child(foot)


func _render_hunts() -> void:
	_content.add_child(_label("Escolha sua presa", 30))
	var weapon: Dictionary = GameData.GEAR[profile.equipado.arma]
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 14)
	_content.add_child(grid)
	for b in GameData.BEASTS:
		var locked: bool = profile.rank < b.rank_minimo
		var c: Array = _card(GameData.element_color(b.elemento))
		c[0].size_flags_vertical = Control.SIZE_FILL
		grid.add_child(c[0])
		var v: VBoxContainer = c[1]
		v.add_child(_label(b.nome, 26, C_TEXT))
		v.add_child(_label("%s  ·  Tier %d" % [b.apelido, b.tier], 16, C_MUTED))
		v.add_child(_label(b.descricao, 17, C_TEXT, true))
		var weak := GameData.weakness_of(b.elemento)
		v.add_child(_label("Elemento: %s  ·  Fraca a: %s" % [_el(b.elemento), _el(weak) if weak != "" else "-"], 16, GameData.element_color(b.elemento).lightened(0.2), true))
		var mult := Formulas.element_multiplier(weapon.elemento, b.elemento)
		var mtxt := "vantagem x%.2f" % mult if mult > 1.0 else ("desvantagem x%.2f" % mult if mult < 1.0 else "neutro x1")
		v.add_child(_label("Sua arma: " + mtxt, 16, C_GOOD if mult > 1.0 else (C_BAD if mult < 1.0 else C_MUTED)))
		var best: Dictionary = profile.bestiario.get(b.id, {})
		if not best.is_empty():
			v.add_child(_label("Abates %d%s" % [best.abates, ("  ·  recorde %ds" % best.melhor_tempo) if best.melhor_tempo >= 0 else ""], 16, C_MUTED))
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
		if locked:
			v.add_child(_button("Requer Rank %d" % b.rank_minimo, func(): pass, false, false))
		else:
			v.add_child(_button("Caçar", func(): hunt_requested.emit(b.id), true))


func _render_forge() -> void:
	_content.add_child(_label("Forja", 30))
	_content.add_child(_label("Fabricar é garantido, sem chance de falha. Partes quebradas dão materiais extras.", 18, C_MUTED, true))
	_content.add_child(_label("FABRICAR", 16, C_MUTED))
	var any := false
	for id in GameData.GEAR_ORDER:
		if profile.equipamentos.has(id):
			continue
		any = true
		var g: Dictionary = GameData.GEAR[id]
		var c: Array = _card()
		_content.add_child(c[0])
		var v: VBoxContainer = c[1]
		var fera_nome := ""
		if g.fera != "":
			fera_nome = "  ·  da " + GameData.beast_by_id(g.fera).nome
		v.add_child(_label("%s  (%s)" % [g.nome, _el(g.elemento)], 22, GameData.element_color(g.elemento).lightened(0.3)))
		v.add_child(_label(_stat(g, 0) + fera_nome, 18, C_MUTED))
		if g.perk != "":
			v.add_child(_label("%s: %s" % [GameData.PERKS[g.perk].nome, GameData.PERKS[g.perk].descricao], 17, C_GOLD, true))
		v.add_child(_recipe_row(g.receita, g.custo))
		var ok := ProfileLogic.can_craft(profile, id)
		v.add_child(_button("Fabricar", func(): _set_profile(ProfileLogic.craft(profile, id), "Fabricado: " + g.nome), ok, ok))
	if not any:
		_content.add_child(_label("Você já fabricou tudo!", 18, C_MUTED))

	_content.add_child(_label("MELHORAR (+0 a +%d)" % GameData.MAX_UPGRADE, 16, C_MUTED))
	for id in GameData.GEAR_ORDER:
		if not profile.equipamentos.has(id):
			continue
		var g: Dictionary = GameData.GEAR[id]
		var lvl: int = profile.equipamentos[id]
		var cost := Formulas.upgrade_cost(g, lvl)
		var c: Array = _card()
		_content.add_child(c[0])
		var v: VBoxContainer = c[1]
		v.add_child(_label("%s +%d" % [g.nome, lvl], 22, C_TEXT))
		if cost.is_empty():
			v.add_child(_label(_stat(g, lvl) + "  ·  Nível máximo!", 18, C_GOOD))
			continue
		v.add_child(_label("%s  ->  %s" % [_stat(g, lvl), _stat(g, lvl + 1)], 18, C_MUTED))
		v.add_child(_recipe_row(cost.materiais, cost.moedas))
		var ok := ProfileLogic.can_upgrade(profile, id)
		v.add_child(_button("Melhorar", func(): _set_profile(ProfileLogic.upgrade(profile, id), "%s +%d" % [g.nome, lvl + 1]), ok, ok))


func _render_equip() -> void:
	_content.add_child(_label("Equipamento", 30))
	_content.add_child(_label("Use a arma do elemento que vence a fera (Fogo > Natureza > Água > Fogo) e a armadura do mesmo elemento dela.", 18, C_MUTED, true))
	for slot in ["arma", "armadura"]:
		_content.add_child(_label("ARMAS" if slot == "arma" else "ARMADURAS", 16, C_MUTED))
		for id in GameData.GEAR_ORDER:
			var g: Dictionary = GameData.GEAR[id]
			if g.slot != slot or not profile.equipamentos.has(id):
				continue
			var lvl: int = profile.equipamentos[id]
			var on: bool = profile.equipado[slot] == id
			var c: Array = _card(C_GOOD if on else Color(0, 0, 0, 0))
			_content.add_child(c[0])
			var v: VBoxContainer = c[1]
			v.add_child(_label("%s +%d  (%s)" % [g.nome, lvl, _el(g.elemento)], 22, GameData.element_color(g.elemento).lightened(0.3)))
			v.add_child(_label(_stat(g, lvl), 18, C_MUTED))
			if g.perk != "":
				v.add_child(_label("%s: %s" % [GameData.PERKS[g.perk].nome, GameData.PERKS[g.perk].descricao], 17, C_GOLD, true))
			if on:
				v.add_child(_label("Equipado", 18, C_GOOD))
			else:
				v.add_child(_button("Equipar", func(): _set_profile(ProfileLogic.equip(profile, id), "Equipado: " + g.nome)))


func _inventory_grid(items: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for k in items:
		var m: Dictionary = GameData.MATERIALS.get(k, {"nome": k, "raridade": "comum", "descricao": ""})
		var c: Array = _card(C_GOLD if m.raridade == "raro" else (Color("#3a7bd5") if m.raridade == "incomum" else Color(0, 0, 0, 0)))
		c[0].custom_minimum_size = Vector2(360, 0)
		c[1].add_child(_label("%dx %s" % [items[k], m.nome], 20, C_TEXT))
		c[1].add_child(_label(m.descricao, 15, C_MUTED, true))
		grid.add_child(c[0])
	return grid


func _render_inventory() -> void:
	_content.add_child(_label("Inventário", 30))
	if profile.inventario.is_empty():
		_content.add_child(_label("Vazio. Vá caçar!", 18, C_MUTED))
	else:
		_content.add_child(_inventory_grid(profile.inventario))


func _render_result() -> void:
	var r := _result
	var b := GameData.beast_by_id(r.fera_id)
	var c: Array = _card(C_GOLD if r.vitoria else C_BAD)
	_content.add_child(c[0])
	var v: VBoxContainer = c[1]
	v.add_child(_label("Caçada concluída!" if r.vitoria else "Caçada falhou", 36, C_GOLD if r.vitoria else C_BAD))
	v.add_child(_label("%s  ·  %d:%02d  ·  %d parte(s) quebrada(s)" % [b.nome, r.tempo / 60, r.tempo % 60, r.partes_quebradas], 20, C_MUTED))
	if _subiu > 0:
		v.add_child(_label("Subiu para o Rank %d!" % profile.rank, 24, C_GOOD))
	v.add_child(_label("+%d XP%s" % [r.xp, ("   +%d moedas" % r.moedas) if r.moedas > 0 else ""], 22, C_GOOD))
	if r.loot.is_empty():
		_content.add_child(_label("Nenhum material.", 18, C_MUTED))
	else:
		_content.add_child(_inventory_grid(r.loot))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for item in [["Ir para a Forja", func(): go("forja"), true], ["Caçar de novo", func(): hunt_requested.emit(r.fera_id), false],
			["Acampamento", func(): go("home"), false]]:
		var btn := _button(item[0], item[1], item[2])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn)
	_content.add_child(row)

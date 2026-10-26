class_name Hub
extends Control
## Acampamento: caçar, forja, equipamento, inventário e resultado da caçada.

signal hunt_requested(fera_id: String)
signal profile_changed(profile: Dictionary)

const C_BG := UiStyle.C_BG_BOTTOM
const C_TEXT := UiStyle.C_TEXT
const C_MUTED := UiStyle.C_MUTED
const C_ACCENT := UiStyle.C_GLOW
const C_GOLD := UiStyle.C_GOLD
const C_GOOD := UiStyle.C_GOOD
const C_BAD := UiStyle.C_BAD

## Equipamento recomendado (poder da arma) por tier, para o "Desafio" na escolha da caçada.
const POWER_BY_TIER := {1: 48.0, 2: 70.0, 3: 100.0}

var profile: Dictionary
var _screen := "home"
var _result: Dictionary = {}
var _subiu := 0
var _content: VBoxContainer
var _wallet: Label
var _back: Button
var _logo: Label
var _scroll: ScrollContainer
var _page: Control
var _stage: Control
var _scene: MenuScene
var _hunt_sel := ""
var _reset_armed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = make_theme()
	add_child(UiStyle.background())
	_scene = MenuScene.new()
	add_child(_scene)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	_page = margin

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	col.add_child(top)
	_back = Button.new()
	_back.text = "‹  Voltar"
	_back.custom_minimum_size = Vector2(160, 50)
	_back.pressed.connect(func(): go("home"))
	top.add_child(_back)
	_logo = _label("", 30, C_TEXT)
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
	return UiStyle.make_theme()


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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	pc.add_child(row)
	if accent.a > 0:
		var strip := ColorRect.new()
		strip.color = accent
		strip.custom_minimum_size = Vector2(5, 0)
		row.add_child(strip)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	row.add_child(v)
	return [pc, v]


func _button(text: String, cb: Callable, primary := false, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)
	b.disabled = not enabled
	if primary and enabled:
		UiStyle.style_button(b, "gold", "gold_pressed")
	b.pressed.connect(cb)
	return b


## Botão do menu principal: medalhão com ícone à esquerda, texto em caixa alta e seta.
func _menu_button(text: String, icon: String, cb: Callable, selected := false, height := 58.0) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_size_override("font_size", 24 if selected else 21)
	var look := "selected" if selected else "normal"
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := UiStyle.box(look if st != "hover" else ("selected" if selected else "hover"), 18, 6)
		if st == "pressed":
			sb = UiStyle.box("pressed", 18, 6)
		sb.content_margin_left = height + 8.0
		b.add_theme_stylebox_override(st, sb)
	var ic := MenuIcon.new(icon, height + 4.0, UiStyle.C_GOLD if selected else UiStyle.C_GLOW)
	ic.position = Vector2(-6, -2)
	b.add_child(ic)
	if selected:
		var arrow := _label("›", 40, Color.WHITE)
		arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		arrow.position += Vector2(-30, -28)
		b.add_child(arrow)
	b.pressed.connect(cb)
	return b


func _stars(n: int, total := 3) -> String:
	return "★".repeat(n) + "☆".repeat(maxi(0, total - n))


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
	for c in _stage.get_children():
		c.queue_free()
	var staged := _result.is_empty() and (_screen == "home" or _screen == "cacar")
	_page.visible = not staged
	_stage.visible = staged
	_scene.visible = staged
	_scene.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if staged else SubViewport.UPDATE_DISABLED
	_wallet.text = "Rank %d    Moedas %d" % [profile.rank, profile.moedas]
	_logo.text = {"forja": "FORJA", "equip": "EQUIPAMENTO", "inventario": "INVENTÁRIO", "opcoes": "OPÇÕES"}.get(_screen, "")
	if not _result.is_empty():
		_logo.text = "RESULTADO"
		_render_result()
	else:
		match _screen:
			"home": _render_home()
			"cacar": _render_hunts()
			"forja": _render_forge()
			"equip": _render_equip()
			"inventario": _render_inventory()
			"opcoes": _render_options()


## Menu principal: logo, lista de botões à esquerda e a fera mais forte liberada em destaque.
func _render_home() -> void:
	var featured := _featured_beast()
	_scene.show_beast(featured.id)

	var title := HBoxContainer.new()
	title.position = Vector2(40, 22)
	title.add_theme_constant_override("separation", 14)
	_stage.add_child(title)
	title.add_child(MenuIcon.new("fera", 84, UiStyle.C_GOLD))
	var tcol := VBoxContainer.new()
	tcol.add_theme_constant_override("separation", -6)
	title.add_child(tcol)
	tcol.add_child(_label("SUBA MONTE", 56, Color.WHITE))
	tcol.add_child(_label("CAÇADORES DA MONTANHA", 18, UiStyle.C_GLOW))

	_stage.add_child(_wallet_panel())

	var menu := VBoxContainer.new()
	menu.position = Vector2(48, 168)
	menu.custom_minimum_size = Vector2(430, 0)
	menu.add_theme_constant_override("separation", 10)
	_stage.add_child(menu)
	menu.add_child(_menu_button("Caçar", "cacar", go.bind("cacar"), true, 66))
	menu.add_child(_menu_button("Forja", "forja", go.bind("forja")))
	menu.add_child(_menu_button("Equipamento", "equip", go.bind("equip")))
	menu.add_child(_menu_button("Inventário", "inventario", go.bind("inventario")))
	menu.add_child(_menu_button("Opções", "opcoes", go.bind("opcoes"), false, 50))

	# Equipamento atual (canto inferior esquerdo).
	var load := PanelContainer.new()
	load.position = Vector2(48, 560)
	load.custom_minimum_size = Vector2(430, 0)
	_stage.add_child(load)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	load.add_child(lv)
	lv.add_child(_label("EQUIPADO", 15, C_MUTED))
	for slot in ["arma", "armadura"]:
		var id: String = profile.equipado[slot]
		var g: Dictionary = GameData.GEAR[id]
		var lvl: int = profile.equipamentos[id]
		lv.add_child(_label("%s +%d  ·  %s" % [g.nome, lvl, _stat(g, lvl)], 19, GameData.element_color(g.elemento).lightened(0.35)))

	# Nome da fera em destaque (canto inferior direito).
	var tag := VBoxContainer.new()
	tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tag.position += Vector2(-40, -30)
	tag.alignment = BoxContainer.ALIGNMENT_END
	_stage.add_child(tag)
	var n := _label(featured.nome.to_upper(), 34, Color.WHITE)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_child(n)
	var ap := _label("%s  ·  %s" % [featured.apelido, _stars(featured.tier)], 18, UiStyle.C_GLOW)
	ap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_child(ap)


func _featured_beast() -> Dictionary:
	var best: Dictionary = GameData.BEASTS[0]
	for b in GameData.BEASTS:
		if profile.rank >= b.rank_minimo and b.tier >= best.tier:
			best = b
	return best


func _wallet_panel() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiStyle.box("panel_dark", 18, 8))
	pc.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pc.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pc.position += Vector2(-30, 22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.add_child(_label("● %d" % profile.moedas, 22, C_GOLD))
	row.add_child(_label("RANK %d" % profile.rank, 22, Color.WHITE))
	v.add_child(row)
	var need := Formulas.xp_for_rank(profile.rank)
	var xpbar := Hud.bar(UiStyle.C_GLOW, Color("#06111c"), 8)
	xpbar.custom_minimum_size = Vector2(220, 8)
	xpbar.value = float(profile.xp) / need
	v.add_child(xpbar)
	return pc


func _render_options() -> void:
	var gfx: Array = _card(UiStyle.C_GLOW)
	_content.add_child(gfx[0])
	gfx[1].add_child(_label("GRÁFICOS", 16, C_MUTED))
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 10)
	for q in Settings.NOMES.size():
		var on := Settings.quality() == q
		var b := _button(Settings.NOMES[q], func():
			Settings.set_quality(q)
			render())
		if on:
			UiStyle.style_button(b, "selected")
		b.custom_minimum_size = Vector2(150, 54)
		grow.add_child(b)
	gfx[1].add_child(grow)
	gfx[1].add_child(_label("Baixo: mais leve (30 FPS estáveis em celulares simples). Alto: sombras e mais vegetação.", 17, C_MUTED, true))

	var look: Array = _card(UiStyle.C_GLOW)
	_content.add_child(look[0])
	look[1].add_child(_label("VISUAL DO CAÇADOR", 16, C_MUTED))
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 10)
	for id in Settings.VISUAIS:
		var b := _button(Settings.VISUAIS[id], func():
			Settings.set_outfit(id)
			render())
		if Settings.outfit() == id:
			UiStyle.style_button(b, "selected")
		b.custom_minimum_size = Vector2(170, 54)
		lrow.add_child(b)
	look[1].add_child(lrow)

	var data: Array = _card(C_BAD)
	_content.add_child(data[0])
	data[1].add_child(_label("PROGRESSO", 16, C_MUTED))
	data[1].add_child(_label("Salvo neste aparelho.", 17, C_MUTED))
	var reset := _button("Toque de novo para apagar tudo" if _reset_armed else "Apagar progresso", func():
		if _reset_armed:
			_reset_armed = false
			_set_profile(ProfileLogic.reset_profile(), "Progresso apagado")
		else:
			_reset_armed = true
			render())
	reset.custom_minimum_size = Vector2(360, 54)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if _reset_armed:
		reset.add_theme_color_override("font_color", C_BAD)
	data[1].add_child(reset)


## Escolha da caçada: lista de ilhas à esquerda, mapa 3D no meio e detalhes à direita.
func _render_hunts() -> void:
	if _hunt_sel == "":
		_hunt_sel = _featured_beast().id
	_scene.show_map(_hunt_sel, _unlocked)
	var sel := GameData.beast_by_id(_hunt_sel)

	var head := HBoxContainer.new()
	head.position = Vector2(30, 16)
	head.add_theme_constant_override("separation", 12)
	_stage.add_child(head)
	head.add_child(MenuIcon.new("cacar", 56, UiStyle.C_GOLD))
	var hc := VBoxContainer.new()
	hc.add_theme_constant_override("separation", -4)
	head.add_child(hc)
	hc.add_child(_label("CAÇAR", 32, Color.WHITE))
	hc.add_child(_label("Ilhas do Monte", 16, UiStyle.C_GLOW))
	_stage.add_child(_wallet_panel())

	# Lista de ilhas
	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", UiStyle.box("panel_dark", 10, 10))
	list_panel.position = Vector2(30, 92)
	list_panel.custom_minimum_size = Vector2(340, 0)
	_stage.add_child(list_panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list_panel.add_child(list)
	for b in GameData.BEASTS:
		var open := _unlocked(b)
		var btn := Button.new()
		btn.text = "%s\n%s   %s" % [b.nome, ("Tier %d" % b.tier) if open else ("Requer Rank %d" % b.rank_minimo), _stars(b.tier)]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 72)
		btn.add_theme_font_size_override("font_size", 19)
		if b.id == _hunt_sel:
			UiStyle.style_button(btn, "selected")
		elif not open:
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
		var strip := ColorRect.new()
		strip.color = GameData.element_color(b.elemento)
		strip.custom_minimum_size = Vector2(5, 0)
		strip.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		strip.offset_left = 4
		strip.offset_right = 9
		strip.offset_top = 6
		strip.offset_bottom = -6
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(strip)
		btn.pressed.connect(func():
			_hunt_sel = b.id
			render())
		list.add_child(btn)

	# Detalhes da ilha escolhida
	var det := PanelContainer.new()
	det.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	det.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	det.position += Vector2(-30, 92)
	det.custom_minimum_size = Vector2(400, 0)
	_stage.add_child(det)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	det.add_child(v)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	name_row.add_child(MenuIcon.new("fera", 46, GameData.element_color(sel.elemento).lightened(0.3)))
	var nc := VBoxContainer.new()
	nc.add_theme_constant_override("separation", -4)
	nc.add_child(_label(sel.nome, 28, Color.WHITE))
	nc.add_child(_label("%s  ·  %s" % [sel.apelido, _stars(sel.tier)], 16, C_GOLD))
	name_row.add_child(nc)
	v.add_child(name_row)
	var weapon: Dictionary = GameData.GEAR[profile.equipado.arma]
	var power := Formulas.gear_value(weapon, profile.equipamentos[profile.equipado.arma])
	var mult := Formulas.element_multiplier(weapon.elemento, sel.elemento)
	var ratio: float = power * mult / POWER_BY_TIER[sel.tier]
	var challenge: Array = ["LETAL", C_BAD] if ratio < 0.7 else (["DIFÍCIL", Color("#ffb070")] if ratio < 0.95 else (["NORMAL", C_TEXT] if ratio < 1.25 else ["FÁCIL", C_GOOD]))
	var ch := PanelContainer.new()
	ch.add_theme_stylebox_override("panel", UiStyle.box("panel_dark", 12, 6))
	ch.add_child(_label("Desafio: %s  (com seu equipamento)" % challenge[0], 17, challenge[1]))
	v.add_child(ch)
	v.add_child(_label(sel.descricao, 16, C_TEXT, true))
	var weak := GameData.weakness_of(sel.elemento)
	v.add_child(_label("Elemento: %s  ·  Fraca a: %s" % [_el(sel.elemento), _el(weak)], 16, GameData.element_color(sel.elemento).lightened(0.3)))
	var mtxt := "vantagem x%.2f" % mult if mult > 1.0 else ("desvantagem x%.2f" % mult if mult < 1.0 else "neutra")
	v.add_child(_label("Sua arma: %s" % mtxt, 16, C_GOOD if mult > 1.0 else (C_BAD if mult < 1.0 else C_MUTED)))
	v.add_child(_label("PARTES QUEBRÁVEIS", 14, C_MUTED))
	var parts := []
	for pt in sel.partes:
		parts.append("%s → %s" % [pt.nome, GameData.material_name(pt.drop)])
	v.add_child(_label("\n".join(parts), 15, C_TEXT, true))
	v.add_child(_label("MATERIAIS", 14, C_MUTED))
	var loot := []
	for l in sel.loot:
		loot.append(GameData.material_name(l.item))
	v.add_child(_label(", ".join(loot), 15, C_TEXT, true))
	var best: Dictionary = profile.bestiario.get(sel.id, {})
	if not best.is_empty():
		v.add_child(_label("Abates %d%s" % [best.abates, ("  ·  recorde %ds" % best.melhor_tempo) if best.melhor_tempo >= 0 else ""], 15, C_MUTED))

	# Iniciar / voltar
	var actions := HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	actions.grow_vertical = Control.GROW_DIRECTION_BEGIN
	actions.position += Vector2(-30, -24)
	actions.add_theme_constant_override("separation", 12)
	_stage.add_child(actions)
	var back := _button("Voltar", go.bind("home"))
	back.custom_minimum_size = Vector2(140, 64)
	actions.add_child(back)
	var open_sel := _unlocked(sel)
	var start := _button("INICIAR" if open_sel else "Requer Rank %d" % sel.rank_minimo, func(): hunt_requested.emit(sel.id), true, open_sel)
	start.custom_minimum_size = Vector2(250, 64)
	start.add_theme_font_size_override("font_size", 30)
	actions.add_child(start)


func _unlocked(b: Dictionary) -> bool:
	return profile.rank >= b.rank_minimo


func _render_forge() -> void:
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

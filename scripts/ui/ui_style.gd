class_name UiStyle
extends RefCounted
## Visual dos menus (inspirado no Dauntless): botões e painéis azul-aço com degradê e borda
## chanfrada, gerados por código como texturas de 9 partes (nítidas em qualquer tamanho).

const C_BG_TOP := Color("#0d2236")
const C_BG_BOTTOM := Color("#050b14")
const C_TEXT := Color("#eef6ff")
const C_MUTED := Color("#8fb0cc")
const C_LINE := Color("#4f87b3")
const C_GLOW := Color("#7fd3ff")
const C_GOLD := Color("#ffd479")
const C_GOOD := Color("#7ee8a8")
const C_BAD := Color("#ff7a7a")

## estilo → [topo, base, borda clara, borda escura]
const LOOKS := {
	"normal": ["#2b5878", "#112a40", "#6aa6d0", "#050d16"],
	"hover": ["#36709a", "#163652", "#8cc7f0", "#050d16"],
	"pressed": ["#123049", "#1d4565", "#4f87b3", "#050d16"],
	"selected": ["#3f9ae0", "#14508a", "#bfe8ff", "#06182a"],
	"disabled": ["#1c2f40", "#0e1a26", "#30495e", "#050d16"],
	"gold": ["#ffe08a", "#c8862a", "#fff4c8", "#3a2408"],
	"gold_pressed": ["#c8862a", "#ffd479", "#fff4c8", "#3a2408"],
	"panel": ["#14304a", "#0a1828", "#3f739c", "#02070d"],
	"panel_dark": ["#0c1c2c", "#07121e", "#2c5476", "#02070d"],
}

static var _cache := {}


## Textura 9 partes: degradê vertical, borda escura por fora, fio claro por dentro e brilho no topo.
static func texture(look: String) -> ImageTexture:
	if _cache.has(look):
		return _cache[look]
	var c: Array = LOOKS[look]
	var top := Color(c[0])
	var bottom := Color(c[1])
	var light := Color(c[2])
	var dark := Color(c[3])
	var w := 48
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / (h - 1)
		var base := top.lerp(bottom, t)
		if y < h * 0.45:
			base = base.lightened(0.08 * (1.0 - y / (h * 0.45)))
		for x in w:
			var edge := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			var col := base
			# Cantos chanfrados (corte de 3 px).
			if (x + y < 3) or (w - 1 - x + y < 3) or (x + h - 1 - y < 3) or (w - 1 - x + h - 1 - y < 3):
				col = Color(0, 0, 0, 0)
			elif edge == 0:
				col = dark
			elif edge == 1:
				col = light if y < h / 2 else light.darkened(0.35)
			elif edge == 2:
				col = base.lerp(light, 0.25)
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache[look] = tex
	return tex


static func box(look: String, margin_h := 18.0, margin_v := 10.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = texture(look)
	sb.set_texture_margin_all(6)
	sb.content_margin_left = margin_h
	sb.content_margin_right = margin_h
	sb.content_margin_top = margin_v
	sb.content_margin_bottom = margin_v
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	t.set_stylebox("normal", "Button", box("normal"))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("hover", "Button", box("hover"))
	t.set_stylebox("pressed", "Button", box("pressed"))
	t.set_stylebox("disabled", "Button", box("disabled"))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "Button", C_TEXT)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.6))
	t.set_constant("outline_size", "Button", 3)
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.55))
	t.set_constant("outline_size", "Label", 3)
	t.set_stylebox("panel", "PanelContainer", box("panel", 20, 16))
	t.set_stylebox("panel", "Panel", box("panel_dark", 0, 0))
	return t


## Aplica um estilo fixo a um botão (ex.: item selecionado ou botão dourado).
static func style_button(b: Button, look: String, pressed_look := "") -> void:
	var sb := box(look)
	for s in ["normal", "hover", "focus"]:
		b.add_theme_stylebox_override(s, sb)
	b.add_theme_stylebox_override("pressed", box(pressed_look if pressed_look != "" else look))
	if look.begins_with("gold"):
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, Color("#2a1604"))
		b.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))


## Fundo em degradê azul-escuro (usado atrás dos menus).
static func background() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, C_BG_TOP)
	g.set_color(1, C_BG_BOTTOM)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.3, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

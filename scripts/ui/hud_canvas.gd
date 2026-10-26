class_name HudCanvas
extends Control
## Desenho do HUD da caçada (conceito final do projeto): brasão em losango com barras
## inclinadas (vida, stamina e foco), barra da fera com pontas de seta, abas das partes e
## painel do tempo. Tudo em polígonos, sem imagens.

const C_FRAME := Color(0.02, 0.06, 0.1, 0.82)
const C_STEEL := Color("#a9bccb")
const C_STEEL_DARK := Color("#3a5468")
const C_CYAN := Color("#55d8ff")

var font: Font
## Valores atualizados pelo Hud a cada quadro.
var d := {
	"hp": 1.0, "hp_ghost": 1.0, "st": 1.0, "focus": 0.0, "charging": false, "sharp": false,
	"level": 0, "max_level": 10, "faints": 0, "max_faints": 3, "weapon": "", "weapon_color": Color.WHITE,
	"beast": "", "beast_color": Color.GREEN, "beast_hp": 1.0, "beast_ghost": 1.0, "fury": false,
	"parts": [], "action": "", "time": "0:00", "fps": "", "compass": 0.0, "compass_on": false,
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


# ------------------------------------------------------------ primitivas

static func diamond(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])


func _gradient_poly(pts: PackedVector2Array, top: Color, bottom: Color) -> void:
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, (p.y - y0) / maxf(1.0, y1 - y0)))
	draw_polygon(pts, cols)


func _outline(pts: PackedVector2Array, col: Color, w := 2.0) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, col, w, true)


func _text(pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, outline := 5) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		p.x -= w / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		p.x -= w
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0, 0, 0, 0.75))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Barra inclinada: começa reta na esquerda e termina em "/" na direita.
func _slant(x: float, y: float, length: float, h: float, frac: float) -> PackedVector2Array:
	var e := x + length * clampf(frac, 0.0, 1.0)
	return PackedVector2Array([Vector2(x, y), Vector2(e + h, y), Vector2(e, y + h), Vector2(x, y + h)])


func _slant_bar(x: float, y: float, length: float, h: float, frac: float, top: Color, bottom: Color, ghost := -1.0) -> void:
	var frame := _slant(x - 3, y - 3, length + 6, h + 6, 1.0)
	draw_colored_polygon(frame, C_FRAME)
	if ghost > frac:
		draw_colored_polygon(_slant(x, y, length, h, ghost), Color(1, 1, 1, 0.55))
	if frac > 0.002:
		_gradient_poly(_slant(x, y, length, h, frac), top, bottom)
		draw_line(Vector2(x, y + 1), Vector2(x + length * frac + h - 1, y + 1), Color(1, 1, 1, 0.35), 1.5)
	_outline(frame, C_STEEL_DARK, 1.5)


## Barra com pontas de seta nas duas extremidades (vida da fera).
func _arrow_shape(x0: float, x1: float, y: float, h: float, a: float) -> PackedVector2Array:
	var cy := y + h / 2.0
	return PackedVector2Array([Vector2(x0, cy), Vector2(x0 + a, y), Vector2(x1 - a, y), Vector2(x1, cy),
		Vector2(x1 - a, y + h), Vector2(x0 + a, y + h)])


func _arrow_fill(x0: float, x1: float, y: float, h: float, a: float, frac: float) -> PackedVector2Array:
	var fx := lerpf(x0 + a, x1 - a, clampf(frac, 0.0, 1.0))
	var cy := y + h / 2.0
	return PackedVector2Array([Vector2(x0, cy), Vector2(x0 + a, y), Vector2(fx, y), Vector2(fx, y + h), Vector2(x0 + a, y + h)])


# ------------------------------------------------------------ desenho

func _draw() -> void:
	_draw_player()
	_draw_beast()
	_draw_clock()


func _draw_player() -> void:
	var c := Vector2(66, 62)
	# Brasão do caçador: losango duplo com três lâminas.
	draw_colored_polygon(diamond(c, 50), Color(0.01, 0.04, 0.08, 0.9))
	_gradient_poly(diamond(c, 44), Color("#16405e"), Color("#06192a"))
	_outline(diamond(c, 50), C_STEEL, 2.0)
	_outline(diamond(c, 44), C_CYAN, 2.0)
	for k in [-1, 0, 1]:
		var tip := c + Vector2(k * 9, -26 + absf(k) * 6)
		var base := c + Vector2(k * 4, 18)
		var pts := PackedVector2Array([tip, base + Vector2(4, 0), base + Vector2(-4, 0)])
		draw_colored_polygon(pts, Color(0.95, 0.98, 1.0))
	draw_line(c + Vector2(-12, 8), c + Vector2(12, 8), Color(0.95, 0.98, 1.0), 3.0)

	var x := 118.0
	var bw := clampf(size.x * 0.21, 220.0, 400.0)
	_slant_bar(x, 22, bw, 18, d.hp, Color("#5fe08a"), Color("#1f8f45"), d.hp_ghost)
	_slant_bar(x, 48, bw * 0.94, 10, d.st, Color("#fff27a"), Color("#d6a514"))
	var ftop := Color("#9fe6ff") if d.charging else Color("#4fb6ff")
	_slant_bar(x, 66, bw * 0.55, 9, d.focus, ftop, Color("#1a5fd0"))
	if d.sharp:
		_outline(_slant(x - 3, 63, bw * 0.55 + 6, 15, 1.0), Color("#ffe066"), 2.0)

	# Nível da arma em losangos.
	for i in d.max_level:
		var dc := Vector2(x + 8 + i * 19, 96)
		draw_colored_polygon(diamond(dc, 7), C_FRAME)
		if i < d.level:
			draw_colored_polygon(diamond(dc, 5), C_CYAN)
		_outline(diamond(dc, 7), C_STEEL_DARK, 1.2)

	_text(Vector2(36, 140), "Desmaios  %d/%d" % [d.faints, d.max_faints], 19, Color("#ff8f8f"))
	# Arma com fundo em degradê e ícone de espada.
	var strip := PackedVector2Array([Vector2(28, 152), Vector2(300, 152), Vector2(286, 178), Vector2(28, 178)])
	draw_polygon(strip, PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.55)]))
	draw_line(Vector2(40, 174), Vector2(54, 158), Color.WHITE, 3.0)
	draw_line(Vector2(39, 166), Vector2(46, 173), Color.WHITE, 2.0)
	_text(Vector2(64, 172), d.weapon, 18, d.weapon_color.lightened(0.5))


func _draw_beast() -> void:
	var w := clampf(size.x * 0.34, 380.0, 640.0)
	var cx := size.x / 2.0
	var x0 := cx - w / 2.0
	var x1 := cx + w / 2.0
	var y := 54.0
	var h := 20.0
	# Faixa escura atrás do nome.
	var top := PackedVector2Array([Vector2(cx - 170, 8), Vector2(cx + 170, 8), Vector2(cx + 150, 46), Vector2(cx - 150, 46)])
	draw_polygon(top, PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55)]))
	var ec := Vector2(cx - 150, 28)
	draw_colored_polygon(diamond(ec, 22), Color(0.01, 0.04, 0.06, 0.9))
	_gradient_poly(diamond(ec, 18), d.beast_color.lightened(0.2), d.beast_color.darkened(0.5))
	_outline(diamond(ec, 22), C_STEEL, 1.6)
	for k in 3:
		var bx := ec.x + (k - 1) * 5.0
		draw_line(Vector2(bx - 2, ec.y - 8), Vector2(bx + 2, ec.y + 8), Color(0.02, 0.08, 0.04), 2.2)
	_text(Vector2(cx + 10, 40), d.beast, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	if d.fury:
		_text(Vector2(cx + 150, 40), "FÚRIA", 18, Color("#ff5a5a"))

	var frame := _arrow_shape(x0 - 6, x1 + 6, y - 4, h + 8, 18)
	draw_colored_polygon(frame, C_FRAME)
	var bshape := _arrow_shape(x0, x1, y, h, 14)
	if d.beast_ghost > d.beast_hp:
		draw_colored_polygon(_arrow_fill(x0, x1, y, h, 14, d.beast_ghost), Color(1, 1, 1, 0.5))
	var hot := Color("#ff7a3a") if d.fury else Color("#ff4a2a")
	if d.beast_hp > 0.001:
		_gradient_poly(_arrow_fill(x0, x1, y, h, 14, d.beast_hp), hot, Color("#a3120c"))
	_outline(frame, C_STEEL, 1.6)
	_outline(bshape, Color(0, 0, 0, 0.5), 1.0)
	# Setas decorativas fora das pontas.
	for sgn in [-1.0, 1.0]:
		var ex: float = (x0 - 14) if sgn < 0 else (x1 + 14)
		var tri := PackedVector2Array([Vector2(ex, y + h / 2), Vector2(ex - sgn * 10, y - 4), Vector2(ex - sgn * 10, y + h + 4)])
		draw_colored_polygon(tri, C_STEEL)

	# Partes: aba escura com o nome e um losango de estado embaixo.
	var parts: Array = d.parts
	var n := parts.size()
	var tab_w := 104.0
	for i in n:
		var pc := Vector2(cx + (i - (n - 1) / 2.0) * (tab_w + 8), 92)
		var tab := PackedVector2Array([pc + Vector2(-tab_w / 2, -14), pc + Vector2(tab_w / 2, -14),
			pc + Vector2(tab_w / 2 - 8, 12), pc + Vector2(-tab_w / 2 + 8, 12)])
		draw_colored_polygon(tab, Color(0.02, 0.06, 0.1, 0.6))
		var p: Dictionary = parts[i]
		var col := Color.WHITE
		if p.quebrada:
			col = Color("#6ee7a0")
		elif p.ferida:
			col = Color("#fdba74")
		_text(pc + Vector2(0, 6), p.nome, 18, col, HORIZONTAL_ALIGNMENT_CENTER, 4)
		draw_colored_polygon(diamond(pc + Vector2(0, 22), 6), col)
		_outline(diamond(pc + Vector2(0, 22), 6), Color(0, 0, 0, 0.6), 1.0)
	if d.action != "":
		_text(Vector2(cx, 140), "! %s !" % d.action, 22, Color("#ffb3a3"), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_clock() -> void:
	var right := size.x - 24.0
	# Losango da pausa (o botão de verdade fica por cima).
	var pc := Vector2(right - 38, 52)
	draw_colored_polygon(diamond(pc, 40), Color(0.01, 0.04, 0.08, 0.9))
	_gradient_poly(diamond(pc, 34), Color("#2a5878"), Color("#0a1a2a"))
	_outline(diamond(pc, 40), C_STEEL, 2.0)
	draw_rect(Rect2(pc + Vector2(-10, -12), Vector2(7, 24)), Color.WHITE)
	draw_rect(Rect2(pc + Vector2(3, -12), Vector2(7, 24)), Color.WHITE)
	# Painel do tempo com cantos chanfrados.
	var x1 := right - 82
	var x0 := x1 - 180
	var panel := PackedVector2Array([Vector2(x0 + 18, 18), Vector2(x1, 18), Vector2(x1 + 14, 52), Vector2(x1, 86),
		Vector2(x0 + 18, 86), Vector2(x0, 52)])
	_gradient_poly(panel, Color(0.05, 0.12, 0.18, 0.85), Color(0.01, 0.03, 0.06, 0.85))
	_outline(panel, C_STEEL, 1.6)
	_text(Vector2((x0 + x1) / 2.0 + 6, 56), d.time, 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2((x0 + x1) / 2.0 + 6, 78), d.fps, 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 3)
	# Bússola: seta laranja apontando para a fera (em relação à câmera).
	if d.compass_on:
		var cc := Vector2(x0 - 26, 52)
		var a: float = d.compass
		var fwd := Vector2(sin(a), -cos(a))
		var side := Vector2(-fwd.y, fwd.x)
		var tri := PackedVector2Array([cc + fwd * 14, cc - fwd * 9 + side * 9, cc - fwd * 4, cc - fwd * 9 - side * 9])
		draw_colored_polygon(tri, Color("#ff9a2a"))
		_outline(tri, Color(0, 0, 0, 0.7), 1.2)

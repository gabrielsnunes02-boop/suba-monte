class_name MenuIcon
extends Control
## Medalhão redondo com um símbolo desenhado por código (sem imagens): caçar, forja,
## equipamento, inventário, opções, estrela...

var kind := "cacar"
var tint := Color("#7fd3ff")


func _init(k := "cacar", size_px := 52.0, color := Color("#7fd3ff")) -> void:
	kind = k
	tint = color
	custom_minimum_size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 1.0
	draw_circle(c, r, Color("#050d16"))
	draw_circle(c, r - 2.0, Color("#c9d6e2"))
	draw_circle(c, r - 4.0, Color("#1a3550"))
	draw_circle(c, r - 7.0, Color("#244a6c"))
	draw_arc(c, r - 7.0, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.25), 2.0)
	var s := (r - 8.0) / 10.0
	var col := tint
	var line := 2.4 * s
	match kind:
		"cacar":
			# Espada inclinada com guarda.
			var a := c + Vector2(-6, 6) * s
			var b := c + Vector2(6, -6) * s
			draw_line(a, b, col, line * 1.4)
			draw_line(c + Vector2(-7, 2) * s, c + Vector2(-2, 7) * s, col, line)
			draw_line(a, a + Vector2(-2.5, 2.5) * s, col.darkened(0.3), line * 1.6)
		"forja":
			# Martelo sobre a bigorna.
			draw_rect(Rect2(c + Vector2(-7, 2) * s, Vector2(14, 3.5) * s), col)
			draw_rect(Rect2(c + Vector2(-3, 5.5) * s, Vector2(6, 2.5) * s), col)
			draw_line(c + Vector2(-5, -1) * s, c + Vector2(3, -8) * s, col, line)
			draw_rect(Rect2(c + Vector2(1, -9.5) * s, Vector2(6, 3.5) * s), col)
		"equip":
			# Escudo.
			var pts := PackedVector2Array([c + Vector2(-7, -7) * s, c + Vector2(7, -7) * s, c + Vector2(6, 2) * s,
				c + Vector2(0, 8) * s, c + Vector2(-6, 2) * s])
			draw_colored_polygon(pts, col)
			draw_line(c + Vector2(0, -6) * s, c + Vector2(0, 6) * s, Color("#1a3550"), line * 0.8)
		"inventario":
			# Bolsa.
			draw_circle(c + Vector2(0, 2) * s, 6.5 * s, col)
			draw_rect(Rect2(c + Vector2(-3, -7) * s, Vector2(6, 4) * s), col)
			draw_line(c + Vector2(-4, -3) * s, c + Vector2(4, -3) * s, Color("#1a3550"), line * 0.7)
		"opcoes":
			# Engrenagem.
			for i in 8:
				var ang := i * TAU / 8.0
				draw_line(c + Vector2(cos(ang), sin(ang)) * 4.0 * s, c + Vector2(cos(ang), sin(ang)) * 8.0 * s, col, line * 1.3)
			draw_circle(c, 5.0 * s, col)
			draw_circle(c, 2.2 * s, Color("#244a6c"))
		"fera":
			# Garras.
			for i in 3:
				var x := (i - 1) * 4.0
				draw_line(c + Vector2(x - 2, -7) * s, c + Vector2(x + 2, 7) * s, col, line)
		_:
			draw_circle(c, 4.0 * s, col)

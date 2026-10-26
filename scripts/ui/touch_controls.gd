class_name TouchControls
extends Control
## Controles de toque com multitoque: joystick (esquerda), arrastar para girar a câmera (direita)
## e botões de ação. Os botões disparam as mesmas ações do teclado/controle (InputMap).

const JOY_RADIUS := 80.0

var camera_rig: CameraRig
var _buttons: Array[Dictionary] = []
var _touches := {}  # índice → {"kind": "joy"|"cam"|"btn", "btn": i, "last": Vector2}
var _joy_origin := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _joy_active := false
var _font: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	_buttons = [
		{"action": "attack", "label": "ATACAR", "sub": "toque / segure", "r": 80.0, "off": Vector2(-112, -112), "color": Color("#ff5a1f"), "icon": "espada"},
		{"action": "dodge", "label": "ESQUIVA", "sub": "", "r": 60.0, "off": Vector2(-272, -84), "color": Color("#2f86ff"), "icon": "corrida"},
		{"action": "potion", "label": "POÇÃO", "sub": "", "r": 52.0, "off": Vector2(-102, -292), "color": Color("#2fd36a"), "icon": "pocao"},
		{"action": "lock_on", "label": "MIRA", "sub": "", "r": 50.0, "off": Vector2(-252, -236), "color": Color("#ffc23a"), "icon": "mira"},
	]


func set_potions(n: int) -> void:
	_buttons[2].label = "POÇÃO x%d" % n
	queue_redraw()


func _button_center(b: Dictionary) -> Vector2:
	var safe := DisplayServer.get_display_safe_area()
	var right_inset := 0.0
	var bottom_inset := 0.0
	var win := DisplayServer.window_get_size()
	if safe.size.x > 0 and win.x > 0:
		var scale_f := size.x / float(win.x)
		right_inset = (win.x - safe.end.x) * scale_f
		bottom_inset = (win.y - safe.end.y) * scale_f
	return Vector2(size.x - right_inset, size.y - bottom_inset) + b.off


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		var pos := t.position
		if t.pressed:
			if pos.y < size.y * 0.14:
				return  # faixa do HUD (pausa)
			for i in _buttons.size():
				if pos.distance_to(_button_center(_buttons[i])) <= _buttons[i].r * 1.15:
					_touches[t.index] = {"kind": "btn", "btn": i}
					Input.action_press(_buttons[i].action)
					get_viewport().set_input_as_handled()
					queue_redraw()
					return
			if pos.x < size.x * 0.45:
				_touches[t.index] = {"kind": "joy"}
				_joy_origin = pos
				_joy_vec = Vector2.ZERO
				_joy_active = true
			else:
				_touches[t.index] = {"kind": "cam", "last": pos}
			queue_redraw()
		elif _touches.has(t.index):
			var info: Dictionary = _touches[t.index]
			if info.kind == "btn":
				Input.action_release(_buttons[info.btn].action)
			elif info.kind == "joy":
				_joy_active = false
				_joy_vec = Vector2.ZERO
				_apply_joy()
			_touches.erase(t.index)
			queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if not _touches.has(d.index):
			return
		var info: Dictionary = _touches[d.index]
		if info.kind == "joy":
			var v := d.position - _joy_origin
			_joy_vec = v.limit_length(JOY_RADIUS) / JOY_RADIUS
			_apply_joy()
			queue_redraw()
		elif info.kind == "cam" and camera_rig:
			camera_rig.look(d.position - info.last)
			info.last = d.position


func _apply_joy() -> void:
	var v := _joy_vec
	_set_axis("move_left", "move_right", v.x)
	_set_axis("move_forward", "move_back", v.y)


func _set_axis(neg: String, pos: String, value: float) -> void:
	if value < -0.05:
		Input.action_press(neg, -value)
		Input.action_release(pos)
	elif value > 0.05:
		Input.action_press(pos, value)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func release_all() -> void:
	for idx in _touches:
		var info: Dictionary = _touches[idx]
		if info.kind == "btn":
			Input.action_release(_buttons[info.btn].action)
	_touches.clear()
	_joy_vec = Vector2.ZERO
	_joy_active = false
	_apply_joy()


func _draw() -> void:
	_draw_joystick()
	for i in _buttons.size():
		_draw_button(i)


## Joystick com anel duplo e quatro losangos nos pontos cardeais.
func _draw_joystick() -> void:
	var base := _joy_origin if _joy_active else Vector2(170, size.y - 150)
	var a := 0.9 if _joy_active else 0.65
	draw_circle(base, JOY_RADIUS + 10, Color(0.0, 0.03, 0.06, 0.35 * a))
	draw_arc(base, JOY_RADIUS + 10, 0, TAU, 64, Color(0.75, 0.82, 0.9, 0.55 * a), 2.0, true)
	draw_arc(base, JOY_RADIUS, 0, TAU, 64, Color(0.75, 0.82, 0.9, 0.35 * a), 1.5, true)
	for k in 4:
		var dir := Vector2.from_angle(k * PI / 2.0)
		var dc := base + dir * (JOY_RADIUS + 10)
		draw_colored_polygon(HudCanvas.diamond(dc, 8), Color(0.85, 0.9, 0.95, 0.85 * a))
	var knob := base + _joy_vec * JOY_RADIUS
	draw_circle(knob, 40, Color(0, 0, 0, 0.25))
	for k in 5:
		var t := k / 4.0
		draw_circle(knob + Vector2(-3, -3) * t, 36.0 - k * 5.0, Color(0.62, 0.66, 0.7, 0.85).lerp(Color(0.93, 0.95, 0.97, 0.9), t))
	draw_arc(knob, 36, 0, TAU, 40, Color(1, 1, 1, 0.5), 1.5, true)


## Botão redondo: brilho colorido, anel metálico, fundo escuro em degradê, ícone e nome.
func _draw_button(i: int) -> void:
	var b: Dictionary = _buttons[i]
	var c := _button_center(b)
	var r: float = b.r
	var held := false
	for idx in _touches:
		if _touches[idx].kind == "btn" and _touches[idx].btn == i:
			held = true
	var col: Color = b.color
	var active: bool = b.action == "lock_on" and camera_rig != null and camera_rig.locked
	if held or active:
		col = col.lightened(0.3)
	# Brilho externo.
	for k in 3:
		draw_circle(c, r + 10 - k * 3, Color(col.r, col.g, col.b, 0.10 + k * 0.05))
	# Fundo: do escuro na borda para a cor no centro.
	for k in 12:
		var t := k / 11.0
		draw_circle(c, r - 4 - k * (r * 0.06), Color(0.02, 0.04, 0.07, 0.9).lerp(col.darkened(0.3), t * t * 0.8))
	# Anel metálico e fio colorido.
	draw_arc(c, r, 0, TAU, 64, Color("#c9d6e2"), 4.0, true)
	draw_arc(c, r - 4, 0, TAU, 64, Color(0.02, 0.05, 0.08), 2.0, true)
	draw_arc(c, r - 7, 0, TAU, 64, col.lightened(0.2), 2.5, true)
	for k in 4:
		var dc := c + Vector2.from_angle(PI / 4.0 + k * PI / 2.0) * r
		draw_colored_polygon(HudCanvas.diamond(dc, 4), Color("#c9d6e2"))
	_icon(b.icon, c + Vector2(0, -r * 0.24), r * 0.33, Color(1, 1, 1, 0.95))
	var fs := 22 if r > 70 else (19 if r > 55 else 17)
	var w := _font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	var ty := r * 0.38 if b.sub == "" else r * 0.3
	draw_string_outline(_font, c + Vector2(-w / 2, ty + fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.75))
	draw_string(_font, c + Vector2(-w / 2, ty + fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	if b.sub != "":
		var sw := _font.get_string_size(b.sub, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
		draw_string_outline(_font, c + Vector2(-sw / 2, ty + fs * 0.35 + 18), b.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.7))
		draw_string(_font, c + Vector2(-sw / 2, ty + fs * 0.35 + 18), b.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.85))


func _icon(kind: String, c: Vector2, s: float, col: Color) -> void:
	var u := s / 10.0
	match kind:
		"espada":
			draw_line(c + Vector2(-7, 7) * u, c + Vector2(8, -8) * u, col, 3.2 * u)
			draw_colored_polygon(PackedVector2Array([c + Vector2(8, -8) * u, c + Vector2(10, -10) * u, c + Vector2(9, -6.5) * u]), col)
			draw_line(c + Vector2(-9, 1) * u, c + Vector2(-1, 9) * u, col, 2.6 * u)
			draw_line(c + Vector2(-7, 7) * u, c + Vector2(-10, 10) * u, col, 3.4 * u)
		"corrida":
			# Figura correndo: cabeça, tronco inclinado, braços e pernas abertos.
			draw_circle(c + Vector2(3, -8) * u, 2.2 * u, col)
			draw_line(c + Vector2(2, -5) * u, c + Vector2(-1, 2) * u, col, 2.6 * u)
			draw_polyline(PackedVector2Array([c + Vector2(-6, -3) * u, c + Vector2(0, -4) * u, c + Vector2(4, -1) * u, c + Vector2(7, -3) * u]), col, 2.2 * u)
			draw_polyline(PackedVector2Array([c + Vector2(-1, 2) * u, c + Vector2(4, 5) * u, c + Vector2(3, 10) * u]), col, 2.4 * u)
			draw_polyline(PackedVector2Array([c + Vector2(-1, 2) * u, c + Vector2(-5, 6) * u, c + Vector2(-9, 5) * u]), col, 2.4 * u)
			for k in 3:
				draw_line(c + Vector2(-12, -4 + k * 3) * u, c + Vector2(-8.5, -4 + k * 3) * u, Color(col.r, col.g, col.b, 0.6), 1.4 * u)
		"mira":
			draw_arc(c, 7 * u, 0, TAU, 32, col, 2.0 * u, true)
			draw_arc(c, 3 * u, 0, TAU, 20, col, 1.6 * u, true)
			for k in 4:
				var dir := Vector2.from_angle(k * PI / 2.0)
				draw_line(c + dir * 5 * u, c + dir * 11 * u, col, 2.0 * u)
		"pocao":
			draw_circle(c + Vector2(0, 3) * u, 6.5 * u, col)
			draw_circle(c + Vector2(0, 4) * u, 5.0 * u, Color("#3dff86"))
			draw_rect(Rect2(c + Vector2(-2.2, -8) * u, Vector2(4.4, 6) * u), col)
			draw_rect(Rect2(c + Vector2(-3, -10) * u, Vector2(6, 2.5) * u), Color("#c9a070"))
			draw_circle(c + Vector2(-2, 2) * u, 1.3 * u, Color(1, 1, 1, 0.8))

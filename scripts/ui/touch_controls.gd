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
		{"action": "attack", "label": "ATACAR", "sub": "toque / segure", "r": 78.0, "off": Vector2(-110, -110), "color": Color(0.91, 0.42, 0.12, 0.55)},
		{"action": "dodge", "label": "ESQUIVA", "sub": "", "r": 56.0, "off": Vector2(-265, -80), "color": Color(0.15, 0.39, 0.92, 0.5)},
		{"action": "potion", "label": "POÇÃO", "sub": "", "r": 46.0, "off": Vector2(-105, -275), "color": Color(0.09, 0.64, 0.29, 0.5)},
		{"action": "lock_on", "label": "MIRA", "sub": "", "r": 40.0, "off": Vector2(-245, -215), "color": Color(0.6, 0.6, 0.7, 0.45)},
	]


func set_potions(n: int) -> void:
	_buttons[2].label = "POÇÃO ×%d" % n
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
	# Joystick
	var base := _joy_origin if _joy_active else Vector2(150, size.y - 150)
	draw_circle(base, JOY_RADIUS, Color(1, 1, 1, 0.08 if not _joy_active else 0.14))
	draw_arc(base, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.3), 3.0, true)
	draw_circle(base + _joy_vec * JOY_RADIUS, 34, Color(1, 1, 1, 0.65))

	# Botões
	for i in _buttons.size():
		var b: Dictionary = _buttons[i]
		var c := _button_center(b)
		var held := false
		for idx in _touches:
			if _touches[idx].kind == "btn" and _touches[idx].btn == i:
				held = true
		var col: Color = b.color
		if held:
			col = col.lightened(0.35)
		if b.action == "lock_on" and camera_rig and camera_rig.locked:
			col = Color(0.95, 0.75, 0.2, 0.6)
		draw_circle(c, b.r, col)
		draw_arc(c, b.r, 0, TAU, 48, Color(1, 1, 1, 0.45), 3.0, true)
		var fs := 22 if b.r > 50 else 16
		var w := _font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string_outline(_font, c + Vector2(-w / 2, fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.6))
		draw_string(_font, c + Vector2(-w / 2, fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		if b.sub != "":
			var sw := _font.get_string_size(b.sub, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
			draw_string(_font, c + Vector2(-sw / 2, fs * 0.35 + 20), b.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.8))

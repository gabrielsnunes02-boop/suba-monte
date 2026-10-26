class_name Hud
extends CanvasLayer
## HUD da caçada: vida/stamina, fera (vida, fúria, partes, ataque em preparo), tempo, avisos e pausa.

signal resume_requested
signal quit_requested
signal pause_requested

var canvas := HudCanvas.new()
var render_scale := 1.0
var info_label: Label
var banner_label: Label
var pause_panel: Control
var _banner_tween: Tween
var _beast_def: Dictionary
var _hp_ghost := 1.0
var _beast_ghost := 1.0


static func bar(fill: Color, bg := Color(0, 0, 0, 0.55), h := 14.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	b.max_value = 1.0
	b.step = 0.0
	b.value = 1.0
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = bg
	sb_bg.set_corner_radius_all(int(h / 2))
	sb_bg.border_color = Color(1, 1, 1, 0.18)
	sb_bg.set_border_width_all(1)
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = fill
	sb_fill.set_corner_radius_all(int(h / 2))
	b.add_theme_stylebox_override("background", sb_bg)
	b.add_theme_stylebox_override("fill", sb_fill)
	return b


static func label(text: String, size := 20, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	return l


func build(beast_def: Dictionary, weapon: Dictionary, weapon_level: int) -> void:
	layer = 1
	_beast_def = beast_def
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.make_theme()
	add_child(root)
	root.add_child(canvas)
	canvas.d.weapon = "%s +%d" % [weapon.nome, weapon_level]
	canvas.d.weapon_color = GameData.element_color(weapon.elemento)
	canvas.d.level = weapon_level
	canvas.d.max_level = GameData.MAX_UPGRADE
	canvas.d.max_faints = GameData.PLAYER.desmaios_maximos
	canvas.d.beast = beast_def.nome
	canvas.d.beast_color = GameData.element_color(beast_def.elemento)

	# Botão de pausa invisível sobre o losango desenhado no canto.
	var pause_btn := Button.new()
	pause_btn.flat = true
	pause_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -110
	pause_btn.offset_right = -14
	pause_btn.offset_top = 6
	pause_btn.offset_bottom = 100
	for st in ["normal", "hover", "pressed", "focus"]:
		pause_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	pause_btn.pressed.connect(func(): pause_requested.emit())
	root.add_child(pause_btn)

	# Aviso central
	banner_label = label("", 46)
	banner_label.set_anchors_preset(Control.PRESET_CENTER)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.size = Vector2(1000, 80)
	banner_label.position = Vector2(-500, -200)
	banner_label.modulate.a = 0.0
	root.add_child(banner_label)

	_build_pause(root)


func _build_pause(root: Control) -> void:
	pause_panel = ColorRect.new()
	(pause_panel as ColorRect).color = Color(0, 0, 0, 0.65)
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(pause_panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(460, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	box.add_child(label("Pausado", 36))
	var hint := label("Mover: joystick ou WASD · Câmera: arraste à direita ou mouse\nAtacar: toque ou J (segure para carregar) · Esquiva: Espaço\nPoção: Q · Mira na fera: Tab ou botão MIRA", 16, Color(0.8, 0.78, 0.9))
	box.add_child(hint)
	info_label = label("", 14, Color(0.65, 0.62, 0.78))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info_label)
	var resume := Button.new()
	resume.text = "Continuar"
	resume.custom_minimum_size = Vector2(0, 64)
	resume.pressed.connect(func(): resume_requested.emit())
	box.add_child(resume)
	var quit := Button.new()
	quit.text = "Abandonar caçada"
	quit.custom_minimum_size = Vector2(0, 64)
	quit.pressed.connect(func(): quit_requested.emit())
	box.add_child(quit)


func show_pause(on: bool) -> void:
	pause_panel.visible = on
	if on:
		info_label.text = "Renderizador: %s  ·  GPU: %s  ·  %d FPS" % [RenderingServer.get_current_rendering_method(),
			RenderingServer.get_video_adapter_name(), Engine.get_frames_per_second()]


func banner(text: String, color := Color.WHITE) -> void:
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	if _banner_tween:
		_banner_tween.kill()
	banner_label.modulate.a = 1.0
	banner_label.scale = Vector2.ONE
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.4)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.3)


func refresh(dt: float, player: HunterPlayer, beast: Beast, faints: int, elapsed: float) -> void:
	var d := canvas.d
	d.hp = player.hp / player.max_hp
	_hp_ghost = maxf(d.hp, _hp_ghost - dt * 0.4)
	d.hp_ghost = _hp_ghost
	d.st = player.stamina / GameData.PLAYER.stamina
	d.focus = player.focus()
	d.charging = player.is_charging()
	d.sharp = player.sharp
	d.faints = faints
	d.beast_hp = beast.hp / beast.max_hp
	_beast_ghost = maxf(d.beast_hp, _beast_ghost - dt * 0.25)
	d.beast_ghost = _beast_ghost
	d.fury = beast.fury
	d.action = beast.busy()
	var parts := []
	for p in _beast_def.partes:
		var st: Dictionary = beast.parts[p.id]
		parts.append({"nome": p.nome, "ferida": st.ferida, "quebrada": st.quebrada})
	d.parts = parts
	var s := int(elapsed)
	d.time = "%d:%02d" % [s / 60, s % 60]
	if Engine.get_process_frames() % 30 == 0:
		d.fps = "%d fps · %d%%" % [Engine.get_frames_per_second(), roundi(render_scale * 100.0)]
	# Bússola: direção da fera em relação para onde a câmera olha.
	var cam := get_viewport().get_camera_3d()
	if cam:
		var to_b := (beast.global_position - cam.global_position) * Vector3(1, 0, 1)
		var fwd := -cam.global_basis.z * Vector3(1, 0, 1)
		d.compass = fwd.signed_angle_to(to_b, Vector3.UP) * -1.0
		d.compass_on = to_b.length() > 0.1
	canvas.queue_redraw()

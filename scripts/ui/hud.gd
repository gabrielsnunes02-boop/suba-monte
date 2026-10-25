class_name Hud
extends CanvasLayer
## HUD da caçada: vida/stamina, fera (vida, fúria, partes, ataque em preparo), tempo, avisos e pausa.

signal resume_requested
signal quit_requested
signal pause_requested

var hp_bar: ProgressBar
var hp_ghost: ProgressBar
var st_bar: ProgressBar
var beast_bar: ProgressBar
var beast_ghost: ProgressBar
var faints_label: Label
var fury_label: Label
var action_label: Label
var timer_label: Label
var fps_label: Label
var render_scale := 1.0
var info_label: Label
var banner_label: Label
var part_labels := {}
var pause_panel: Control
var _banner_tween: Tween


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
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Jogador (topo esquerdo)
	var pbox := VBoxContainer.new()
	pbox.position = Vector2(24, 18)
	pbox.custom_minimum_size = Vector2(340, 0)
	pbox.add_theme_constant_override("separation", 6)
	root.add_child(pbox)
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(340, 20)
	pbox.add_child(stack)
	hp_ghost = bar(Color(1, 1, 1, 0.6), Color(0, 0, 0, 0.55), 20)
	hp_bar = bar(Color("#3fbf6a"), Color(0, 0, 0, 0), 20)
	for b in [hp_ghost, hp_bar]:
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		stack.add_child(b)
	st_bar = bar(Color("#facc15"), Color(0, 0, 0, 0.55), 9)
	pbox.add_child(st_bar)
	faints_label = label("Desmaios 0/3", 18, Color("#ff8a8a"))
	pbox.add_child(faints_label)
	pbox.add_child(label("%s +%d" % [weapon.nome, weapon_level], 16, GameData.element_color(weapon.elemento)))

	# Fera (topo centro)
	var bbox := VBoxContainer.new()
	bbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bbox.custom_minimum_size = Vector2(460, 0)
	bbox.position = Vector2(-230, 14)
	bbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	bbox.add_theme_constant_override("separation", 5)
	root.add_child(bbox)
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 10)
	name_row.add_child(label(beast_def.nome, 24, GameData.element_color(beast_def.elemento).lightened(0.3)))
	fury_label = label("FÚRIA", 18, Color("#ff5a5a"))
	fury_label.visible = false
	name_row.add_child(fury_label)
	bbox.add_child(name_row)
	var bstack := Control.new()
	bstack.custom_minimum_size = Vector2(460, 14)
	bbox.add_child(bstack)
	beast_ghost = bar(Color(1, 1, 1, 0.55))
	beast_bar = bar(Color("#e8571a"), Color(0, 0, 0, 0))
	for b in [beast_ghost, beast_bar]:
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		bstack.add_child(b)
	var parts_row := HBoxContainer.new()
	parts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	parts_row.add_theme_constant_override("separation", 14)
	for p in beast_def.partes:
		var l := label(p.nome, 16, Color(1, 1, 1, 0.85))
		part_labels[p.id] = l
		parts_row.add_child(l)
	bbox.add_child(parts_row)
	action_label = label("", 20, Color("#fca5a5"))
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bbox.add_child(action_label)

	# Tempo e pausa (topo direito)
	var tbox := HBoxContainer.new()
	tbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tbox.position = Vector2(-190, 16)
	tbox.add_theme_constant_override("separation", 12)
	root.add_child(tbox)
	var tcol := VBoxContainer.new()
	timer_label = label("0:00", 24)
	tcol.add_child(timer_label)
	fps_label = label("", 14, Color(1, 1, 1, 0.7))
	tcol.add_child(fps_label)
	tbox.add_child(tcol)
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.custom_minimum_size = Vector2(64, 56)
	pause_btn.add_theme_font_size_override("font_size", 24)
	pause_btn.pressed.connect(func(): pause_requested.emit())
	tbox.add_child(pause_btn)

	# Aviso central
	banner_label = label("", 46)
	banner_label.set_anchors_preset(Control.PRESET_CENTER)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.size = Vector2(1000, 80)
	banner_label.position = Vector2(-500, -220)
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
	hp_bar.value = player.hp / player.max_hp
	hp_ghost.value = maxf(hp_bar.value, hp_ghost.value - dt * 0.4)
	st_bar.value = player.stamina / GameData.PLAYER.stamina
	beast_bar.value = beast.hp / beast.max_hp
	beast_ghost.value = maxf(beast_bar.value, beast_ghost.value - dt * 0.25)
	fury_label.visible = beast.fury
	var b := beast.busy()
	action_label.text = ("! " + b + " !") if b != "" else ""
	var s := int(elapsed)
	timer_label.text = "%d:%02d" % [s / 60, s % 60]
	if Engine.get_process_frames() % 30 == 0:
		fps_label.text = "%d fps · %d%%" % [Engine.get_frames_per_second(), roundi(render_scale * 100.0)]
	faints_label.text = "Desmaios %d/%d" % [faints, GameData.PLAYER.desmaios_maximos]
	for id in part_labels:
		var st: Dictionary = beast.parts[id]
		var l: Label = part_labels[id]
		if st.quebrada:
			l.add_theme_color_override("font_color", Color("#6ee7a0"))
			l.text = st.def.nome + " (quebrada)"
		elif st.ferida:
			l.add_theme_color_override("font_color", Color("#fdba74"))

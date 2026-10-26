extends Node
## Ponto de entrada: configura os controles, mostra o acampamento e troca para a caçada.
##
## Argumentos de teste (depois de `--`):
##   --bot=<fera_id>     inicia a caçada direto e joga sozinho (teste automatizado)
##   --seconds=<n>       tempo máximo do bot (padrão 90)
##   --shots=<pasta>     salva capturas de tela durante o teste (precisa de renderização)
##   --quality=<0|1|2>   qualidade gráfica (Baixo, Médio, Alto)
##   --hub-shot=<pasta>  salva capturas das telas do acampamento e sai

var profile: Dictionary
var hub: Hub
var hunt: Hunt
var _args := {}


func _ready() -> void:
	_setup_input()
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _args.has("outfit"):
		Settings.set_outfit(_args.outfit)
	if _args.has("quality"):
		Settings.set_quality(int(_args.quality))
	profile = ProfileLogic.load_profile()
	if _args.has("bot"):
		_start_bot()
	else:
		_show_hub()
		if _args.has("hub-shot"):
			_hub_shots.call_deferred()


func _hub_shots() -> void:
	for screen in ["home", "cacar", "forja", "opcoes"]:
		hub.go(screen)
		for i in 12:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/godot-hub-%s.png" % [_args["hub-shot"], screen])
	get_tree().quit()


func _show_hub() -> void:
	hub = Hub.new()
	hub.profile = profile
	hub.hunt_requested.connect(_start_hunt)
	hub.profile_changed.connect(func(p):
		profile = p
		ProfileLogic.save_profile(p))
	add_child(hub)


func _start_hunt(fera_id: String) -> void:
	if hub:
		hub.queue_free()
		hub = null
	# Mostra "Carregando" antes de montar a ilha (pode levar alguns segundos em celulares simples).
	var loading := _loading_screen(GameData.beast_by_id(fera_id).nome)
	add_child(loading)
	await get_tree().process_frame
	await get_tree().process_frame
	hunt = Hunt.new()
	hunt.setup(profile, fera_id)
	hunt.finished.connect(_on_hunt_finished)
	add_child(hunt)
	for i in 3:
		await get_tree().process_frame
	loading.queue_free()


func _loading_screen(beast_name: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var bg := ColorRect.new()
	bg.color = Hub.C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var l := Hud.label("Carregando caçada: %s..." % beast_name, 30, Hub.C_TEXT)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bg.add_child(l)
	return layer


func _on_hunt_finished(result: Dictionary) -> void:
	var applied := ProfileLogic.apply_hunt_result(profile, result)
	profile = applied.profile
	if not _args.has("bot"):
		ProfileLogic.save_profile(profile)
	hunt.queue_free()
	hunt = null
	if _args.has("bot"):
		print("RESULTADO ", JSON.stringify(result))
		_bot_done(0)
		return
	_show_hub()
	hub.show_result(result, applied.subiu_rank)


# ------------------------------------------------------------ controles

func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"attack": [KEY_J, KEY_ENTER], "dodge": [KEY_SPACE, KEY_K, KEY_SHIFT],
		"potion": [KEY_Q, KEY_E], "lock_on": [KEY_TAB, KEY_L], "pause": [KEY_ESCAPE, KEY_P],
		"cam_left": [], "cam_right": [], "cam_up": [], "cam_down": [],
	}
	var pad_buttons := {"attack": JOY_BUTTON_X, "dodge": JOY_BUTTON_A, "potion": JOY_BUTTON_Y,
		"lock_on": JOY_BUTTON_RIGHT_STICK, "pause": JOY_BUTTON_START}
	var pad_axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_forward": [JOY_AXIS_LEFT_Y, -1.0], "move_back": [JOY_AXIS_LEFT_Y, 1.0],
		"cam_left": [JOY_AXIS_RIGHT_X, -1.0], "cam_right": [JOY_AXIS_RIGHT_X, 1.0],
		"cam_up": [JOY_AXIS_RIGHT_Y, -1.0], "cam_down": [JOY_AXIS_RIGHT_Y, 1.0],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		if pad_buttons.has(action):
			var jb := InputEventJoypadButton.new()
			jb.button_index = pad_buttons[action]
			InputMap.action_add_event(action, jb)
		if pad_axes.has(action):
			var ja := InputEventJoypadMotion.new()
			ja.axis = pad_axes[action][0]
			ja.axis_value = pad_axes[action][1]
			InputMap.action_add_event(action, ja)
	# O clique esquerdo vira toque (emulação), então o ataque pelo mouse fica no botão do meio.
	var mouse_attack := InputEventMouseButton.new()
	mouse_attack.button_index = MOUSE_BUTTON_MIDDLE
	InputMap.action_add_event("attack", mouse_attack)


# ------------------------------------------------------------ modo de teste (bot)

var _bot_t := 0.0
var _bot_log := 0.0
var _bot_shot := 0
var _bot_attack_down := false


func _start_bot() -> void:
	profile = ProfileLogic.new_profile()
	profile.rank = 3
	profile.equipamentos = {"espada_ferro": 6, "roupa_couro": 6}
	_start_hunt(_args.bot)


func _process(dt: float) -> void:
	if not _args.has("bot") or hunt == null or not hunt.is_inside_tree():
		return
	_bot_t += dt / maxf(Engine.time_scale, 0.05)
	var p := hunt.player
	var b := hunt.beast
	if _args.has("shots") and _bot_t > 1.0 + _bot_shot * 4.0 and _bot_shot < 8:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/godot-%s-%d.png" % [_args.shots, _args.bot, _bot_shot])
		_bot_shot += 1
	if _bot_t - _bot_log > 4.0:
		_bot_log = _bot_t
		print("t=%.0f fera=%s hp=%d/%d jogador=%s hp=%d partes=%s furia=%s" % [_bot_t, Beast.State.keys()[b.state],
			b.hp, b.max_hp, HunterPlayer.State.keys()[p.state], p.hp,
			",".join(b.parts.keys().map(func(k): return k + ("Q" if b.parts[k].quebrada else ("F" if b.parts[k].ferida else "-")))),
			b.fury])
	if _bot_t > float(_args.get("seconds", "90")):
		print("TEMPO ESGOTADO")
		_bot_done(0)
		return

	# Decide: esquivar do aviso, aproximar ou atacar.
	for a in ["move_left", "move_right", "move_forward", "move_back", "dodge"]:
		Input.action_release(a)
	var to_b := (b.position - p.position) * Vector3(1, 0, 1)
	var surf := b.distance_to_point(p.position)
	var dir := Vector3.ZERO
	if b.state == Beast.State.PREPARAR and surf < 7.0:
		dir = Vector3(-to_b.z, 0, to_b.x).normalized()
		Input.action_press("dodge")
	elif surf > 1.2:
		dir = to_b.normalized()
	else:
		_bot_attack_down = not _bot_attack_down
		if _bot_attack_down:
			Input.action_press("attack")
		else:
			Input.action_release("attack")
	if dir != Vector3.ZERO:
		var local := dir.rotated(Vector3.UP, -hunt.camera_rig.yaw)
		if local.x < -0.2: Input.action_press("move_left", -local.x)
		if local.x > 0.2: Input.action_press("move_right", local.x)
		if local.z < -0.2: Input.action_press("move_forward", -local.z)
		if local.z > 0.2: Input.action_press("move_back", local.z)


func _bot_done(code: int) -> void:
	set_process(false)
	get_tree().quit(code)

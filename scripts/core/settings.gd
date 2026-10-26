class_name Settings
extends RefCounted
## Configurações do aparelho (separadas do progresso). Hoje: qualidade gráfica.

const PATH := "user://config.cfg"
const NOMES := ["Baixo", "Médio", "Alto"]

## Por nível: resolução 3D, sombras em tempo real, grama, MSAA, árvores (e quanto dos galhos
## fica na versão simplificada) e plantas do kit,
## materiais simples (sem mapas de relevo/rugosidade), luz por vértice (bem mais barata) e
## limite de FPS (30 estável é melhor que 40 oscilando; 0 = sem limite).
const PRESETS := [
	{"escala_3d": 0.55, "sombras": false, "grama": 500, "msaa": false, "arvores": 14, "galhos": 0.12, "detalhes": 36,
		"simples": true, "vertice": true, "fps": 30},
	{"escala_3d": 0.75, "sombras": false, "grama": 1400, "msaa": false, "arvores": 20, "galhos": 0.25, "detalhes": 90,
		"simples": true, "vertice": false, "fps": 30},
	{"escala_3d": 1.0, "sombras": true, "grama": 3200, "msaa": true, "arvores": 30, "galhos": 0.5, "detalhes": 240,
		"simples": false, "vertice": false, "fps": 0},
]
## GPUs de entrada: o jogo já começa em Baixo nelas.
const GPUS_FRACAS := ["PowerVR Rogue GE", "PowerVR Rogue GX", "PowerVR Rogue G6", "Mali-4", "Mali-T",
	"Mali-G31", "Mali-G51", "Mali-G52", "Mali-G57", "Adreno (TM) 3", "Adreno (TM) 4", "Adreno (TM) 50",
	"Adreno (TM) 51", "Adreno (TM) 52", "Adreno (TM) 60"]

static var _cache := -1


static func quality() -> int:
	if _cache < 0:
		var cfg := ConfigFile.new()
		_cache = 0 if is_weak_gpu() else 1
		if cfg.load(PATH) == OK and cfg.has_section_key("graficos", "qualidade"):
			_cache = clampi(int(cfg.get_value("graficos", "qualidade", _cache)), 0, PRESETS.size() - 1)
	return _cache


static func set_quality(q: int) -> void:
	_cache = clampi(q, 0, PRESETS.size() - 1)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("graficos", "qualidade", _cache)
	cfg.save(PATH)


static func is_weak_gpu() -> bool:
	var gpu := RenderingServer.get_video_adapter_name()
	for g in GPUS_FRACAS:
		if gpu.contains(g):
			return true
	return false


static func preset() -> Dictionary:
	return PRESETS[quality()]


## Visuais do caçador: id → nome na tela.
const VISUAIS := {"ranger": "Ranger", "campones": "Camponês"}


static func outfit() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		var v: String = cfg.get_value("visual", "caçador", "ranger")
		if VISUAIS.has(v):
			return v
	return "ranger"


static func set_outfit(v: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("visual", "caçador", v)
	cfg.save(PATH)

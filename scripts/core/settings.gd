class_name Settings
extends RefCounted
## Configurações do aparelho (separadas do progresso). Hoje: qualidade gráfica.

const PATH := "user://config.cfg"
const NOMES := ["Baixo", "Médio", "Alto"]

## Por nível: resolução 3D, sombras em tempo real, grama, MSAA, árvores e plantas do kit.
const PRESETS := [
	{"escala_3d": 0.6, "sombras": false, "grama": 1200, "msaa": false, "arvores": 14, "detalhes": 70},
	{"escala_3d": 0.8, "sombras": false, "grama": 2200, "msaa": false, "arvores": 22, "detalhes": 140},
	{"escala_3d": 1.0, "sombras": true, "grama": 3200, "msaa": true, "arvores": 30, "detalhes": 240},
]

static var _cache := -1


static func quality() -> int:
	if _cache < 0:
		var cfg := ConfigFile.new()
		_cache = 1
		if cfg.load(PATH) == OK:
			_cache = clampi(int(cfg.get_value("graficos", "qualidade", 1)), 0, PRESETS.size() - 1)
	return _cache


static func set_quality(q: int) -> void:
	_cache = clampi(q, 0, PRESETS.size() - 1)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("graficos", "qualidade", _cache)
	cfg.save(PATH)


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

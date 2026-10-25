class_name Settings
extends RefCounted
## Configurações do aparelho (separadas do progresso). Hoje: qualidade gráfica.

const PATH := "user://config.cfg"
const NOMES := ["Baixo", "Médio", "Alto"]

## Por nível: resolução 3D, sombras em tempo real, quantidade de grama, MSAA.
const PRESETS := [
	{"escala_3d": 0.6, "sombras": false, "grama": 1200, "msaa": false},
	{"escala_3d": 0.8, "sombras": false, "grama": 2200, "msaa": false},
	{"escala_3d": 1.0, "sombras": true, "grama": 3200, "msaa": true},
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


## Personagens disponíveis: id → nome na tela.
const PERSONAGENS := {"campones": "Camponês", "cavaleiro": "Cavaleiro"}


static func character() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		var c: String = cfg.get_value("visual", "personagem", "campones")
		if PERSONAGENS.has(c):
			return c
	return "campones"


static func set_character(c: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("visual", "personagem", c)
	cfg.save(PATH)

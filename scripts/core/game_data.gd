class_name GameData
extends RefCounted
## Dados de design do jogo. Todo o balanceamento mora aqui.

const ELEMENTS := {
	"neutro": {"nome": "Neutro", "cor": "#b8b8b8"},
	"fogo": {"nome": "Fogo", "cor": "#ff6a2b"},
	"natureza": {"nome": "Natureza", "cor": "#5fc44a"},
	"agua": {"nome": "Água", "cor": "#3aa8ff"},
}

## Fogo ► Natureza ► Água ► Fogo. A chave vence o valor.
const BEATS := {"fogo": "natureza", "natureza": "agua", "agua": "fogo"}

const MATERIALS := {
	"minerio": {"nome": "Minério de Ferro", "raridade": "comum", "descricao": "Veios azulados nas pedras da ilha."},
	"fibra": {"nome": "Fibra de Capim", "raridade": "comum", "descricao": "Arbustos verdes espalhados pelo mapa."},

	"couro_brasa": {"nome": "Couro de Brasa", "raridade": "comum", "descricao": "Ainda quente ao toque."},
	"garra_brasa": {"nome": "Garra de Brasa", "raridade": "incomum", "descricao": "Curva e afiada."},
	"presa_brasa": {"nome": "Presa de Brasa", "raridade": "incomum", "descricao": "Quebre a cabeça da Onça-Brasa."},
	"cauda_brasa": {"nome": "Cauda de Brasa", "raridade": "incomum", "descricao": "Corte a cauda da Onça-Brasa."},
	"coracao_brasa": {"nome": "Coração de Brasa", "raridade": "raro", "descricao": "Pulsa como carvão vivo."},

	"placa_musgo": {"nome": "Placa Musgosa", "raridade": "comum", "descricao": "Casco coberto de musgo."},
	"garra_musgo": {"nome": "Garra Escavadora", "raridade": "incomum", "descricao": "Feita para cavar rocha."},
	"focinho_musgo": {"nome": "Focinho Blindado", "raridade": "incomum", "descricao": "Quebre a cabeça do Tatu-Musgo."},
	"cauda_musgo": {"nome": "Cauda de Clava", "raridade": "incomum", "descricao": "Corte a cauda do Tatu-Musgo."},
	"coracao_musgo": {"nome": "Coração Verdejante", "raridade": "raro", "descricao": "Brotos nascem ao redor dele."},

	"escama_mare": {"nome": "Escama de Maré", "raridade": "comum", "descricao": "Úmida, nunca seca."},
	"dente_mare": {"nome": "Dente de Maré", "raridade": "incomum", "descricao": "Serrilhado como coral."},
	"mandibula_mare": {"nome": "Mandíbula Abissal", "raridade": "incomum", "descricao": "Quebre a cabeça do Jacaré-Maré."},
	"cauda_mare": {"nome": "Cauda de Correnteza", "raridade": "incomum", "descricao": "Corte a cauda do Jacaré-Maré."},
	"coracao_mare": {"nome": "Coração de Maré", "raridade": "raro", "descricao": "Ouve-se o mar dentro dele."},
}

const PERKS := {
	"quebra_ossos": {"nome": "Quebra-Ossos", "descricao": "+30% de dano em partes feridas."},
	"cacador_paciente": {"nome": "Caçador Paciente", "descricao": "+20% de dano após 3 s sem sofrer dano."},
	"esquiva_afiada": {"nome": "Esquiva Afiada", "descricao": "Após uma esquiva perfeita, o próximo golpe é crítico."},
	"ultimo_folego": {"nome": "Último Fôlego", "descricao": "+25% de dano com vida abaixo de 30%."},
	"pele_grossa": {"nome": "Pele Grossa", "descricao": "+20% de vida máxima."},
	"folego_longo": {"nome": "Fôlego Longo", "descricao": "Esquivas gastam 25% menos stamina."},
}

## base = poder (arma) ou defesa 0–1 (armadura).
const GEAR := {
	"espada_ferro": {"nome": "Espada de Ferro", "slot": "arma", "elemento": "neutro", "base": 40.0, "perk": "",
		"fera": "", "receita": {}, "custo": 0, "material_upgrade": "minerio", "material_raro": "fibra"},
	"roupa_couro": {"nome": "Roupa de Couro", "slot": "armadura", "elemento": "neutro", "base": 0.05, "perk": "",
		"fera": "", "receita": {}, "custo": 0, "material_upgrade": "fibra", "material_raro": "minerio"},

	"lamina_brasa": {"nome": "Lâmina de Brasa", "slot": "arma", "elemento": "fogo", "base": 52.0, "perk": "quebra_ossos",
		"fera": "onca_brasa", "receita": {"couro_brasa": 3, "garra_brasa": 2, "minerio": 4}, "custo": 300,
		"material_upgrade": "couro_brasa", "material_raro": "coracao_brasa"},
	"couraca_brasa": {"nome": "Couraça de Brasa", "slot": "armadura", "elemento": "fogo", "base": 0.15, "perk": "ultimo_folego",
		"fera": "onca_brasa", "receita": {"couro_brasa": 4, "presa_brasa": 1, "fibra": 3}, "custo": 300,
		"material_upgrade": "couro_brasa", "material_raro": "coracao_brasa"},

	"lamina_musgo": {"nome": "Lâmina Musgosa", "slot": "arma", "elemento": "natureza", "base": 52.0, "perk": "cacador_paciente",
		"fera": "tatu_musgo", "receita": {"placa_musgo": 3, "garra_musgo": 2, "minerio": 4}, "custo": 300,
		"material_upgrade": "placa_musgo", "material_raro": "coracao_musgo"},
	"couraca_musgo": {"nome": "Couraça Musgosa", "slot": "armadura", "elemento": "natureza", "base": 0.18, "perk": "pele_grossa",
		"fera": "tatu_musgo", "receita": {"placa_musgo": 4, "cauda_musgo": 1, "fibra": 3}, "custo": 300,
		"material_upgrade": "placa_musgo", "material_raro": "coracao_musgo"},

	"lamina_mare": {"nome": "Lâmina de Maré", "slot": "arma", "elemento": "agua", "base": 68.0, "perk": "esquiva_afiada",
		"fera": "jacare_mare", "receita": {"escama_mare": 4, "dente_mare": 2, "mandibula_mare": 1, "minerio": 6}, "custo": 700,
		"material_upgrade": "escama_mare", "material_raro": "coracao_mare"},
	"couraca_mare": {"nome": "Couraça de Maré", "slot": "armadura", "elemento": "agua", "base": 0.24, "perk": "folego_longo",
		"fera": "jacare_mare", "receita": {"escama_mare": 5, "cauda_mare": 1, "fibra": 5}, "custo": 700,
		"material_upgrade": "escama_mare", "material_raro": "coracao_mare"},
}

const GEAR_ORDER := ["espada_ferro", "roupa_couro", "lamina_brasa", "couraca_brasa", "lamina_musgo",
	"couraca_musgo", "lamina_mare", "couraca_mare"]

const MAX_UPGRADE := 10

## tipo: "setor" (ângulo 360 = giro), "investida" ou "circulo".
const BEASTS := [
	{
		"id": "onca_brasa", "nome": "Onça-Brasa", "apelido": "A Fera das Cinzas", "tier": 1, "rank_minimo": 1,
		"elemento": "fogo", "vida": 2600.0, "velocidade": 5.2, "defesa": 0.05, "limite_atordoamento": 260.0,
		"descricao": "Rápida e agressiva. Avança em linha reta: esquive para o lado e puna a recuperação.",
		"partes": [
			{"id": "cabeca", "nome": "Cabeça", "vida": 520.0, "drop": "presa_brasa"},
			{"id": "costas", "nome": "Costas", "vida": 620.0, "drop": "garra_brasa"},
			{"id": "cauda", "nome": "Cauda", "vida": 420.0, "drop": "cauda_brasa"},
		],
		"ataques": [
			{"id": "patada", "nome": "Patada", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 4.2, "raio": 4.6, "angulo": 110.0, "preparo": 0.65, "dano": 16.0, "recuperacao": 0.8, "so_furia": false},
			{"id": "investida", "nome": "Investida", "tipo": "investida", "alcance_min": 5.0, "alcance_max": 18.0, "raio": 2.0, "angulo": 0.0, "preparo": 0.85, "dano": 22.0, "recuperacao": 1.1, "so_furia": false},
			{"id": "explosao", "nome": "Explosão de Brasas", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 7.0, "raio": 6.5, "angulo": 360.0, "preparo": 1.25, "dano": 28.0, "recuperacao": 1.3, "so_furia": true},
		],
		"loot": [
			{"item": "couro_brasa", "chance": 1.0, "qtd": [2, 3]},
			{"item": "garra_brasa", "chance": 0.6, "qtd": [1, 2]},
			{"item": "coracao_brasa", "chance": 0.12, "qtd": [1, 1]},
		],
		"moedas": [180, 260], "xp": 80,
		"visual": {"cor_corpo": "#d9712c", "cor_detalhe": "#3a1d10", "cor_olhos": "#ffe066", "comprimento": 3.6,
			"altura": 1.5, "largura": 1.4, "pernas": 1.3, "cauda_segmentos": 5, "espinhos": "chamas"},
		"bioma": {"chao": "#a8843c", "grama": "#b39a45", "ceu_topo": "#5f8fd0", "ceu_horizonte": "#f4c48a", "arvore": "#9a7b2a", "pedra": "#8b6a4f"},
	},
	{
		"id": "tatu_musgo", "nome": "Tatu-Musgo", "apelido": "O Muro Vivo", "tier": 1, "rank_minimo": 1,
		"elemento": "natureza", "vida": 3400.0, "velocidade": 3.6, "defesa": 0.15, "limite_atordoamento": 320.0,
		"descricao": "Lento e blindado. Rola sobre você e gira a cauda em clava. Fique atrás dele.",
		"partes": [
			{"id": "cabeca", "nome": "Cabeça", "vida": 600.0, "drop": "focinho_musgo"},
			{"id": "costas", "nome": "Casco", "vida": 900.0, "drop": "garra_musgo"},
			{"id": "cauda", "nome": "Cauda", "vida": 500.0, "drop": "cauda_musgo"},
		],
		"ataques": [
			{"id": "focinhada", "nome": "Focinhada", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 4.0, "raio": 4.2, "angulo": 80.0, "preparo": 0.75, "dano": 18.0, "recuperacao": 0.9, "so_furia": false},
			{"id": "rolamento", "nome": "Rolamento", "tipo": "investida", "alcance_min": 4.0, "alcance_max": 16.0, "raio": 2.4, "angulo": 0.0, "preparo": 1.0, "dano": 24.0, "recuperacao": 1.4, "so_furia": false},
			{"id": "giro_cauda", "nome": "Giro da Clava", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 5.0, "raio": 5.4, "angulo": 360.0, "preparo": 0.95, "dano": 20.0, "recuperacao": 1.0, "so_furia": false},
			{"id": "terremoto", "nome": "Terremoto", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 8.0, "raio": 7.5, "angulo": 360.0, "preparo": 1.4, "dano": 30.0, "recuperacao": 1.5, "so_furia": true},
		],
		"loot": [
			{"item": "placa_musgo", "chance": 1.0, "qtd": [2, 3]},
			{"item": "garra_musgo", "chance": 0.6, "qtd": [1, 2]},
			{"item": "coracao_musgo", "chance": 0.12, "qtd": [1, 1]},
		],
		"moedas": [200, 280], "xp": 90,
		"visual": {"cor_corpo": "#6f8f3a", "cor_detalhe": "#3d4a22", "cor_olhos": "#c8ff6a", "comprimento": 3.4,
			"altura": 1.8, "largura": 2.0, "pernas": 0.9, "cauda_segmentos": 4, "espinhos": "placas"},
		"bioma": {"chao": "#4f8a3a", "grama": "#5fa845", "ceu_topo": "#4f86c6", "ceu_horizonte": "#bfe3ef", "arvore": "#2f7a3a", "pedra": "#7c8a7a"},
	},
	{
		"id": "jacare_mare", "nome": "Jacaré-Maré", "apelido": "O Senhor da Correnteza", "tier": 2, "rank_minimo": 3,
		"elemento": "agua", "vida": 5200.0, "velocidade": 4.6, "defesa": 0.12, "limite_atordoamento": 420.0,
		"descricao": "Mordidas rápidas e uma cauda que varre tudo. Na fúria, explode em ondas.",
		"partes": [
			{"id": "cabeca", "nome": "Mandíbula", "vida": 900.0, "drop": "mandibula_mare"},
			{"id": "costas", "nome": "Dorso", "vida": 1100.0, "drop": "dente_mare"},
			{"id": "cauda", "nome": "Cauda", "vida": 800.0, "drop": "cauda_mare"},
		],
		"ataques": [
			{"id": "mordida", "nome": "Mordida", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 4.8, "raio": 5.2, "angulo": 60.0, "preparo": 0.5, "dano": 22.0, "recuperacao": 0.7, "so_furia": false},
			{"id": "bote", "nome": "Bote", "tipo": "investida", "alcance_min": 5.0, "alcance_max": 17.0, "raio": 2.2, "angulo": 0.0, "preparo": 0.7, "dano": 26.0, "recuperacao": 1.0, "so_furia": false},
			{"id": "varredura", "nome": "Varredura de Cauda", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 5.5, "raio": 6.0, "angulo": 360.0, "preparo": 0.85, "dano": 24.0, "recuperacao": 0.9, "so_furia": false},
			{"id": "onda", "nome": "Onda Abissal", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 9.0, "raio": 8.5, "angulo": 360.0, "preparo": 1.2, "dano": 34.0, "recuperacao": 1.3, "so_furia": true},
		],
		"loot": [
			{"item": "escama_mare", "chance": 1.0, "qtd": [3, 4]},
			{"item": "dente_mare", "chance": 0.6, "qtd": [1, 2]},
			{"item": "coracao_mare", "chance": 0.12, "qtd": [1, 1]},
		],
		"moedas": [380, 500], "xp": 160,
		"visual": {"cor_corpo": "#2f7f8f", "cor_detalhe": "#163f4a", "cor_olhos": "#9ff3ff", "comprimento": 5.2,
			"altura": 1.1, "largura": 1.6, "pernas": 0.7, "cauda_segmentos": 7, "espinhos": "cristas"},
		"bioma": {"chao": "#3f7a5e", "grama": "#4f9a6e", "ceu_topo": "#3d6f93", "ceu_horizonte": "#a9d2dc", "arvore": "#2c6650", "pedra": "#56706e"},
	},
]

const PLAYER := {
	"vida": 100.0,
	"stamina": 100.0,
	"regen_stamina": 30.0,
	"atraso_regen": 0.5,
	"custo_esquiva": 25.0,
	"velocidade": 6.2,
	"pocoes": 3,
	"cura_pocao": 40.0,
	"desmaios_maximos": 3,
}

## Multiplicadores dos golpes da espada.
const MOTION_LEVE := [1.0, 1.1, 1.45]
const MOTION_PESADO_MIN := 1.8
const MOTION_PESADO_MAX := 2.7


static func weakness_of(el: String) -> String:
	for k in BEATS:
		if BEATS[k] == el:
			return k
	return ""


static func beast_by_id(id: String) -> Dictionary:
	for b in BEASTS:
		if b.id == id:
			return b
	push_error("Fera desconhecida: %s" % id)
	return {}


static func element_color(el: String) -> Color:
	return Color(ELEMENTS[el].cor)


static func material_name(id: String) -> String:
	return MATERIALS[id].nome if MATERIALS.has(id) else id

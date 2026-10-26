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
	"presa_brasa": {"nome": "Presa de Brasa", "raridade": "incomum", "descricao": "Quebre a cabeça do Raptor-Brasa."},
	"cauda_brasa": {"nome": "Cauda de Brasa", "raridade": "incomum", "descricao": "Corte a cauda do Raptor-Brasa."},
	"coracao_brasa": {"nome": "Coração de Brasa", "raridade": "raro", "descricao": "Pulsa como carvão vivo."},

	"placa_musgo": {"nome": "Placa Musgosa", "raridade": "comum", "descricao": "Casco coberto de musgo."},
	"garra_musgo": {"nome": "Garra Escavadora", "raridade": "incomum", "descricao": "Feita para cavar rocha."},
	"focinho_musgo": {"nome": "Focinho Blindado", "raridade": "incomum", "descricao": "Quebre a cabeça do Estego-Musgo."},
	"cauda_musgo": {"nome": "Cauda de Clava", "raridade": "incomum", "descricao": "Corte a cauda do Estego-Musgo."},
	"coracao_musgo": {"nome": "Coração Verdejante", "raridade": "raro", "descricao": "Brotos nascem ao redor dele."},

	"escama_mare": {"nome": "Escama de Maré", "raridade": "comum", "descricao": "Úmida, nunca seca."},
	"dente_mare": {"nome": "Dente de Maré", "raridade": "incomum", "descricao": "Serrilhado como coral."},
	"mandibula_mare": {"nome": "Mandíbula Abissal", "raridade": "incomum", "descricao": "Quebre a cabeça do Rex-Maré."},
	"cauda_mare": {"nome": "Cauda de Correnteza", "raridade": "incomum", "descricao": "Corte a cauda do Rex-Maré."},
	"coracao_mare": {"nome": "Coração de Maré", "raridade": "raro", "descricao": "Ouve-se o mar dentro dele."},

	"pele_nevoa": {"nome": "Pele de Névoa", "raridade": "comum", "descricao": "Lisa e sempre fria."},
	"crista_nevoa": {"nome": "Crista Sonora", "raridade": "incomum", "descricao": "Assobia com o vento."},
	"cranio_nevoa": {"nome": "Crânio de Névoa", "raridade": "incomum", "descricao": "Quebre a cabeça da Crista-Névoa."},
	"cauda_nevoa": {"nome": "Cauda de Névoa", "raridade": "incomum", "descricao": "Corte a cauda da Crista-Névoa."},
	"coracao_nevoa": {"nome": "Coração de Névoa", "raridade": "raro", "descricao": "Solta vapor em silêncio."},

	"placa_espinho": {"nome": "Placa Espinhosa", "raridade": "comum", "descricao": "Dura como casca de árvore velha."},
	"chifre_espinho": {"nome": "Chifre Verde", "raridade": "incomum", "descricao": "Cresce de novo a cada estação."},
	"escudo_espinho": {"nome": "Escudo do Tri-Espinho", "raridade": "incomum", "descricao": "Quebre a cabeça do Tri-Espinho."},
	"cauda_espinho": {"nome": "Cauda Espinhosa", "raridade": "incomum", "descricao": "Corte a cauda do Tri-Espinho."},
	"coracao_espinho": {"nome": "Coração de Cerne", "raridade": "raro", "descricao": "Tem anéis como um tronco."},

	"escama_tita": {"nome": "Escama de Cinza", "raridade": "comum", "descricao": "Cheira a vulcão."},
	"osso_tita": {"nome": "Osso Colossal", "raridade": "incomum", "descricao": "Pesado demais para um só caçador."},
	"cranio_tita": {"nome": "Crânio do Titã", "raridade": "incomum", "descricao": "Quebre a cabeça do Titã-Cinza."},
	"cauda_tita": {"nome": "Cauda do Titã", "raridade": "incomum", "descricao": "Corte a cauda do Titã-Cinza."},
	"coracao_tita": {"nome": "Coração de Magma", "raridade": "raro", "descricao": "Brilha no escuro como lava."},
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

	"lamina_nevoa": {"nome": "Lâmina de Névoa", "slot": "arma", "elemento": "agua", "base": 52.0, "perk": "esquiva_afiada",
		"fera": "crista_nevoa", "receita": {"pele_nevoa": 3, "crista_nevoa": 2, "minerio": 4}, "custo": 300,
		"material_upgrade": "pele_nevoa", "material_raro": "coracao_nevoa"},
	"couraca_nevoa": {"nome": "Couraça de Névoa", "slot": "armadura", "elemento": "agua", "base": 0.15, "perk": "folego_longo",
		"fera": "crista_nevoa", "receita": {"pele_nevoa": 4, "cranio_nevoa": 1, "fibra": 3}, "custo": 300,
		"material_upgrade": "pele_nevoa", "material_raro": "coracao_nevoa"},

	"lamina_espinho": {"nome": "Lâmina Espinhosa", "slot": "arma", "elemento": "natureza", "base": 68.0, "perk": "quebra_ossos",
		"fera": "tri_espinho", "receita": {"placa_espinho": 4, "chifre_espinho": 2, "escudo_espinho": 1, "minerio": 6}, "custo": 700,
		"material_upgrade": "placa_espinho", "material_raro": "coracao_espinho"},
	"couraca_espinho": {"nome": "Couraça Espinhosa", "slot": "armadura", "elemento": "natureza", "base": 0.26, "perk": "pele_grossa",
		"fera": "tri_espinho", "receita": {"placa_espinho": 5, "cauda_espinho": 1, "fibra": 5}, "custo": 700,
		"material_upgrade": "placa_espinho", "material_raro": "coracao_espinho"},

	"lamina_tita": {"nome": "Lâmina do Titã", "slot": "arma", "elemento": "fogo", "base": 86.0, "perk": "ultimo_folego",
		"fera": "tita_cinza", "receita": {"escama_tita": 5, "osso_tita": 3, "cranio_tita": 1, "minerio": 8}, "custo": 1400,
		"material_upgrade": "escama_tita", "material_raro": "coracao_tita"},
	"couraca_tita": {"nome": "Couraça do Titã", "slot": "armadura", "elemento": "fogo", "base": 0.32, "perk": "cacador_paciente",
		"fera": "tita_cinza", "receita": {"escama_tita": 6, "cauda_tita": 1, "osso_tita": 2, "fibra": 6}, "custo": 1400,
		"material_upgrade": "escama_tita", "material_raro": "coracao_tita"},
}

const GEAR_ORDER := ["espada_ferro", "roupa_couro", "lamina_brasa", "couraca_brasa", "lamina_musgo",
	"couraca_musgo", "lamina_nevoa", "couraca_nevoa", "lamina_mare", "couraca_mare", "lamina_espinho",
	"couraca_espinho", "lamina_tita", "couraca_tita"]

const MAX_UPGRADE := 10

## tipo: "setor" (ângulo 360 = giro), "investida" ou "circulo".
const BEASTS := [
	{
		"id": "onca_brasa", "nome": "Raptor-Brasa", "apelido": "A Fera das Cinzas", "tier": 1, "rank_minimo": 1,
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
		"modelo": "Velociraptor",
		"visual": {"cor_corpo": "#9a3a14", "cor_detalhe": "#f0b048", "cor_olhos": "#ffe066", "comprimento": 5.0,
			"altura": 2.4, "largura": 1.2, "pernas": 1.1, "cauda_segmentos": 5, "espinhos": "chamas"},
		"bioma": {"chao": "#a8843c", "grama": "#8f7f3c", "ceu_topo": "#9fb6c8", "ceu_horizonte": "#f4c48a",
			"neblina": "#e3cf9e", "luz": "#fff0cf", "sombra": "#4a3f2e", "raio": "#ffe2a01c",
			"tint_grama": "#ffd98f", "tint_terra": "#ffeedd", "tint_rocha": "#ffe6c8", "arvore": "#9a7b2a", "pedra": "#8b6a4f",
			"arvores": ["DeadTree_1", "DeadTree_3", "TwistedTree_1", "CommonTree_5"],
			"plantas": ["Bush_Common", "Grass_Wispy_Tall", "Plant_7_Big", "Grass_Common_Tall"]},
	},
	{
		"id": "tatu_musgo", "nome": "Estego-Musgo", "apelido": "O Muro Vivo", "tier": 1, "rank_minimo": 1,
		"elemento": "natureza", "vida": 3400.0, "velocidade": 3.6, "defesa": 0.15, "limite_atordoamento": 320.0,
		"descricao": "Lento e blindado. Avança com as placas e gira a cauda de espinhos. Fique atrás dele.",
		"partes": [
			{"id": "cabeca", "nome": "Cabeça", "vida": 600.0, "drop": "focinho_musgo"},
			{"id": "costas", "nome": "Casco", "vida": 900.0, "drop": "garra_musgo"},
			{"id": "cauda", "nome": "Cauda", "vida": 500.0, "drop": "cauda_musgo"},
		],
		"ataques": [
			{"id": "focinhada", "nome": "Focinhada", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 4.0, "raio": 4.2, "angulo": 80.0, "preparo": 0.75, "dano": 18.0, "recuperacao": 0.9, "so_furia": false},
			{"id": "rolamento", "nome": "Avanço de Placas", "tipo": "investida", "alcance_min": 4.0, "alcance_max": 16.0, "raio": 2.4, "angulo": 0.0, "preparo": 1.0, "dano": 24.0, "recuperacao": 1.4, "so_furia": false},
			{"id": "giro_cauda", "nome": "Giro da Clava", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 5.0, "raio": 5.4, "angulo": 360.0, "preparo": 0.95, "dano": 20.0, "recuperacao": 1.0, "so_furia": false},
			{"id": "terremoto", "nome": "Terremoto", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 8.0, "raio": 7.5, "angulo": 360.0, "preparo": 1.4, "dano": 30.0, "recuperacao": 1.5, "so_furia": true},
		],
		"loot": [
			{"item": "placa_musgo", "chance": 1.0, "qtd": [2, 3]},
			{"item": "garra_musgo", "chance": 0.6, "qtd": [1, 2]},
			{"item": "coracao_musgo", "chance": 0.12, "qtd": [1, 1]},
		],
		"moedas": [200, 280], "xp": 90,
		"modelo": "Stegosaurus",
		"visual": {"cor_corpo": "#4c5f2c", "cor_detalhe": "#b7c45a", "cor_olhos": "#c8ff6a", "comprimento": 6.5,
			"altura": 3.0, "largura": 1.8, "pernas": 1.0, "cauda_segmentos": 4, "espinhos": "placas"},
		"bioma": {"chao": "#4f8a3a", "grama": "#5f8a35", "ceu_topo": "#c8dcc0", "ceu_horizonte": "#bfe3ef",
			"neblina": "#c3d3a0", "luz": "#fff6d8", "sombra": "#28331f", "raio": "#f0ffc01a",
			"tint_grama": "#ffffff", "tint_terra": "#ffffff", "tint_rocha": "#ffffff", "arvore": "#2f7a3a", "pedra": "#7c8a7a",
			"arvores": ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "Pine_1", "Pine_3"],
			"plantas": ["Bush_Common_Flowers", "Fern_1", "Flower_3_Group", "Flower_4_Group", "Mushroom_Common", "Clover_1"]},
	},
	{
		"id": "crista_nevoa", "nome": "Crista-Névoa", "apelido": "A Voz do Lago", "tier": 1, "rank_minimo": 1,
		"elemento": "agua", "vida": 2400.0, "velocidade": 5.0, "defesa": 0.05, "limite_atordoamento": 240.0,
		"descricao": "Ágil e barulhenta. O grito empurra tudo ao redor: afaste-se quando ela erguer a crista.",
		"partes": [
			{"id": "cabeca", "nome": "Crista", "vida": 480.0, "drop": "cranio_nevoa"},
			{"id": "costas", "nome": "Dorso", "vida": 560.0, "drop": "crista_nevoa"},
			{"id": "cauda", "nome": "Cauda", "vida": 400.0, "drop": "cauda_nevoa"},
		],
		"ataques": [
			{"id": "cabecada", "nome": "Cabeçada", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 4.0, "raio": 4.4, "angulo": 90.0, "preparo": 0.6, "dano": 14.0, "recuperacao": 0.8, "so_furia": false},
			{"id": "disparada", "nome": "Disparada", "tipo": "investida", "alcance_min": 5.0, "alcance_max": 18.0, "raio": 1.8, "angulo": 0.0, "preparo": 0.8, "dano": 18.0, "recuperacao": 1.0, "so_furia": false},
			{"id": "grito", "nome": "Grito da Névoa", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 6.0, "raio": 5.5, "angulo": 360.0, "preparo": 1.0, "dano": 16.0, "recuperacao": 1.1, "so_furia": false},
			{"id": "tempestade", "nome": "Tempestade de Névoa", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 8.0, "raio": 7.5, "angulo": 360.0, "preparo": 1.3, "dano": 26.0, "recuperacao": 1.3, "so_furia": true},
		],
		"loot": [
			{"item": "pele_nevoa", "chance": 1.0, "qtd": [2, 3]},
			{"item": "crista_nevoa", "chance": 0.6, "qtd": [1, 2]},
			{"item": "coracao_nevoa", "chance": 0.12, "qtd": [1, 1]},
		],
		"moedas": [170, 250], "xp": 80,
		"modelo": "Parasaurolophus",
		"visual": {"cor_corpo": "#5d7f9a", "cor_detalhe": "#e3e9f0", "cor_olhos": "#bfefff", "comprimento": 5.5,
			"altura": 2.7, "largura": 1.1, "pernas": 1.2, "cauda_segmentos": 5, "espinhos": "cristas"},
		"bioma": {"chao": "#3f7a5e", "grama": "#55895c", "ceu_topo": "#c4d6de", "ceu_horizonte": "#c4d8dc",
			"neblina": "#c4d8dc", "luz": "#f4fbff", "sombra": "#2c4048", "raio": "#e0f4ff1c",
			"tint_grama": "#dcf0e4", "tint_terra": "#e0e0d8", "tint_rocha": "#dce6ea", "arvore": "#2c6650", "pedra": "#56706e",
			"arvores": ["Pine_1", "Pine_2", "CommonTree_2", "Pine_5"],
			"plantas": ["Fern_1", "Grass_Common_Tall", "Flower_3_Group", "Clover_1", "Mushroom_Common"]},
	},
	{
		"id": "tri_espinho", "nome": "Tri-Espinho", "apelido": "O Aríete Verde", "tier": 2, "rank_minimo": 2,
		"elemento": "natureza", "vida": 4600.0, "velocidade": 4.4, "defesa": 0.18, "limite_atordoamento": 400.0,
		"descricao": "Investe de chifres baixos e não para. Quebre o escudo da cabeça para atordoá-lo mais fácil.",
		"partes": [
			{"id": "cabeca", "nome": "Escudo", "vida": 950.0, "drop": "escudo_espinho"},
			{"id": "costas", "nome": "Dorso", "vida": 1000.0, "drop": "chifre_espinho"},
			{"id": "cauda", "nome": "Cauda", "vida": 700.0, "drop": "cauda_espinho"},
		],
		"ataques": [
			{"id": "chifrada", "nome": "Chifrada", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 4.6, "raio": 5.0, "angulo": 100.0, "preparo": 0.7, "dano": 22.0, "recuperacao": 0.9, "so_furia": false},
			{"id": "ariete", "nome": "Aríete", "tipo": "investida", "alcance_min": 4.0, "alcance_max": 20.0, "raio": 2.6, "angulo": 0.0, "preparo": 0.9, "dano": 30.0, "recuperacao": 1.3, "so_furia": false},
			{"id": "pisao", "nome": "Pisão", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 5.0, "raio": 5.0, "angulo": 360.0, "preparo": 1.0, "dano": 24.0, "recuperacao": 1.1, "so_furia": false},
			{"id": "estouro", "nome": "Estouro da Manada", "tipo": "investida", "alcance_min": 0.0, "alcance_max": 22.0, "raio": 3.2, "angulo": 0.0, "preparo": 0.7, "dano": 36.0, "recuperacao": 1.0, "so_furia": true},
		],
		"loot": [
			{"item": "placa_espinho", "chance": 1.0, "qtd": [3, 4]},
			{"item": "chifre_espinho", "chance": 0.6, "qtd": [1, 2]},
			{"item": "coracao_espinho", "chance": 0.12, "qtd": [1, 1]},
		],
		"moedas": [360, 480], "xp": 150,
		"modelo": "Triceratops",
		"visual": {"cor_corpo": "#5b6b32", "cor_detalhe": "#d9c27a", "cor_olhos": "#e8ff9a", "comprimento": 7.0,
			"altura": 3.0, "largura": 2.0, "pernas": 1.1, "cauda_segmentos": 4, "espinhos": "placas"},
		"bioma": {"chao": "#4f8a3a", "grama": "#4f7a30", "ceu_topo": "#b8cca8", "ceu_horizonte": "#b6c98e",
			"neblina": "#b6c98e", "luz": "#fff4d0", "sombra": "#202c18", "raio": "#f4ffb020",
			"tint_grama": "#e8ffd0", "tint_terra": "#f0e8d8", "tint_rocha": "#e8f0e0", "arvore": "#2f7a3a", "pedra": "#7c8a7a",
			"arvores": ["CommonTree_1", "CommonTree_2", "CommonTree_4", "Pine_3", "Pine_1"],
			"plantas": ["Bush_Common", "Fern_1", "Plant_1_Big", "Plant_7_Big", "Mushroom_Common"]},
	},
	{
		"id": "jacare_mare", "nome": "Rex-Maré", "apelido": "O Senhor da Correnteza", "tier": 2, "rank_minimo": 3,
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
		"modelo": "Trex",
		"visual": {"cor_corpo": "#2f6a78", "cor_detalhe": "#bcd2c0", "cor_olhos": "#9ff3ff", "comprimento": 8.0,
			"altura": 4.0, "largura": 2.2, "pernas": 1.8, "cauda_segmentos": 7, "espinhos": "cristas"},
		"bioma": {"chao": "#3f7a5e", "grama": "#4f8456", "ceu_topo": "#a9c6cc", "ceu_horizonte": "#a9d2dc",
			"neblina": "#a8c8bc", "luz": "#effaf0", "sombra": "#1f302c", "raio": "#d8fff018",
			"tint_grama": "#d6f0dc", "tint_terra": "#d8dccf", "tint_rocha": "#d4e2e2", "arvore": "#2c6650", "pedra": "#56706e",
			"arvores": ["CommonTree_1", "DeadTree_1", "Pine_5", "CommonTree_3", "Pine_2"],
			"plantas": ["Fern_1", "Plant_1_Big", "Grass_Common_Tall", "Mushroom_Common", "Bush_Common"]},
	},
	{
		"id": "tita_cinza", "nome": "Titã-Cinza", "apelido": "A Montanha que Anda", "tier": 3, "rank_minimo": 4,
		"elemento": "fogo", "vida": 9000.0, "velocidade": 2.8, "defesa": 0.15, "limite_atordoamento": 700.0,
		"descricao": "Gigantesco e lento. O pescoço alcança longe e a cauda varre tudo: lute colado nas patas.",
		"partes": [
			{"id": "cabeca", "nome": "Cabeça", "vida": 1500.0, "drop": "cranio_tita"},
			{"id": "costas", "nome": "Dorso", "vida": 2000.0, "drop": "osso_tita"},
			{"id": "cauda", "nome": "Cauda", "vida": 1400.0, "drop": "cauda_tita"},
		],
		"ataques": [
			{"id": "pescocada", "nome": "Golpe de Pescoço", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 9.5, "raio": 10.0, "angulo": 70.0, "preparo": 1.0, "dano": 32.0, "recuperacao": 1.1, "so_furia": false},
			{"id": "chicote", "nome": "Chicote de Cauda", "tipo": "setor", "alcance_min": 0.0, "alcance_max": 7.5, "raio": 8.0, "angulo": 360.0, "preparo": 1.3, "dano": 30.0, "recuperacao": 1.2, "so_furia": false},
			{"id": "patada_tita", "nome": "Pisada Sísmica", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 7.0, "raio": 6.5, "angulo": 360.0, "preparo": 1.35, "dano": 34.0, "recuperacao": 1.3, "so_furia": false},
			{"id": "erupcao", "nome": "Erupção", "tipo": "circulo", "alcance_min": 0.0, "alcance_max": 12.0, "raio": 11.0, "angulo": 360.0, "preparo": 1.8, "dano": 44.0, "recuperacao": 1.6, "so_furia": true},
		],
		"loot": [
			{"item": "escama_tita", "chance": 1.0, "qtd": [4, 6]},
			{"item": "osso_tita", "chance": 0.7, "qtd": [1, 3]},
			{"item": "coracao_tita", "chance": 0.15, "qtd": [1, 1]},
		],
		"moedas": [700, 950], "xp": 300,
		"modelo": "Apatosaurus",
		"visual": {"cor_corpo": "#4d4442", "cor_detalhe": "#e0642a", "cor_olhos": "#ffb060", "comprimento": 16.0,
			"altura": 3.7, "largura": 2.2, "pernas": 1.8, "cauda_segmentos": 6, "espinhos": "cristas"},
		"bioma": {"chao": "#6a5040", "grama": "#7a6440", "ceu_topo": "#8a6a70", "ceu_horizonte": "#c99a7a",
			"neblina": "#c99a7a", "luz": "#ffd2a8", "sombra": "#3a241c", "raio": "#ffb07020",
			"tint_grama": "#c8a070", "tint_terra": "#b89888", "tint_rocha": "#a08880", "arvore": "#5a4a3a", "pedra": "#6a5a50",
			"arvores": ["DeadTree_1", "DeadTree_3", "TwistedTree_1"],
			"plantas": ["Grass_Wispy_Tall", "Bush_Common", "Plant_7_Big"]},
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

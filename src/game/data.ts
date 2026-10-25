// Dados de design do jogo. Tudo que é balanceamento mora aqui (e não espalhado no código).

export type Element = "neutro" | "fogo" | "natureza" | "agua";

export const ELEMENT_INFO: Record<Element, { nome: string; cor: string; icone: string }> = {
  neutro: { nome: "Neutro", cor: "#b8b8b8", icone: "◆" },
  fogo: { nome: "Fogo", cor: "#ff6a2b", icone: "🔥" },
  natureza: { nome: "Natureza", cor: "#5fc44a", icone: "🌿" },
  agua: { nome: "Água", cor: "#3aa8ff", icone: "💧" },
};

/** Fogo ► Natureza ► Água ► Fogo. Chave vence o valor. */
export const BEATS: Partial<Record<Element, Element>> = {
  fogo: "natureza",
  natureza: "agua",
  agua: "fogo",
};

export function weaknessOf(el: Element): Element | null {
  const entry = Object.entries(BEATS).find(([, beaten]) => beaten === el);
  return entry ? (entry[0] as Element) : null;
}

// ---------------------------------------------------------------- materiais

export interface Material {
  id: string;
  nome: string;
  raridade: "comum" | "incomum" | "raro";
  descricao: string;
}

export const MATERIALS: Record<string, Material> = {
  minerio: { id: "minerio", nome: "Minério de Ferro", raridade: "comum", descricao: "Veios azulados nas pedras da ilha." },
  fibra: { id: "fibra", nome: "Fibra de Capim", raridade: "comum", descricao: "Arbustos verdes espalhados pelo mapa." },

  couro_brasa: { id: "couro_brasa", nome: "Couro de Brasa", raridade: "comum", descricao: "Ainda quente ao toque." },
  garra_brasa: { id: "garra_brasa", nome: "Garra de Brasa", raridade: "incomum", descricao: "Curva e afiada." },
  presa_brasa: { id: "presa_brasa", nome: "Presa de Brasa", raridade: "incomum", descricao: "Quebre a cabeça da Onça-Brasa." },
  cauda_brasa: { id: "cauda_brasa", nome: "Cauda de Brasa", raridade: "incomum", descricao: "Corte a cauda da Onça-Brasa." },
  coracao_brasa: { id: "coracao_brasa", nome: "Coração de Brasa", raridade: "raro", descricao: "Pulsa como carvão vivo." },

  placa_musgo: { id: "placa_musgo", nome: "Placa Musgosa", raridade: "comum", descricao: "Casco coberto de musgo." },
  garra_musgo: { id: "garra_musgo", nome: "Garra Escavadora", raridade: "incomum", descricao: "Feita para cavar rocha." },
  focinho_musgo: { id: "focinho_musgo", nome: "Focinho Blindado", raridade: "incomum", descricao: "Quebre a cabeça do Tatu-Musgo." },
  cauda_musgo: { id: "cauda_musgo", nome: "Cauda de Clava", raridade: "incomum", descricao: "Corte a cauda do Tatu-Musgo." },
  coracao_musgo: { id: "coracao_musgo", nome: "Coração Verdejante", raridade: "raro", descricao: "Brotos nascem ao redor dele." },

  escama_mare: { id: "escama_mare", nome: "Escama de Maré", raridade: "comum", descricao: "Úmida, nunca seca." },
  dente_mare: { id: "dente_mare", nome: "Dente de Maré", raridade: "incomum", descricao: "Serrilhado como coral." },
  mandibula_mare: { id: "mandibula_mare", nome: "Mandíbula Abissal", raridade: "incomum", descricao: "Quebre a cabeça do Jacaré-Maré." },
  cauda_mare: { id: "cauda_mare", nome: "Cauda de Correnteza", raridade: "incomum", descricao: "Corte a cauda do Jacaré-Maré." },
  coracao_mare: { id: "coracao_mare", nome: "Coração de Maré", raridade: "raro", descricao: "Ouve-se o mar dentro dele." },
};

// ---------------------------------------------------------------- perks

export type PerkId =
  | "quebra_ossos"
  | "cacador_paciente"
  | "esquiva_afiada"
  | "ultimo_folego"
  | "pele_grossa"
  | "folego_longo";

export const PERKS: Record<PerkId, { nome: string; descricao: string }> = {
  quebra_ossos: { nome: "Quebra-Ossos", descricao: "+30% de dano em partes feridas." },
  cacador_paciente: { nome: "Caçador Paciente", descricao: "+20% de dano após 3 s sem sofrer dano." },
  esquiva_afiada: { nome: "Esquiva Afiada", descricao: "Após uma esquiva perfeita, o próximo golpe é crítico." },
  ultimo_folego: { nome: "Último Fôlego", descricao: "+25% de dano com vida abaixo de 30%." },
  pele_grossa: { nome: "Pele Grossa", descricao: "+20% de vida máxima." },
  folego_longo: { nome: "Fôlego Longo", descricao: "Esquivas gastam 25% menos stamina." },
};

// ---------------------------------------------------------------- equipamento

export type GearSlot = "arma" | "armadura";

export interface Gear {
  id: string;
  nome: string;
  slot: GearSlot;
  elemento: Element;
  /** Poder base (arma) ou defesa base em % (armadura, 0–1). */
  base: number;
  perk?: PerkId;
  /** Origem temática (fera). */
  fera?: string;
  receita: Record<string, number>;
  custo: number;
  /** Material principal usado nos upgrades. */
  materialUpgrade: string;
  /** Material raro exigido a partir do +5. */
  materialRaro: string;
}

export const GEAR: Record<string, Gear> = {
  espada_ferro: {
    id: "espada_ferro", nome: "Espada de Ferro", slot: "arma", elemento: "neutro", base: 40,
    receita: {}, custo: 0, materialUpgrade: "minerio", materialRaro: "fibra",
  },
  roupa_couro: {
    id: "roupa_couro", nome: "Roupa de Couro", slot: "armadura", elemento: "neutro", base: 0.05,
    receita: {}, custo: 0, materialUpgrade: "fibra", materialRaro: "minerio",
  },

  lamina_brasa: {
    id: "lamina_brasa", nome: "Lâmina de Brasa", slot: "arma", elemento: "fogo", base: 52, perk: "quebra_ossos", fera: "onca_brasa",
    receita: { couro_brasa: 3, garra_brasa: 2, minerio: 4 }, custo: 300, materialUpgrade: "couro_brasa", materialRaro: "coracao_brasa",
  },
  couraca_brasa: {
    id: "couraca_brasa", nome: "Couraça de Brasa", slot: "armadura", elemento: "fogo", base: 0.15, perk: "ultimo_folego", fera: "onca_brasa",
    receita: { couro_brasa: 4, presa_brasa: 1, fibra: 3 }, custo: 300, materialUpgrade: "couro_brasa", materialRaro: "coracao_brasa",
  },

  lamina_musgo: {
    id: "lamina_musgo", nome: "Lâmina Musgosa", slot: "arma", elemento: "natureza", base: 52, perk: "cacador_paciente", fera: "tatu_musgo",
    receita: { placa_musgo: 3, garra_musgo: 2, minerio: 4 }, custo: 300, materialUpgrade: "placa_musgo", materialRaro: "coracao_musgo",
  },
  couraca_musgo: {
    id: "couraca_musgo", nome: "Couraça Musgosa", slot: "armadura", elemento: "natureza", base: 0.18, perk: "pele_grossa", fera: "tatu_musgo",
    receita: { placa_musgo: 4, cauda_musgo: 1, fibra: 3 }, custo: 300, materialUpgrade: "placa_musgo", materialRaro: "coracao_musgo",
  },

  lamina_mare: {
    id: "lamina_mare", nome: "Lâmina de Maré", slot: "arma", elemento: "agua", base: 68, perk: "esquiva_afiada", fera: "jacare_mare",
    receita: { escama_mare: 4, dente_mare: 2, mandibula_mare: 1, minerio: 6 }, custo: 700, materialUpgrade: "escama_mare", materialRaro: "coracao_mare",
  },
  couraca_mare: {
    id: "couraca_mare", nome: "Couraça de Maré", slot: "armadura", elemento: "agua", base: 0.24, perk: "folego_longo", fera: "jacare_mare",
    receita: { escama_mare: 5, cauda_mare: 1, fibra: 5 }, custo: 700, materialUpgrade: "escama_mare", materialRaro: "coracao_mare",
  },
};

export const MAX_UPGRADE = 10;

// ---------------------------------------------------------------- feras

export type PartId = "cabeca" | "costas" | "cauda";

export interface PartDef {
  id: PartId;
  nome: string;
  vida: number;
  /** Cauda só pode ser cortada; as outras quebram. */
  drop: string;
}

export interface AttackDef {
  id: string;
  nome: string;
  tipo: "setor" | "investida" | "circulo";
  /** Distância para decidir usar o ataque. */
  alcanceMin: number;
  alcanceMax: number;
  /** Tamanho da área de dano. */
  raio: number;
  /** Ângulo do setor em graus (360 = giro completo). */
  angulo?: number;
  preparo: number;
  dano: number;
  recuperacao: number;
  soFuria?: boolean;
}

export interface LootEntry {
  item: string;
  chance: number;
  qtd: [number, number];
}

export interface BeastVisual {
  corCorpo: string;
  corDetalhe: string;
  corOlhos: string;
  comprimento: number;
  altura: number;
  largura: number;
  pernas: number;
  caudaSegmentos: number;
  espinhos: "chamas" | "placas" | "cristas";
}

export interface BeastDef {
  id: string;
  nome: string;
  apelido: string;
  tier: number;
  rankMinimo: number;
  elemento: Element;
  vida: number;
  velocidade: number;
  defesa: number;
  limiteAtordoamento: number;
  partes: PartDef[];
  ataques: AttackDef[];
  loot: LootEntry[];
  moedas: [number, number];
  xp: number;
  visual: BeastVisual;
  descricao: string;
}

export const BEASTS: BeastDef[] = [
  {
    id: "onca_brasa",
    nome: "Onça-Brasa",
    apelido: "A Fera das Cinzas",
    tier: 1,
    rankMinimo: 1,
    elemento: "fogo",
    vida: 2600,
    velocidade: 5.2,
    defesa: 0.05,
    limiteAtordoamento: 260,
    descricao: "Rápida e agressiva. Avança em linha reta: esquive para o lado e puna a recuperação.",
    partes: [
      { id: "cabeca", nome: "Cabeça", vida: 520, drop: "presa_brasa" },
      { id: "costas", nome: "Costas", vida: 620, drop: "garra_brasa" },
      { id: "cauda", nome: "Cauda", vida: 420, drop: "cauda_brasa" },
    ],
    ataques: [
      { id: "patada", nome: "Patada", tipo: "setor", alcanceMin: 0, alcanceMax: 4.2, raio: 4.6, angulo: 110, preparo: 0.65, dano: 16, recuperacao: 0.8 },
      { id: "investida", nome: "Investida", tipo: "investida", alcanceMin: 5, alcanceMax: 18, raio: 2.0, preparo: 0.85, dano: 22, recuperacao: 1.1 },
      { id: "explosao", nome: "Explosão de Brasas", tipo: "circulo", alcanceMin: 0, alcanceMax: 7, raio: 6.5, preparo: 1.25, dano: 28, recuperacao: 1.3, soFuria: true },
    ],
    loot: [
      { item: "couro_brasa", chance: 1, qtd: [2, 3] },
      { item: "garra_brasa", chance: 0.6, qtd: [1, 2] },
      { item: "coracao_brasa", chance: 0.12, qtd: [1, 1] },
    ],
    moedas: [180, 260],
    xp: 80,
    visual: {
      corCorpo: "#d9712c", corDetalhe: "#3a1d10", corOlhos: "#ffe066",
      comprimento: 3.6, altura: 1.5, largura: 1.4, pernas: 1.3, caudaSegmentos: 5, espinhos: "chamas",
    },
  },
  {
    id: "tatu_musgo",
    nome: "Tatu-Musgo",
    apelido: "O Muro Vivo",
    tier: 1,
    rankMinimo: 1,
    elemento: "natureza",
    vida: 3400,
    velocidade: 3.6,
    defesa: 0.15,
    limiteAtordoamento: 320,
    descricao: "Lento e blindado. Rola sobre você e gira a cauda em clava. Fique atrás dele.",
    partes: [
      { id: "cabeca", nome: "Cabeça", vida: 600, drop: "focinho_musgo" },
      { id: "costas", nome: "Casco", vida: 900, drop: "garra_musgo" },
      { id: "cauda", nome: "Cauda", vida: 500, drop: "cauda_musgo" },
    ],
    ataques: [
      { id: "focinhada", nome: "Focinhada", tipo: "setor", alcanceMin: 0, alcanceMax: 4, raio: 4.2, angulo: 80, preparo: 0.75, dano: 18, recuperacao: 0.9 },
      { id: "rolamento", nome: "Rolamento", tipo: "investida", alcanceMin: 4, alcanceMax: 16, raio: 2.4, preparo: 1.0, dano: 24, recuperacao: 1.4 },
      { id: "giro_cauda", nome: "Giro da Clava", tipo: "setor", alcanceMin: 0, alcanceMax: 5, raio: 5.4, angulo: 360, preparo: 0.95, dano: 20, recuperacao: 1.0 },
      { id: "terremoto", nome: "Terremoto", tipo: "circulo", alcanceMin: 0, alcanceMax: 8, raio: 7.5, preparo: 1.4, dano: 30, recuperacao: 1.5, soFuria: true },
    ],
    loot: [
      { item: "placa_musgo", chance: 1, qtd: [2, 3] },
      { item: "garra_musgo", chance: 0.6, qtd: [1, 2] },
      { item: "coracao_musgo", chance: 0.12, qtd: [1, 1] },
    ],
    moedas: [200, 280],
    xp: 90,
    visual: {
      corCorpo: "#6f8f3a", corDetalhe: "#3d4a22", corOlhos: "#c8ff6a",
      comprimento: 3.4, altura: 1.8, largura: 2.0, pernas: 0.9, caudaSegmentos: 4, espinhos: "placas",
    },
  },
  {
    id: "jacare_mare",
    nome: "Jacaré-Maré",
    apelido: "O Senhor da Correnteza",
    tier: 2,
    rankMinimo: 3,
    elemento: "agua",
    vida: 5200,
    velocidade: 4.6,
    defesa: 0.12,
    limiteAtordoamento: 420,
    descricao: "Mordidas rápidas e uma cauda que varre tudo. Na fúria, explode em ondas.",
    partes: [
      { id: "cabeca", nome: "Mandíbula", vida: 900, drop: "mandibula_mare" },
      { id: "costas", nome: "Dorso", vida: 1100, drop: "dente_mare" },
      { id: "cauda", nome: "Cauda", vida: 800, drop: "cauda_mare" },
    ],
    ataques: [
      { id: "mordida", nome: "Mordida", tipo: "setor", alcanceMin: 0, alcanceMax: 4.8, raio: 5.2, angulo: 60, preparo: 0.5, dano: 22, recuperacao: 0.7 },
      { id: "bote", nome: "Bote", tipo: "investida", alcanceMin: 5, alcanceMax: 17, raio: 2.2, preparo: 0.7, dano: 26, recuperacao: 1.0 },
      { id: "varredura", nome: "Varredura de Cauda", tipo: "setor", alcanceMin: 0, alcanceMax: 5.5, raio: 6, angulo: 360, preparo: 0.85, dano: 24, recuperacao: 0.9 },
      { id: "onda", nome: "Onda Abissal", tipo: "circulo", alcanceMin: 0, alcanceMax: 9, raio: 8.5, preparo: 1.2, dano: 34, recuperacao: 1.3, soFuria: true },
    ],
    loot: [
      { item: "escama_mare", chance: 1, qtd: [3, 4] },
      { item: "dente_mare", chance: 0.6, qtd: [1, 2] },
      { item: "coracao_mare", chance: 0.12, qtd: [1, 1] },
    ],
    moedas: [380, 500],
    xp: 160,
    visual: {
      corCorpo: "#2f7f8f", corDetalhe: "#163f4a", corOlhos: "#9ff3ff",
      comprimento: 5.2, altura: 1.1, largura: 1.6, pernas: 0.7, caudaSegmentos: 7, espinhos: "cristas",
    },
  },
];

export function beastById(id: string): BeastDef {
  const b = BEASTS.find((x) => x.id === id);
  if (!b) throw new Error(`Fera desconhecida: ${id}`);
  return b;
}

// ---------------------------------------------------------------- jogador

export const PLAYER = {
  vida: 100,
  stamina: 100,
  regenStamina: 30,
  atrasoRegen: 0.5,
  custoEsquiva: 25,
  velocidade: 6.2,
  pocoes: 3,
  curaPocao: 40,
  desmaiosMaximos: 3,
} as const;

/** Multiplicadores de cada golpe da espada. */
export const MOTION = {
  leve: [1.0, 1.1, 1.45],
  pesadoMin: 1.8,
  pesadoMax: 2.7,
} as const;

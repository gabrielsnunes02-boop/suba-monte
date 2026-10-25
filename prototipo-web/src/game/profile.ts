import { GEAR, type Gear, type GearSlot } from "./data";
import { applyXp, mergeCounts, upgradeCost } from "./formulas";

export interface BestiaryEntry {
  abates: number;
  partesQuebradas: number;
  melhorTempo: number | null;
}

export interface Profile {
  versao: 1;
  moedas: number;
  rank: number;
  xp: number;
  inventario: Record<string, number>;
  /** Equipamentos possuídos → nível de upgrade. */
  equipamentos: Record<string, number>;
  equipado: Record<GearSlot, string>;
  bestiario: Record<string, BestiaryEntry>;
}

export function newProfile(): Profile {
  return {
    versao: 1,
    moedas: 200,
    rank: 1,
    xp: 0,
    inventario: { minerio: 4, fibra: 4 },
    equipamentos: { espada_ferro: 0, roupa_couro: 0 },
    equipado: { arma: "espada_ferro", armadura: "roupa_couro" },
    bestiario: {},
  };
}

export function hasAll(inv: Record<string, number>, need: Record<string, number>): boolean {
  return Object.entries(need).every(([k, v]) => (inv[k] ?? 0) >= v);
}

function spend(inv: Record<string, number>, need: Record<string, number>): Record<string, number> {
  const out = { ...inv };
  for (const [k, v] of Object.entries(need)) {
    out[k] = (out[k] ?? 0) - v;
    if (out[k] <= 0) delete out[k];
  }
  return out;
}

export function canCraft(p: Profile, gear: Gear): boolean {
  return !(gear.id in p.equipamentos) && p.moedas >= gear.custo && hasAll(p.inventario, gear.receita);
}

export function craft(p: Profile, gearId: string): Profile {
  const gear = GEAR[gearId];
  if (!gear || !canCraft(p, gear)) throw new Error("Não é possível fabricar este item.");
  return {
    ...p,
    moedas: p.moedas - gear.custo,
    inventario: spend(p.inventario, gear.receita),
    equipamentos: { ...p.equipamentos, [gear.id]: 0 },
  };
}

export function canUpgrade(p: Profile, gearId: string): boolean {
  const level = p.equipamentos[gearId];
  if (level === undefined) return false;
  const cost = upgradeCost(GEAR[gearId], level);
  return !!cost && p.moedas >= cost.moedas && hasAll(p.inventario, cost.materiais);
}

export function upgrade(p: Profile, gearId: string): Profile {
  if (!canUpgrade(p, gearId)) throw new Error("Não é possível melhorar este item.");
  const level = p.equipamentos[gearId];
  const cost = upgradeCost(GEAR[gearId], level)!;
  return {
    ...p,
    moedas: p.moedas - cost.moedas,
    inventario: spend(p.inventario, cost.materiais),
    equipamentos: { ...p.equipamentos, [gearId]: level + 1 },
  };
}

export function equip(p: Profile, gearId: string): Profile {
  const gear = GEAR[gearId];
  if (!gear || !(gearId in p.equipamentos)) throw new Error("Item não possuído.");
  return { ...p, equipado: { ...p.equipado, [gear.slot]: gearId } };
}

export interface HuntResult {
  feraId: string;
  vitoria: boolean;
  tempo: number;
  partesQuebradas: number;
  loot: Record<string, number>;
  moedas: number;
  xp: number;
}

export function applyHuntResult(p: Profile, r: HuntResult): { profile: Profile; subiuRank: number } {
  const xp = applyXp(p.rank, p.xp, r.xp);
  const prev = p.bestiario[r.feraId] ?? { abates: 0, partesQuebradas: 0, melhorTempo: null };
  const entry: BestiaryEntry = r.vitoria
    ? {
        abates: prev.abates + 1,
        partesQuebradas: prev.partesQuebradas + r.partesQuebradas,
        melhorTempo: prev.melhorTempo === null ? r.tempo : Math.min(prev.melhorTempo, r.tempo),
      }
    : { ...prev, partesQuebradas: prev.partesQuebradas + r.partesQuebradas };
  return {
    profile: {
      ...p,
      moedas: p.moedas + r.moedas,
      rank: xp.rank,
      xp: xp.xp,
      inventario: mergeCounts(p.inventario, r.loot),
      bestiario: { ...p.bestiario, [r.feraId]: entry },
    },
    subiuRank: xp.subiu,
  };
}

// ---------------------------------------------------------------- persistência (offline-first)

const KEY = "suba-monte:perfil";

export function loadProfile(): Profile {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) {
      const p = JSON.parse(raw) as Profile;
      if (p.versao === 1) return { ...newProfile(), ...p };
    }
  } catch {
    // armazenamento indisponível: segue com perfil novo
  }
  return newProfile();
}

export function saveProfile(p: Profile): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(p));
  } catch {
    // modo privado/bloqueado: progresso fica só na sessão
  }
}

export function resetProfile(): Profile {
  try {
    localStorage.removeItem(KEY);
  } catch {
    // ignora
  }
  return newProfile();
}

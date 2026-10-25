import { BEATS, type Element, type Gear, type LootEntry, MAX_UPGRADE } from "./data";

export const CRIT_CHANCE = 0.05;
export const CRIT_MULT = 1.5;
export const PERK_BONUS_CAP = 1;
export const WOUND_MULT = 1.3;

/** Forte ×1,5 · neutro ×1 · fraco ×0,75. Neutro nunca tem vantagem nem desvantagem. */
export function elementMultiplier(attack: Element, defender: Element): number {
  if (attack === "neutro" || defender === "neutro") return 1;
  if (BEATS[attack] === defender) return 1.5;
  if (BEATS[defender] === attack) return 0.75;
  return 1;
}

/** Quanto a armadura reduz do dano de um elemento (resistência ou fraqueza). */
export function elementalResistance(armor: Element, incoming: Element): number {
  if (armor === "neutro" || incoming === "neutro") return 1;
  if (armor === incoming) return 0.8;
  if (BEATS[incoming] === armor) return 1.2;
  return 1;
}

export interface DamageInput {
  base: number;
  motion: number;
  perkBonus: number;
  crit: boolean;
  elementMult: number;
  partMult: number;
  defense: number;
}

export function computeDamage(d: DamageInput): number {
  const perks = 1 + Math.min(Math.max(d.perkBonus, 0), PERK_BONUS_CAP);
  const crit = d.crit ? CRIT_MULT : 1;
  const raw = d.base * d.motion * perks * crit * d.elementMult * d.partMult * (1 - d.defense);
  return Math.max(1, Math.round(raw));
}

export function computeIncoming(rawDamage: number, armorDefense: number, resistMult: number): number {
  return Math.max(1, Math.round(rawDamage * (1 - armorDefense) * resistMult));
}

/** Cada nível de upgrade dá +8% sobre o valor base. */
export function gearValue(gear: Gear, level: number): number {
  const v = gear.base * (1 + 0.08 * level);
  return gear.slot === "arma" ? Math.round(v) : Math.min(0.6, v);
}

export interface UpgradeCost {
  moedas: number;
  materiais: Record<string, number>;
}

/** Custo para ir do nível `level` para `level + 1`. Null se já está no máximo. */
export function upgradeCost(gear: Gear, level: number): UpgradeCost | null {
  if (level >= MAX_UPGRADE) return null;
  const materiais: Record<string, number> = { [gear.materialUpgrade]: level + 1 };
  if (level >= 5) materiais[gear.materialRaro] = (materiais[gear.materialRaro] ?? 0) + 1;
  return { moedas: Math.round(100 * Math.pow(1.35, level)), materiais };
}

/** XP necessário para sair do rank `n` para o `n + 1`. */
export function xpForRank(n: number): number {
  return Math.round(100 * Math.pow(n, 1.6));
}

export function applyXp(rank: number, xp: number, gained: number): { rank: number; xp: number; subiu: number } {
  let r = rank;
  let x = xp + gained;
  let subiu = 0;
  while (x >= xpForRank(r)) {
    x -= xpForRank(r);
    r++;
    subiu++;
  }
  return { rank: r, xp: x, subiu };
}

export type Rng = () => number;

export function randInt(rng: Rng, min: number, max: number): number {
  return min + Math.floor(rng() * (max - min + 1));
}

export function rollLoot(table: LootEntry[], rng: Rng): Record<string, number> {
  const out: Record<string, number> = {};
  for (const e of table) {
    if (rng() < e.chance) out[e.item] = (out[e.item] ?? 0) + randInt(rng, e.qtd[0], e.qtd[1]);
  }
  return out;
}

export function mergeCounts(a: Record<string, number>, b: Record<string, number>): Record<string, number> {
  const out = { ...a };
  for (const [k, v] of Object.entries(b)) out[k] = (out[k] ?? 0) + v;
  return out;
}

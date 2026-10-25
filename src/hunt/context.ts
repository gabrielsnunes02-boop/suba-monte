import type * as THREE from "three";
import type { Element, Gear } from "../game/data";
import type { Beast } from "./beast";
import type { FloatingText, Particles } from "./fx";
import type { Player } from "./player";

/** O que jogador e fera podem pedir à caçada (efeitos, eventos, referências mútuas). */
export interface HuntContext {
  scene: THREE.Scene;
  particles: Particles;
  text: FloatingText;
  rng: () => number;
  player: Player;
  beast: Beast;
  weapon: Gear;
  weaponLevel: number;
  armor: Gear;
  armorLevel: number;
  shake(amount: number): void;
  hitstop(seconds: number): void;
  slowmo(seconds: number, scale: number): void;
  banner(text: string, cls?: string): void;
  /** Fera tenta acertar o jogador. Retorna true se o golpe foi consumido (acertou ou foi esquivado). */
  hitPlayer(rawDamage: number, element: Element, from: THREE.Vector3): boolean;
  onPlayerDown(): void;
  onBeastDead(): void;
  onPartBroken(drop: string, nome: string): void;
}

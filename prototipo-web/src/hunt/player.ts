import * as THREE from "three";
import { ELEMENT_INFO, MOTION, PERKS, PLAYER, type Element, type PerkId } from "../game/data";
import {
  CRIT_CHANCE,
  WOUND_MULT,
  computeDamage,
  computeIncoming,
  elementMultiplier,
  elementalResistance,
  gearValue,
} from "../game/formulas";
import type { HuntContext } from "./context";
import type { Input } from "./input";
import { ARENA_RADIUS, buildPlayer, type PlayerModel } from "./models";

type State = "livre" | "ataque" | "carregando" | "pesado" | "esquiva" | "bebendo" | "atingido" | "caido";

const LIGHT = [
  { dur: 0.42, hitAt: 0.14 },
  { dur: 0.42, hitAt: 0.14 },
  { dur: 0.56, hitAt: 0.22 },
];
const HEAVY = { dur: 0.62, hitAt: 0.22, chargeTime: 1.0 };
const DODGE = { dur: 0.42, iframes: 0.32, speed: 13 };
const DRINK = { dur: 0.9 };
const STAGGER = { dur: 0.45 };
const SOFT_LOCK_RANGE = 9;
const REACH = 1.9;

function wrapAngle(a: number): number {
  return Math.atan2(Math.sin(a), Math.cos(a));
}

export class Player {
  model: PlayerModel;
  pos: THREE.Vector3;
  facing = 0;
  maxHp: number;
  hp: number;
  stamina: number = PLAYER.stamina;
  potions: number = PLAYER.pocoes;
  state: State = "livre";
  /** Bônus "Esquiva Afiada": próximo golpe garantido crítico. */
  sharp = false;

  private perks: Set<PerkId>;
  private t = 0;
  private time = 0;
  private lastDamagedAt = -99;
  private staminaDelay = 0;
  private combo = 0;
  private comboQueued = false;
  private hitDone = false;
  private charge = 0;
  private healLeft = 0;
  private dodgeDir = new THREE.Vector3();
  private knock = new THREE.Vector3();
  private walkPhase = 0;
  private tmp = new THREE.Vector3();

  constructor(private ctx: HuntContext) {
    const { weapon, armor } = ctx;
    this.perks = new Set([weapon.perk, armor.perk].filter((p): p is PerkId => !!p));
    this.maxHp = Math.round(PLAYER.vida * (this.perks.has("pele_grossa") ? 1.2 : 1));
    this.hp = this.maxHp;
    this.model = buildPlayer(ELEMENT_INFO[armor.elemento].cor, ELEMENT_INFO[weapon.elemento].cor);
    this.pos = this.model.root.position;
    ctx.scene.add(this.model.root);
  }

  get perkNames(): string[] {
    return [...this.perks].map((p) => PERKS[p].nome);
  }

  get invulnerable(): boolean {
    return (this.state === "esquiva" && this.t < DODGE.iframes) || this.state === "caido";
  }

  get forward(): THREE.Vector3 {
    return this.tmp.set(Math.sin(this.facing), 0, Math.cos(this.facing));
  }

  update(dt: number, input: Input): void {
    const ctx = this.ctx;
    this.time += dt;
    this.t += dt;

    const pressed = input.consumeAttackPressed();
    const released = input.consumeAttackReleased();
    const dodge = input.consumeDodge();
    const potion = input.consumePotion();

    if (this.staminaDelay > 0) this.staminaDelay -= dt;
    else if (this.state !== "esquiva") this.stamina = Math.min(PLAYER.stamina, this.stamina + PLAYER.regenStamina * dt);

    // Joystick na tela → mundo (câmera olha para -Z).
    const mv = new THREE.Vector3(input.move.x, 0, -input.move.y);
    const mag = Math.min(1, mv.length());
    const moving = mag > 0.15;
    if (moving) mv.normalize();

    let speedMul = 0;
    switch (this.state) {
      case "livre":
        speedMul = 1;
        if (moving) this.turnTo(Math.atan2(mv.x, mv.z), dt, 18);
        if (dodge) this.tryDodge(mv, moving);
        else if (pressed) this.startLight(0);
        else if (potion) this.tryDrink();
        break;

      case "ataque": {
        const s = LIGHT[this.combo];
        if (this.t < s.hitAt) this.pos.addScaledVector(this.forward, 2.6 * dt);
        if (!this.hitDone && this.t >= s.hitAt) this.strike(MOTION.leve[this.combo], false);
        if (pressed && this.t > s.dur * 0.3) this.comboQueued = true;
        if (dodge && this.t > s.hitAt) {
          this.tryDodge(mv, moving);
          break;
        }
        if (this.t >= s.dur) {
          if (this.comboQueued && this.combo < 2) this.startLight(this.combo + 1);
          else if (input.attackHeld) this.setState("carregando");
          else this.setState("livre");
        }
        break;
      }

      case "carregando":
        speedMul = 0.3;
        if (moving) this.turnTo(Math.atan2(mv.x, mv.z), dt, 6);
        this.charge = Math.min(1, this.t / HEAVY.chargeTime);
        this.model.bladeMat.emissiveIntensity = 0.25 + this.charge * 1.6;
        if (this.charge >= 1 && Math.random() < 0.3) ctx.particles.burst(this.model.blade.getWorldPosition(new THREE.Vector3()), "#fff3b0", 1, 2, 2);
        if (dodge) {
          this.model.bladeMat.emissiveIntensity = 0.25;
          this.tryDodge(mv, moving);
        } else if (released || !input.attackHeld) {
          this.softLock();
          this.setState("pesado");
        }
        break;

      case "pesado":
        if (this.t < HEAVY.hitAt) this.pos.addScaledVector(this.forward, 1.5 * dt);
        if (!this.hitDone && this.t >= HEAVY.hitAt) {
          this.strike(MOTION.pesadoMin + (MOTION.pesadoMax - MOTION.pesadoMin) * this.charge, true);
          this.model.bladeMat.emissiveIntensity = 0.25;
        }
        if (dodge && this.t > HEAVY.hitAt + 0.1) this.tryDodge(mv, moving);
        else if (this.t >= HEAVY.dur) this.setState("livre");
        break;

      case "esquiva": {
        const k = Math.max(0, 1 - this.t / DODGE.dur);
        this.pos.addScaledVector(this.dodgeDir, DODGE.speed * Math.pow(k, 1.2) * dt);
        if (this.t >= DODGE.dur) this.setState("livre");
        break;
      }

      case "bebendo": {
        speedMul = 0.35;
        if (moving) this.turnTo(Math.atan2(mv.x, mv.z), dt, 8);
        const heal = Math.min(this.healLeft, (PLAYER.curaPocao / DRINK.dur) * dt);
        this.healLeft -= heal;
        this.hp = Math.min(this.maxHp, this.hp + heal);
        if (Math.random() < 0.4) ctx.particles.burst(this.pos.clone().setY(1.2), "#7dff8a", 1, 1.5, 3);
        if (this.t >= DRINK.dur) this.setState("livre");
        break;
      }

      case "atingido":
        this.pos.addScaledVector(this.knock, dt);
        this.knock.multiplyScalar(Math.pow(0.02, dt));
        if (this.t >= STAGGER.dur) this.setState("livre");
        break;

      case "caido":
        break;
    }

    if (speedMul > 0 && moving) {
      this.pos.addScaledVector(mv, PLAYER.velocidade * speedMul * mag * dt);
      this.walkPhase += dt * 11 * mag;
    }

    // Limites da ilha e colisão com a fera.
    const r = Math.hypot(this.pos.x, this.pos.z);
    if (r > ARENA_RADIUS - 1) this.pos.multiplyScalar((ARENA_RADIUS - 1) / r);
    this.pos.y = 0;
    if (this.state !== "caido") ctx.beast.pushOut(this.pos, 0.5);

    this.animate(moving && speedMul > 0);
  }

  /** Golpe da fera chega no jogador. */
  takeHit(raw: number, element: Element, from: THREE.Vector3): "acertou" | "esquivou" | "nada" {
    if (this.state === "caido") return "nada";
    if (this.invulnerable) return "esquivou";
    const ctx = this.ctx;
    const def = gearValue(ctx.armor, ctx.armorLevel);
    const dmg = computeIncoming(raw, def, elementalResistance(ctx.armor.elemento, element));
    this.hp = Math.max(0, this.hp - dmg);
    this.lastDamagedAt = this.time;
    this.healLeft = 0;
    this.model.bladeMat.emissiveIntensity = 0.25;
    ctx.text.spawn(this.pos.clone().setY(2.4), `-${dmg}`, "ft-player");
    ctx.particles.burst(this.pos.clone().setY(1.2), "#ff4040", 8, 5, 4);
    ctx.shake(0.35);

    this.knock.subVectors(this.pos, from).setY(0);
    if (this.knock.lengthSq() < 0.01) this.knock.set(0, 0, 1);
    this.knock.normalize().multiplyScalar(11);

    if (this.hp <= 0) {
      this.setState("caido");
      ctx.onPlayerDown();
    } else {
      this.setState("atingido");
    }
    return "acertou";
  }

  respawn(at: THREE.Vector3): void {
    this.pos.copy(at);
    this.hp = this.maxHp;
    this.stamina = PLAYER.stamina;
    this.setState("livre");
  }

  // ------------------------------------------------------------ ações

  private setState(s: State): void {
    this.state = s;
    this.t = 0;
    this.hitDone = false;
    if (s !== "ataque") this.comboQueued = false;
    if (s === "carregando") this.charge = 0;
  }

  private startLight(step: number): void {
    this.softLock();
    this.setState("ataque");
    this.combo = step;
  }

  private tryDodge(mv: THREE.Vector3, moving: boolean): void {
    const cost = PLAYER.custoEsquiva * (this.perks.has("folego_longo") ? 0.75 : 1);
    if (this.stamina < cost) {
      this.ctx.text.spawn(this.pos.clone().setY(2.4), "sem fôlego", "ft-info");
      return;
    }
    this.stamina -= cost;
    this.staminaDelay = PLAYER.atrasoRegen;
    if (moving) this.dodgeDir.copy(mv);
    else this.dodgeDir.copy(this.forward).multiplyScalar(-1);
    this.facing = Math.atan2(this.dodgeDir.x, this.dodgeDir.z);
    this.setState("esquiva");
  }

  private tryDrink(): void {
    if (this.potions <= 0 || this.hp >= this.maxHp) {
      this.ctx.text.spawn(this.pos.clone().setY(2.4), this.potions <= 0 ? "sem poções" : "vida cheia", "ft-info");
      return;
    }
    this.potions--;
    this.healLeft = PLAYER.curaPocao;
    this.setState("bebendo");
  }

  private softLock(): void {
    const b = this.ctx.beast;
    if (!b.alive) return;
    const dx = b.pos.x - this.pos.x;
    const dz = b.pos.z - this.pos.z;
    if (Math.hypot(dx, dz) - b.radius < SOFT_LOCK_RANGE) this.facing = Math.atan2(dx, dz);
  }

  private turnTo(target: number, dt: number, rate: number): void {
    const d = wrapAngle(target - this.facing);
    this.facing += Math.sign(d) * Math.min(Math.abs(d), rate * dt);
  }

  private strike(motion: number, heavy: boolean): void {
    this.hitDone = true;
    const ctx = this.ctx;
    const beast = ctx.beast;
    const point = this.pos.clone().addScaledVector(this.forward, REACH).setY(1.2);
    const hit = beast.findHitPart(point);
    if (!hit) return;

    const part = hit.part ? beast.parts[hit.part] : null;
    const wounded = !!part?.ferida;
    let bonus = 0;
    if (wounded && this.perks.has("quebra_ossos")) bonus += 0.3;
    if (this.perks.has("cacador_paciente") && this.time - this.lastDamagedAt > 3) bonus += 0.2;
    if (this.perks.has("ultimo_folego") && this.hp < this.maxHp * 0.3) bonus += 0.25;

    const crit = this.sharp || ctx.rng() < CRIT_CHANCE;
    this.sharp = false;
    const elMult = elementMultiplier(ctx.weapon.elemento, beast.def.elemento);
    const dmg = computeDamage({
      base: gearValue(ctx.weapon, ctx.weaponLevel),
      motion,
      perkBonus: bonus,
      crit,
      elementMult: elMult,
      partMult: wounded ? WOUND_MULT : 1,
      defense: beast.def.defesa,
    });
    const stagger = hit.part === "cabeca" ? dmg * (heavy ? 0.7 : 0.25) : 0;
    beast.applyDamage(hit.part, dmg, stagger);

    const cls = crit ? "ft-crit" : elMult > 1 ? "ft-weak" : elMult < 1 ? "ft-resist" : "";
    ctx.text.spawn(point.clone().setY(2.2), `${dmg}${crit ? "!" : ""}`, cls);
    ctx.particles.burst(point, ELEMENT_INFO[ctx.weapon.elemento].cor, heavy ? 14 : 7, heavy ? 8 : 5, 4);
    ctx.hitstop(heavy ? 0.09 : 0.045);
    ctx.shake(heavy ? 0.3 : 0.1);
  }

  // ------------------------------------------------------------ animação

  private animate(walking: boolean): void {
    const m = this.model;
    m.root.rotation.y = this.facing;
    m.body.rotation.set(0, 0, 0);
    m.body.position.set(0, 0, 0);

    const swing = walking ? Math.sin(this.walkPhase) * 0.7 : 0;
    m.legs[0].rotation.x = swing;
    m.legs[1].rotation.x = -swing;
    if (walking) m.body.position.y = Math.abs(Math.cos(this.walkPhase)) * 0.08;

    const arm = m.armPivot;
    arm.rotation.set(0.9, 0.35, 0);
    const ease = (x: number) => 1 - Math.pow(1 - Math.min(1, Math.max(0, x)), 3);

    switch (this.state) {
      case "ataque": {
        const s = LIGHT[this.combo];
        const p = ease(this.t / (s.hitAt + 0.06));
        const dir = this.combo === 1 ? -1 : 1;
        arm.rotation.set(0.15, dir * (1.7 - 3.2 * p), 0);
        m.body.rotation.y = dir * (0.4 - 0.8 * p);
        break;
      }
      case "carregando":
        arm.rotation.set(-1.7 + Math.sin(this.t * 30) * 0.03 * this.charge, 0.2, 0);
        m.body.rotation.x = -0.15;
        break;
      case "pesado": {
        const p = ease(this.t / (HEAVY.hitAt + 0.04));
        arm.rotation.set(-1.7 + 3.0 * p, 0.1, 0);
        m.body.rotation.x = -0.15 + 0.45 * p;
        break;
      }
      case "esquiva": {
        // Rolamento em torno do centro do corpo (y = 1), não dos pés.
        const p = Math.min(1, this.t / (DODGE.dur * 0.85));
        const a = p * Math.PI * 2;
        m.body.rotation.x = a;
        m.body.position.set(0, 1 - Math.cos(a) - Math.sin(p * Math.PI) * 0.45, -Math.sin(a));
        break;
      }
      case "bebendo":
        arm.rotation.set(1.2, 0.8, 0);
        m.body.rotation.x = -0.2;
        break;
      case "atingido":
        m.body.rotation.x = -0.4 * (1 - this.t / STAGGER.dur);
        break;
      case "caido":
        m.body.rotation.x = -Math.PI / 2;
        m.body.position.y = 0.35;
        break;
    }
  }
}

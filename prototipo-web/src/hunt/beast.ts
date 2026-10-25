import * as THREE from "three";
import { ELEMENT_INFO, type AttackDef, type BeastDef, type PartDef, type PartId } from "../game/data";
import type { HuntContext } from "./context";
import { ARENA_RADIUS, buildBeast, buildTelegraph, type BeastModel } from "./models";

type State = "ocioso" | "perseguir" | "preparar" | "atacar" | "recuperar" | "rugir" | "atordoado" | "morto";

export interface PartState {
  def: PartDef;
  dano: number;
  ferida: boolean;
  quebrada: boolean;
}

const DASH_TIME = 0.9;
const DASH_SPEED_MULT = 3.2;
const FURY_HP = 0.4;
const STUN_TIME = 3.5;

function wrapAngle(a: number): number {
  return Math.atan2(Math.sin(a), Math.cos(a));
}

export class Beast {
  model: BeastModel;
  pos: THREE.Vector3;
  facing = Math.PI;
  hp: number;
  maxHp: number;
  fury = false;
  state: State = "ocioso";
  parts: Record<PartId, PartState>;
  readonly radius: number;
  readonly halfLen: number;

  private t = 0;
  private think = 1;
  private attack: AttackDef | null = null;
  private lastAttack = "";
  private telegraph: { group: THREE.Group; fill: THREE.Mesh } | null = null;
  private dashDir = new THREE.Vector3();
  private dashSpeed = 0;
  private dashHit = false;
  private stagger = 0;
  private staggerLimit: number;
  private walkPhase = 0;
  private flash = 0;
  private wander = new THREE.Vector3();
  private deadNotified = false;
  private roarIsFury = false;
  private severedTail: { obj: THREE.Object3D; vy: number; spin: number } | null = null;
  private tmpA = new THREE.Vector3();
  private tmpB = new THREE.Vector3();

  constructor(public def: BeastDef, private ctx: HuntContext) {
    this.model = buildBeast(def);
    this.pos = this.model.root.position;
    this.pos.set(0, 0, -12);
    this.maxHp = this.hp = def.vida;
    this.staggerLimit = def.limiteAtordoamento;
    this.radius = def.visual.largura / 2 + 0.25;
    this.halfLen = def.visual.comprimento * 0.4;
    this.parts = Object.fromEntries(
      def.partes.map((p) => [p.id, { def: p, dano: 0, ferida: false, quebrada: false }]),
    ) as Record<PartId, PartState>;
    ctx.scene.add(this.model.root);
  }

  get alive(): boolean {
    return this.state !== "morto";
  }

  get busy(): string {
    return this.attack && (this.state === "preparar" || this.state === "atacar") ? this.attack.nome : "";
  }

  update(dt: number): void {
    const ctx = this.ctx;
    const player = ctx.player;
    this.t += dt;
    const furyMul = this.fury ? 1.25 : 1;
    const toP = this.tmpA.subVectors(player.pos, this.pos).setY(0);
    const dist = toP.length();
    const angleToP = Math.atan2(toP.x, toP.z);
    const diff = wrapAngle(angleToP - this.facing);
    let moving = 0;

    switch (this.state) {
      case "ocioso": {
        if (this.wander.lengthSq() === 0 || this.pos.distanceTo(this.wander) < 1) {
          const a = ctx.rng() * Math.PI * 2;
          this.wander.set(Math.cos(a) * 10, 0, Math.sin(a) * 10 - 6);
        }
        const w = this.tmpB.subVectors(this.wander, this.pos);
        this.turn(Math.atan2(w.x, w.z), dt, 1.5);
        this.moveForward(this.def.velocidade * 0.35 * dt);
        moving = 0.35;
        if (dist < 15) this.startRoar(false);
        break;
      }

      case "perseguir": {
        this.turn(angleToP, dt, 2.6 * furyMul);
        if (dist > this.halfLen + 2.2 && Math.abs(diff) < 1.3) {
          const sp = this.def.velocidade * furyMul * Math.max(0.3, Math.cos(diff));
          this.moveForward(sp * dt);
          moving = sp / this.def.velocidade;
        }
        this.think -= dt;
        if (this.think <= 0 && player.state !== "caido") {
          this.think = 0.25 + ctx.rng() * 0.35;
          const a = this.chooseAttack(dist, diff);
          if (a) this.startAttack(a);
        }
        break;
      }

      case "preparar": {
        const a = this.attack!;
        const wind = a.preparo * (this.fury ? 0.8 : 1);
        const p = Math.min(1, this.t / wind);
        if (p < 0.55) this.turn(angleToP, dt, 3.5 * furyMul);
        if (this.telegraph) {
          this.telegraph.group.position.set(this.pos.x, 0.06, this.pos.z);
          this.telegraph.group.rotation.y = this.facing;
          if (a.tipo === "investida") this.telegraph.fill.scale.set(1, 1, p);
          else this.telegraph.fill.scale.set(p, 1, p);
        }
        this.setGlow(0.25 + 0.55 * Math.abs(Math.sin(this.t * 14)), "#ff2020");
        if (p >= 1) this.release(a, dist, diff);
        break;
      }

      case "atacar": {
        const a = this.attack!;
        if (a.tipo === "investida") {
          const step = this.dashSpeed * dt;
          this.pos.addScaledVector(this.dashDir, step);
          moving = 2.5;
          if (!this.dashHit && this.distanceTo(player.pos) < a.raio * 0.5 + 0.6) {
            this.dashHit = ctx.hitPlayer(a.dano * (this.fury ? 1.15 : 1), this.def.elemento, this.pos);
          }
          if (Math.random() < 0.5) ctx.particles.burst(this.pos.clone().setY(0.3), "#c8b08a", 1, 2, 1.5);
          const out = Math.hypot(this.pos.x, this.pos.z) > ARENA_RADIUS - 3;
          if (this.t >= DASH_TIME || out) this.setState("recuperar");
        } else if (this.t >= 0.28) {
          this.setState("recuperar");
        }
        break;
      }

      case "recuperar":
        if (this.t >= this.attack!.recuperacao) this.setState("perseguir");
        break;

      case "rugir":
        this.turn(angleToP, dt, 2);
        if (this.t > 0.25 && this.t - dt <= 0.25) {
          ctx.shake(0.6);
          ctx.particles.burst(this.model.head.getWorldPosition(new THREE.Vector3()), this.fury ? "#ff3030" : "#ffffff", 16, 7, 3);
          if (this.roarIsFury) ctx.banner(`${this.def.nome} ENFURECEU!`, "banner-fury");
        }
        if (this.t >= 1.3) this.setState("perseguir");
        break;

      case "atordoado":
        if (this.t >= STUN_TIME) this.setState("perseguir");
        break;

      case "morto":
        if (!this.deadNotified && this.t > 2) {
          this.deadNotified = true;
          ctx.onBeastDead();
        }
        break;
    }

    const r = Math.hypot(this.pos.x, this.pos.z);
    if (r > ARENA_RADIUS - 2) this.pos.multiplyScalar((ARENA_RADIUS - 2) / r);

    this.walkPhase += dt * 9 * moving;
    this.animate(dt, moving);
  }

  // ------------------------------------------------------------ IA

  private chooseAttack(dist: number, diff: number): AttackDef | null {
    const options: { a: AttackDef; w: number }[] = [];
    for (const a of this.def.ataques) {
      if (a.soFuria && !this.fury) continue;
      if (dist < a.alcanceMin || dist > a.alcanceMax) continue;
      const full = a.tipo === "circulo" || (a.angulo ?? 0) >= 360;
      if (!full && Math.abs(diff) > 0.6) continue;
      let w = 1;
      if (full) w = Math.abs(diff) > 1.2 ? 1.8 : 0.5;
      if (a.soFuria) w *= 1.4;
      if (a.id === this.lastAttack) w *= 0.4;
      options.push({ a, w });
    }
    if (!options.length) return null;
    let roll = this.ctx.rng() * options.reduce((s, o) => s + o.w, 0);
    for (const o of options) {
      roll -= o.w;
      if (roll <= 0) return o.a;
    }
    return options[options.length - 1].a;
  }

  private startAttack(a: AttackDef): void {
    this.attack = a;
    this.lastAttack = a.id;
    this.setState("preparar");
    this.dashSpeed = this.def.velocidade * DASH_SPEED_MULT * (this.fury ? 1.25 : 1);
    this.telegraph = buildTelegraph(a.tipo, a.raio, a.angulo ?? 360, this.dashSpeed * DASH_TIME);
    this.ctx.scene.add(this.telegraph.group);
  }

  private release(a: AttackDef, dist: number, diff: number): void {
    this.clearTelegraph();
    this.setGlow(0);
    this.setState("atacar");
    const ctx = this.ctx;
    const dmg = a.dano * (this.fury ? 1.15 : 1);
    const color = ELEMENT_INFO[this.def.elemento].cor;
    if (a.tipo === "investida") {
      this.dashDir.set(Math.sin(this.facing), 0, Math.cos(this.facing));
      this.dashHit = false;
      return;
    }
    let hit = false;
    if (a.tipo === "circulo") {
      hit = dist <= a.raio;
      ctx.particles.burst(this.pos.clone().setY(0.4), color, 30, a.raio * 1.6, 3);
      ctx.shake(0.5);
    } else {
      const half = ((a.angulo ?? 90) * Math.PI) / 360;
      hit = dist <= a.raio + 0.4 && ((a.angulo ?? 0) >= 360 || Math.abs(diff) <= half + 0.15);
      const front = this.pos.clone().addScaledVector(this.tmpB.set(Math.sin(this.facing), 0, Math.cos(this.facing)), this.halfLen + 1);
      ctx.particles.burst((a.angulo ?? 0) >= 360 ? this.pos.clone().setY(0.8) : front.setY(0.8), color, 12, 6, 2);
      ctx.shake(0.2);
    }
    if (hit) ctx.hitPlayer(dmg, this.def.elemento, this.pos);
  }

  private startRoar(fury: boolean): void {
    this.clearTelegraph();
    this.setGlow(0);
    this.roarIsFury = fury;
    this.setState("rugir");
  }

  private setState(s: State): void {
    this.state = s;
    this.t = 0;
    if (s !== "preparar") this.clearTelegraph();
  }

  private clearTelegraph(): void {
    if (!this.telegraph) return;
    this.ctx.scene.remove(this.telegraph.group);
    this.telegraph.group.traverse((o) => {
      if (o instanceof THREE.Mesh) (o.material as THREE.Material).dispose();
    });
    (this.telegraph.fill.geometry as THREE.BufferGeometry).dispose();
    this.telegraph = null;
  }

  private turn(target: number, dt: number, rate: number): void {
    const d = wrapAngle(target - this.facing);
    this.facing += Math.sign(d) * Math.min(Math.abs(d), rate * dt);
  }

  private moveForward(step: number): void {
    this.pos.x += Math.sin(this.facing) * step;
    this.pos.z += Math.cos(this.facing) * step;
  }

  // ------------------------------------------------------------ geometria de colisão (cápsula)

  private closestOnSpine(p: THREE.Vector3, out: THREE.Vector3): THREE.Vector3 {
    const fx = Math.sin(this.facing);
    const fz = Math.cos(this.facing);
    const rx = p.x - this.pos.x;
    const rz = p.z - this.pos.z;
    const t = Math.max(-this.halfLen, Math.min(this.halfLen, rx * fx + rz * fz));
    return out.set(this.pos.x + fx * t, 0, this.pos.z + fz * t);
  }

  /** Distância de um ponto até a superfície do corpo (negativo = dentro). */
  distanceTo(p: THREE.Vector3): number {
    const c = this.closestOnSpine(p, new THREE.Vector3());
    return Math.hypot(p.x - c.x, p.z - c.z) - this.radius;
  }

  pushOut(p: THREE.Vector3, r: number): void {
    if (this.state === "morto" && this.t > 1) return;
    const c = this.closestOnSpine(p, new THREE.Vector3());
    let dx = p.x - c.x;
    let dz = p.z - c.z;
    const d = Math.hypot(dx, dz);
    const min = this.radius + r;
    if (d >= min) return;
    if (d < 1e-4) {
      dx = Math.cos(this.facing);
      dz = -Math.sin(this.facing);
    } else {
      dx /= d;
      dz /= d;
    }
    p.x = c.x + dx * min;
    p.z = c.z + dz * min;
  }

  // ------------------------------------------------------------ receber dano

  findHitPart(strike: THREE.Vector3): { part: PartId | null } | null {
    if (!this.alive) return null;
    const v = this.def.visual;
    const radii: Record<PartId, number> = {
      cabeca: Math.max(1, v.largura * 0.5),
      costas: v.comprimento * 0.3,
      cauda: 1.1,
    };
    let best: PartId | null = null;
    let bestD = Infinity;
    const w = new THREE.Vector3();
    for (const id of Object.keys(this.parts) as PartId[]) {
      if (id === "cauda" && this.parts.cauda.quebrada) continue;
      this.model.anchors[id].getWorldPosition(w);
      const d = Math.hypot(w.x - strike.x, w.z - strike.z) - radii[id];
      if (d < bestD) {
        bestD = d;
        best = id;
      }
    }
    if (best && bestD <= 1.3) return { part: best };
    if (this.distanceTo(strike) <= 0.9) return { part: null };
    return null;
  }

  applyDamage(partId: PartId | null, dmg: number, staggerAmt: number): void {
    if (!this.alive) return;
    const ctx = this.ctx;
    this.hp = Math.max(0, this.hp - dmg);
    this.flash = 1;

    if (partId) {
      const p = this.parts[partId];
      p.dano += dmg;
      const at = this.model.anchors[partId].getWorldPosition(new THREE.Vector3());
      if (!p.ferida && p.dano >= p.def.vida * 0.5) {
        p.ferida = true;
        ctx.text.spawn(at.clone().setY(at.y + 1), "FERIDA", "ft-info");
      }
      if (!p.quebrada && p.dano >= p.def.vida) {
        p.quebrada = true;
        this.breakPart(partId, at);
      }
    }

    if (this.state === "ocioso") this.startRoar(false);

    if (this.hp <= 0) {
      this.clearTelegraph();
      this.setGlow(0);
      this.setState("morto");
      ctx.slowmo(0.8, 0.3);
      ctx.banner(`${this.def.nome} ABATIDA!`, "banner-win");
      return;
    }

    this.stagger += staggerAmt;
    if (this.stagger >= this.staggerLimit && this.state !== "atordoado") {
      this.stagger = 0;
      this.staggerLimit *= 1.35;
      this.clearTelegraph();
      this.setGlow(0);
      this.setState("atordoado");
      ctx.banner("ATORDOADA! Ataque agora!", "banner-good");
      ctx.shake(0.4);
      return;
    }

    if (!this.fury && this.hp <= this.maxHp * FURY_HP && this.state !== "atordoado") {
      this.fury = true;
      this.model.eyes.color.set("#ff2a2a");
      this.startRoar(true);
    }
  }

  private breakPart(id: PartId, at: THREE.Vector3): void {
    const ctx = this.ctx;
    const part = this.parts[id];
    ctx.particles.burst(at, "#ffffff", 24, 9, 6);
    ctx.particles.burst(at, ELEMENT_INFO[this.def.elemento].cor, 16, 7, 5);
    ctx.shake(0.45);
    ctx.hitstop(0.12);
    ctx.onPartBroken(part.def.drop, part.def.nome);

    if (id === "cauda") {
      const tail = this.model.tailRoot;
      ctx.scene.attach(tail);
      this.severedTail = { obj: tail, vy: 4, spin: (Math.random() - 0.5) * 6 };
      ctx.banner(`CAUDA CORTADA!`, "banner-good");
    } else {
      if (id === "costas") this.model.spikes.forEach((s, i) => i % 2 === 0 && (s.visible = false));
      if (id === "cabeca") this.model.partMats.cabeca.color.multiplyScalar(0.6);
      ctx.banner(`${part.def.nome.toUpperCase()} QUEBRADA!`, "banner-good");
    }
    if (id !== "cauda") this.model.partMats[id].color.offsetHSL(0, -0.2, -0.1);
  }

  private setGlow(intensity: number, color: THREE.ColorRepresentation = "#ff2020"): void {
    for (const m of this.model.bodyMats) {
      m.emissive.set(color);
      m.emissiveIntensity = intensity;
    }
  }

  // ------------------------------------------------------------ animação

  private animate(dt: number, moving: number): void {
    const m = this.model;
    m.root.rotation.y = this.facing;

    // Flash branco ao levar dano (sobrepõe o brilho de preparo).
    if (this.flash > 0) {
      this.flash = Math.max(0, this.flash - dt * 6);
      if (this.state !== "preparar") this.setGlow(this.flash * 0.9, "#ffffff");
    } else if (this.fury && this.state !== "preparar") {
      this.setGlow(0.12 + 0.08 * Math.sin(this.t * 6), "#ff3010");
    }

    const legSwing = Math.sin(this.walkPhase) * Math.min(0.7, 0.35 + moving * 0.2) * (moving > 0.05 ? 1 : 0);
    m.legs.forEach((l, i) => (l.rotation.x = (i === 0 || i === 3 ? 1 : -1) * legSwing));

    const time = performance.now() / 1000;
    m.tailSegments.forEach((s, i) => (s.rotation.y = Math.sin(time * 2.2 + i * 0.6) * (0.12 + i * 0.03)));

    let poseY = 0;
    let poseX = 0;
    let poseZ = 0;
    let headX = 0;
    let poseSpin = 0;
    const p = this.attack ? Math.min(1, this.t / (this.attack.preparo * (this.fury ? 0.8 : 1))) : 0;

    switch (this.state) {
      case "preparar":
        if (this.attack?.tipo === "investida") {
          poseY = -0.25 * p;
          poseX = 0.15 * p;
          headX = 0.3 * p;
        } else if (this.attack?.tipo === "circulo") {
          poseY = 0.4 * p;
          poseX = -0.35 * p;
          headX = -0.5 * p;
        } else if ((this.attack?.angulo ?? 0) >= 360) {
          poseSpin = -0.6 * p;
          poseY = -0.15 * p;
        } else {
          poseX = -0.25 * p;
          headX = -0.6 * p;
        }
        break;
      case "atacar":
        if (this.attack?.tipo === "circulo") {
          poseY = 0.4 * Math.max(0, 1 - this.t * 6);
        } else if (this.attack?.tipo === "setor" && (this.attack.angulo ?? 0) >= 360) {
          poseSpin = -0.6 + (Math.PI * 2 + 0.6) * Math.min(1, this.t / 0.25);
        } else if (this.attack?.tipo === "setor") {
          poseX = 0.25;
          headX = 0.5;
        }
        break;
      case "recuperar":
        poseY = Math.sin(this.t * 8) * 0.04;
        headX = 0.25;
        break;
      case "rugir":
        headX = -0.8 * Math.min(1, this.t * 4);
        poseX = -0.2 * Math.min(1, this.t * 4);
        break;
      case "atordoado":
        poseZ = Math.min(1, this.t * 4) * 1.25 * (this.t > STUN_TIME - 0.3 ? (STUN_TIME - this.t) / 0.3 : 1);
        m.legs.forEach((l, i) => (l.rotation.x = Math.sin(this.t * 10 + i) * 0.5));
        break;
      case "morto":
        poseZ = Math.min(1, this.t * 1.5) * 1.5;
        m.eyes.color.set("#333333");
        break;
    }
    m.pose.position.y = poseY + (poseZ ? Math.sin(poseZ) * this.def.visual.pernas * 0.3 : 0);
    m.pose.rotation.set(poseX, poseSpin, poseZ);
    m.head.rotation.x = headX;

    if (this.severedTail) {
      const s = this.severedTail;
      if (s.obj.position.y > 0.3) {
        s.vy -= 18 * dt;
        s.obj.position.y = Math.max(0.3, s.obj.position.y + s.vy * dt);
        s.obj.rotation.y += s.spin * dt;
        s.obj.rotation.z += s.spin * 0.5 * dt;
      }
    }
  }
}

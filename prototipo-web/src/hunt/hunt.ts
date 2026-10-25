import * as THREE from "three";
import { ELEMENT_INFO, GEAR, MATERIALS, PLAYER, beastById, type Element, type Gear, type PartId } from "../game/data";
import { mergeCounts, randInt, rollLoot } from "../game/formulas";
import type { HuntResult, Profile } from "../game/profile";
import { Beast } from "./beast";
import type { HuntContext } from "./context";
import { FloatingText, Particles } from "./fx";
import { Input } from "./input";
import { ARENA_RADIUS, BIOMES, buildArena, buildGatherNode } from "./models";
import { Player } from "./player";

function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

interface GatherNode {
  kind: "minerio" | "fibra";
  obj: THREE.Group;
  taken: boolean;
}

const PART_ORDER: PartId[] = ["cabeca", "costas", "cauda"];

export class Hunt implements HuntContext {
  scene = new THREE.Scene();
  particles: Particles;
  text: FloatingText;
  rng: () => number;
  player: Player;
  beast: Beast;
  weapon: Gear;
  weaponLevel: number;
  armor: Gear;
  armorLevel: number;

  private renderer: THREE.WebGLRenderer;
  private camera: THREE.PerspectiveCamera;
  private sun: THREE.DirectionalLight;
  private input: Input;
  private root: HTMLElement;
  private hud: Record<string, HTMLElement> = {};
  private nodes: GatherNode[] = [];
  private gathered: Record<string, number> = {};
  private partDrops: Record<string, number> = {};
  private partsBroken = 0;
  private faints = 0;
  private elapsed = 0;
  private raf = 0;
  private last = 0;
  private paused = false;
  private ended = false;
  private hitstopLeft = 0;
  private slowLeft = 0;
  private slowScale = 1;
  private shakeAmt = 0;
  private camPos = new THREE.Vector3();
  private camLook = new THREE.Vector3();
  private ghostHp = 1;
  private pendingTimers: number[] = [];
  private onResize = () => this.resize();
  private onVisibility = () => document.hidden && this.setPaused(true);

  constructor(
    container: HTMLElement,
    profile: Profile,
    feraId: string,
    private onEnd: (r: HuntResult) => void,
  ) {
    const def = beastById(feraId);
    this.weapon = GEAR[profile.equipado.arma];
    this.weaponLevel = profile.equipamentos[this.weapon.id] ?? 0;
    this.armor = GEAR[profile.equipado.armadura];
    this.armorLevel = profile.equipamentos[this.armor.id] ?? 0;
    this.rng = mulberry32(Date.now() & 0xffffffff);

    this.root = document.createElement("div");
    this.root.className = "hunt";
    container.appendChild(this.root);

    const dpr = Math.min(window.devicePixelRatio || 1, 1.75);
    this.renderer = new THREE.WebGLRenderer({ antialias: dpr < 1.5, powerPreference: "high-performance" });
    this.renderer.setPixelRatio(dpr);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFShadowMap;
    this.root.appendChild(this.renderer.domElement);

    this.camera = new THREE.PerspectiveCamera(50, 1, 0.5, 260);

    const hemi = new THREE.HemisphereLight("#ffffff", "#6a5a4a", 1.6);
    this.sun = new THREE.DirectionalLight("#fff4dd", 2.2);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(1024, 1024);
    const sc = this.sun.shadow.camera;
    sc.left = sc.bottom = -22;
    sc.right = sc.top = 22;
    sc.near = 1;
    sc.far = 80;
    this.scene.add(hemi, this.sun, this.sun.target);

    const layer = document.createElement("div");
    layer.className = "fx-layer";
    this.root.appendChild(layer);
    this.particles = new Particles(this.scene);
    this.text = new FloatingText(layer, this.camera);

    buildArena(this.scene, BIOMES[def.id] ?? BIOMES.tatu_musgo, mulberry32(def.id.length * 977));
    this.spawnNodes();

    // Jogador e fera se referenciam pelo contexto (this).
    this.beast = undefined as unknown as Beast;
    this.player = new Player(this);
    this.player.pos.set(0, 0, 14);
    this.player.facing = Math.PI;
    this.beast = new Beast(def, this);

    this.buildHud();
    this.input = new Input(this.root);
    this.input.setPotions(this.player.potions);

    this.resize();
    window.addEventListener("resize", this.onResize);
    document.addEventListener("visibilitychange", this.onVisibility);

    this.camPos.copy(this.player.pos).add(new THREE.Vector3(0, 18, 14));
    if (location.search.includes("debug")) (window as unknown as { __hunt: Hunt }).__hunt = this;
    this.banner(`Cace: ${def.nome}`, "banner-intro");
    this.last = performance.now();
    this.raf = requestAnimationFrame(this.loop);
  }

  // ------------------------------------------------------------ HuntContext

  shake(amount: number): void {
    this.shakeAmt = Math.max(this.shakeAmt, amount);
  }
  hitstop(seconds: number): void {
    this.hitstopLeft = Math.max(this.hitstopLeft, seconds);
  }
  slowmo(seconds: number, scale: number): void {
    this.slowLeft = seconds;
    this.slowScale = scale;
  }
  banner(text: string, cls = ""): void {
    const b = this.hud.banner;
    b.textContent = text;
    b.className = `banner show ${cls}`;
    clearTimeout(Number(b.dataset.timer));
    b.dataset.timer = String(window.setTimeout(() => b.classList.remove("show"), 1600));
  }

  hitPlayer(raw: number, element: Element, from: THREE.Vector3): boolean {
    const r = this.player.takeHit(raw, element, from);
    if (r === "esquivou" && this.player.state === "esquiva") {
      this.slowmo(0.35, 0.3);
      this.text.spawn(this.player.pos.clone().setY(2.6), "ESQUIVA PERFEITA", "ft-perfect");
      if (this.player.perkNames.includes("Esquiva Afiada")) this.player.sharp = true;
    }
    return r !== "nada";
  }

  onPlayerDown(): void {
    this.faints++;
    if (this.faints >= PLAYER.desmaiosMaximos) {
      this.banner("A caçada falhou...", "banner-fury");
      this.later(2200, () => this.finish(false));
      return;
    }
    this.banner(`Você desmaiou! (${this.faints}/${PLAYER.desmaiosMaximos})`, "banner-fury");
    this.later(2500, () => {
      if (this.ended) return;
      const away = new THREE.Vector3().subVectors(this.player.pos, this.beast.pos).setY(0);
      if (away.lengthSq() < 0.01) away.set(0, 0, 1);
      away.normalize().multiplyScalar(ARENA_RADIUS - 8);
      this.player.respawn(away);
    });
  }

  onBeastDead(): void {
    this.later(800, () => this.finish(true));
  }

  onPartBroken(drop: string): void {
    this.partsBroken++;
    this.partDrops[drop] = (this.partDrops[drop] ?? 0) + 1;
  }

  // ------------------------------------------------------------ loop

  private loop = (now: number) => {
    this.raf = requestAnimationFrame(this.loop);
    let dt = Math.min(0.05, (now - this.last) / 1000);
    this.last = now;
    if (this.paused) return;

    this.elapsed += dt;
    if (this.slowLeft > 0) {
      this.slowLeft -= dt;
      dt *= this.slowScale;
    }
    this.input.update();
    if (this.hitstopLeft > 0) {
      this.hitstopLeft -= dt;
    } else if (!this.ended) {
      this.player.update(dt, this.input);
      this.beast.update(dt);
      this.updateNodes();
    }
    this.particles.update(dt);
    this.updateCamera(dt);
    this.renderer.render(this.scene, this.camera);
    const { clientWidth: w, clientHeight: h } = this.root;
    this.text.update(dt, w, h);
    this.updateHud(dt);
  };

  private updateCamera(dt: number): void {
    const p = this.player.pos;
    const b = this.beast.pos;
    const aspect = this.camera.aspect;
    const dist = aspect < 1 ? 1.45 : 1;
    // Puxa o enquadramento um pouco em direção à fera para manter os dois na tela.
    const focus = p.clone();
    const toB = b.clone().sub(p);
    if (toB.length() < 24) focus.addScaledVector(toB, 0.35);
    focus.z -= 1.5;
    const want = focus.clone().add(new THREE.Vector3(0, 18 * dist, 14 * dist));
    const k = 1 - Math.pow(0.002, dt);
    this.camPos.lerp(want, k);
    this.camLook.lerp(focus.setY(1), k);
    this.camera.position.copy(this.camPos);
    if (this.shakeAmt > 0) {
      this.camera.position.x += (Math.random() - 0.5) * this.shakeAmt;
      this.camera.position.y += (Math.random() - 0.5) * this.shakeAmt;
      this.shakeAmt = Math.max(0, this.shakeAmt - dt * 2.5);
    }
    this.camera.lookAt(this.camLook);
    this.sun.position.copy(p).add(new THREE.Vector3(12, 25, 8));
    this.sun.target.position.copy(p);
  }

  private resize(): void {
    const w = this.root.clientWidth || window.innerWidth;
    const h = this.root.clientHeight || window.innerHeight;
    this.renderer.setSize(w, h);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  // ------------------------------------------------------------ coleta

  private spawnNodes(): void {
    const rng = mulberry32(4242);
    for (let i = 0; i < 10; i++) {
      const kind = i % 2 === 0 ? "minerio" : "fibra";
      const a = (i / 10) * Math.PI * 2 + rng() * 0.4;
      const r = 12 + rng() * (ARENA_RADIUS - 16);
      const obj = buildGatherNode(kind);
      obj.position.set(Math.cos(a) * r, 0, Math.sin(a) * r);
      this.scene.add(obj);
      this.nodes.push({ kind, obj, taken: false });
    }
  }

  private updateNodes(): void {
    const t = performance.now() / 1000;
    for (const n of this.nodes) {
      if (n.taken) {
        n.obj.scale.multiplyScalar(0.85);
        continue;
      }
      n.obj.rotation.y = Math.sin(t + n.obj.position.x) * 0.2;
      if (this.player.state !== "caido" && n.obj.position.distanceTo(this.player.pos) < 1.5) {
        n.taken = true;
        const qtd = 1 + Math.floor(this.rng() * 2);
        this.gathered[n.kind] = (this.gathered[n.kind] ?? 0) + qtd;
        this.text.spawn(n.obj.position.clone().setY(1.8), `+${qtd} ${MATERIALS[n.kind].nome}`, "ft-gather");
        this.particles.burst(n.obj.position.clone().setY(0.8), n.kind === "minerio" ? "#7fd6ff" : "#7ad65a", 10, 3, 4);
      }
    }
  }

  // ------------------------------------------------------------ HUD

  private buildHud(): void {
    const def = this.beast.def;
    const el = document.createElement("div");
    el.className = "hud";
    const wInfo = ELEMENT_INFO[this.weapon.elemento];
    el.innerHTML = `
      <div class="hud-player">
        <div class="bar hp"><i class="ghost"></i><i class="fill"></i></div>
        <div class="bar st"><i class="fill"></i></div>
        <div class="faints"></div>
        <div class="weapon-tag" style="--c:${wInfo.cor}">${wInfo.icone} ${this.weapon.nome} +${this.weaponLevel}</div>
      </div>
      <div class="hud-beast">
        <div class="beast-name"><span style="color:${ELEMENT_INFO[def.elemento].cor}">${ELEMENT_INFO[def.elemento].icone}</span> ${def.nome}<span class="fury-tag">FÚRIA</span></div>
        <div class="bar bhp"><i class="ghost"></i><i class="fill"></i></div>
        <div class="parts">${PART_ORDER.filter((p) => this.beast.parts[p])
          .map((p) => `<span class="part" data-part="${p}">${this.beast.parts[p].def.nome}</span>`)
          .join("")}</div>
        <div class="beast-action"></div>
      </div>
      <div class="hud-top-right">
        <span class="timer">0:00</span>
        <button class="pause-btn" aria-label="Pausar">❚❚</button>
      </div>
      <div class="banner"></div>
      <div class="offscreen">➤</div>
      <div class="pause-menu hidden">
        <div class="panel">
          <h2>Pausado</h2>
          <p class="hint">Mover: joystick / WASD · Atacar: toque ou J (segure para carregar) · Esquiva: botão ou Espaço · Poção: botão ou Q</p>
          <button class="btn primary" data-act="resume">Continuar</button>
          <button class="btn danger" data-act="quit">Abandonar caçada</button>
        </div>
      </div>`;
    this.root.appendChild(el);
    const q = (s: string) => el.querySelector(s) as HTMLElement;
    this.hud = {
      hp: q(".hp .fill"),
      hpGhost: q(".hp .ghost"),
      st: q(".st .fill"),
      faints: q(".faints"),
      bhp: q(".bhp .fill"),
      bhpGhost: q(".bhp .ghost"),
      fury: q(".fury-tag"),
      parts: q(".parts"),
      action: q(".beast-action"),
      timer: q(".timer"),
      banner: q(".banner"),
      offscreen: q(".offscreen"),
      pause: q(".pause-menu"),
    };
    q(".pause-btn").addEventListener("click", () => this.setPaused(true));
    q('[data-act="resume"]').addEventListener("click", () => this.setPaused(false));
    q('[data-act="quit"]').addEventListener("click", () => this.finish(false));
  }

  private setPaused(p: boolean): void {
    if (this.ended) return;
    this.paused = p;
    this.hud.pause.classList.toggle("hidden", !p);
    if (!p) this.last = performance.now();
  }

  private lastHudKey = "";

  private updateHud(dt: number): void {
    const pl = this.player;
    const b = this.beast;
    const hpFrac = pl.hp / pl.maxHp;
    this.hud.hp.style.width = `${hpFrac * 100}%`;
    this.hud.hpGhost.style.width = `${Math.max(hpFrac, parseFloat(this.hud.hpGhost.style.width || "100") / 100 - dt * 0.4) * 100}%`;
    this.hud.st.style.width = `${pl.stamina}%`;
    const bf = b.hp / b.maxHp;
    this.ghostHp = Math.max(bf, this.ghostHp - dt * 0.25);
    this.hud.bhp.style.width = `${bf * 100}%`;
    this.hud.bhpGhost.style.width = `${this.ghostHp * 100}%`;

    const s = Math.floor(this.elapsed);
    const key = `${s}|${this.faints}|${pl.potions}|${b.fury}|${b.busy}|${PART_ORDER.map((p) => (b.parts[p] ? `${+b.parts[p].ferida}${+b.parts[p].quebrada}` : "")).join()}`;
    if (key !== this.lastHudKey) {
      this.lastHudKey = key;
      this.hud.timer.textContent = `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
      this.hud.faints.innerHTML = Array.from({ length: PLAYER.desmaiosMaximos }, (_, i) => `<span class="${i < this.faints ? "lost" : ""}">♥</span>`).join("");
      this.hud.fury.classList.toggle("on", b.fury);
      this.hud.action.textContent = b.busy ? `⚠ ${b.busy}` : "";
      this.input.setPotions(pl.potions);
      this.hud.parts.querySelectorAll<HTMLElement>(".part").forEach((el) => {
        const st = b.parts[el.dataset.part as PartId];
        el.classList.toggle("wounded", st.ferida && !st.quebrada);
        el.classList.toggle("broken", st.quebrada);
      });
    }

    // Seta indicando a fera fora da tela.
    const v = b.pos.clone().setY(1.5).project(this.camera);
    const off = Math.abs(v.x) > 1 || Math.abs(v.y) > 1 || v.z > 1;
    this.hud.offscreen.style.display = off && b.alive ? "block" : "none";
    if (off) {
      const sign = v.z > 1 ? -1 : 1;
      const ang = Math.atan2(-v.y * sign, v.x * sign);
      const w = this.root.clientWidth / 2;
      const h = this.root.clientHeight / 2;
      const r = Math.min(w, h) - 40;
      this.hud.offscreen.style.transform = `translate(${w + Math.cos(ang) * r}px, ${h + Math.sin(ang) * r}px) translate(-50%, -50%) rotate(${ang}rad)`;
    }
  }

  // ------------------------------------------------------------ fim

  private later(ms: number, fn: () => void): void {
    this.pendingTimers.push(window.setTimeout(fn, ms));
  }

  private finish(victory: boolean): void {
    if (this.ended) return;
    this.ended = true;
    const def = this.beast.def;
    let loot: Record<string, number> = { ...this.gathered };
    let moedas = 0;
    let xp = 10;
    if (victory) {
      loot = mergeCounts(mergeCounts(loot, rollLoot(def.loot, this.rng)), this.partDrops);
      moedas = randInt(this.rng, def.moedas[0], def.moedas[1]);
      xp = def.xp + this.partsBroken * 10;
    }
    const result: HuntResult = {
      feraId: def.id,
      vitoria: victory,
      tempo: Math.round(this.elapsed),
      partesQuebradas: this.partsBroken,
      loot,
      moedas,
      xp,
    };
    this.dispose();
    this.onEnd(result);
  }

  dispose(): void {
    cancelAnimationFrame(this.raf);
    this.pendingTimers.forEach(clearTimeout);
    window.removeEventListener("resize", this.onResize);
    document.removeEventListener("visibilitychange", this.onVisibility);
    this.input.dispose();
    this.text.clear();
    this.scene.traverse((o) => {
      if (o instanceof THREE.Mesh) {
        o.geometry.dispose();
        const m = o.material as THREE.Material | THREE.Material[];
        (Array.isArray(m) ? m : [m]).forEach((x) => x.dispose());
      }
    });
    this.renderer.dispose();
    this.root.remove();
  }
}

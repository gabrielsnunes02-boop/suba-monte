// Entrada unificada: joystick virtual + botões de toque, teclado e mouse.

export class Input {
  /** Vetor de movimento na tela (x direita, y para cima), magnitude 0–1. */
  move = { x: 0, y: 0 };
  attackHeld = false;
  private attackPressedFlag = false;
  private attackReleasedFlag = false;
  private dodgeFlag = false;
  private potionFlag = false;

  private keys = new Set<string>();
  private joyId: number | null = null;
  private joyOrigin = { x: 0, y: 0 };
  private joyVec = { x: 0, y: 0 };
  private cleanup: (() => void)[] = [];

  constructor(private root: HTMLElement) {
    this.buildTouchUi();
    const kd = (e: KeyboardEvent) => this.onKey(e, true);
    const ku = (e: KeyboardEvent) => this.onKey(e, false);
    window.addEventListener("keydown", kd);
    window.addEventListener("keyup", ku);
    this.cleanup.push(() => window.removeEventListener("keydown", kd), () => window.removeEventListener("keyup", ku));
  }

  consumeAttackPressed(): boolean {
    const v = this.attackPressedFlag;
    this.attackPressedFlag = false;
    return v;
  }
  consumeAttackReleased(): boolean {
    const v = this.attackReleasedFlag;
    this.attackReleasedFlag = false;
    return v;
  }
  consumeDodge(): boolean {
    const v = this.dodgeFlag;
    this.dodgeFlag = false;
    return v;
  }
  consumePotion(): boolean {
    const v = this.potionFlag;
    this.potionFlag = false;
    return v;
  }

  update(): void {
    let kx = 0;
    let ky = 0;
    if (this.keys.has("KeyA") || this.keys.has("ArrowLeft")) kx -= 1;
    if (this.keys.has("KeyD") || this.keys.has("ArrowRight")) kx += 1;
    if (this.keys.has("KeyW") || this.keys.has("ArrowUp")) ky += 1;
    if (this.keys.has("KeyS") || this.keys.has("ArrowDown")) ky -= 1;
    if (kx || ky) {
      const l = Math.hypot(kx, ky);
      this.move.x = kx / l;
      this.move.y = ky / l;
    } else {
      this.move.x = this.joyVec.x;
      this.move.y = this.joyVec.y;
    }
  }

  dispose(): void {
    this.cleanup.forEach((f) => f());
  }

  private pressAttack(down: boolean): void {
    if (down && !this.attackHeld) this.attackPressedFlag = true;
    if (!down && this.attackHeld) this.attackReleasedFlag = true;
    this.attackHeld = down;
  }

  private onKey(e: KeyboardEvent, down: boolean): void {
    if (e.repeat) return;
    if (down) this.keys.add(e.code);
    else this.keys.delete(e.code);
    if (e.code === "KeyJ" || e.code === "Enter") this.pressAttack(down);
    if (down && (e.code === "Space" || e.code === "KeyK" || e.code === "ShiftLeft")) {
      this.dodgeFlag = true;
      e.preventDefault();
    }
    if (down && (e.code === "KeyQ" || e.code === "KeyE")) this.potionFlag = true;
  }

  private buildTouchUi(): void {
    const zone = document.createElement("div");
    zone.className = "joy-zone";
    const base = document.createElement("div");
    base.className = "joy-base";
    const knob = document.createElement("div");
    knob.className = "joy-knob";
    base.appendChild(knob);
    zone.appendChild(base);

    const R = 55;
    const setKnob = () => {
      knob.style.transform = `translate(${this.joyVec.x * R}px, ${-this.joyVec.y * R}px)`;
    };
    zone.addEventListener("pointerdown", (e) => {
      if (this.joyId !== null) return;
      this.joyId = e.pointerId;
      zone.setPointerCapture(e.pointerId);
      const rect = zone.getBoundingClientRect();
      this.joyOrigin = { x: e.clientX, y: e.clientY };
      base.style.left = `${e.clientX - rect.left}px`;
      base.style.top = `${e.clientY - rect.top}px`;
      base.classList.add("ativo");
    });
    zone.addEventListener("pointermove", (e) => {
      if (e.pointerId !== this.joyId) return;
      const dx = e.clientX - this.joyOrigin.x;
      const dy = e.clientY - this.joyOrigin.y;
      const l = Math.hypot(dx, dy);
      const m = Math.min(l, R) / R;
      this.joyVec = l > 4 ? { x: (dx / l) * m, y: (-dy / l) * m } : { x: 0, y: 0 };
      setKnob();
    });
    const end = (e: PointerEvent) => {
      if (e.pointerId !== this.joyId) return;
      this.joyId = null;
      this.joyVec = { x: 0, y: 0 };
      setKnob();
      base.classList.remove("ativo");
    };
    zone.addEventListener("pointerup", end);
    zone.addEventListener("pointercancel", end);

    const buttons = document.createElement("div");
    buttons.className = "btn-zone";
    const mk = (cls: string, label: string) => {
      const b = document.createElement("button");
      b.className = `tbtn ${cls}`;
      b.innerHTML = label;
      buttons.appendChild(b);
      return b;
    };
    const atk = mk("tbtn-atk", "⚔<small>toque / segure</small>");
    const dodge = mk("tbtn-dodge", "⤴<small>esquiva</small>");
    const pot = mk("tbtn-pot", "✚<small>poção</small>");

    atk.addEventListener("pointerdown", (e) => {
      atk.setPointerCapture(e.pointerId);
      this.pressAttack(true);
    });
    const atkUp = () => this.pressAttack(false);
    atk.addEventListener("pointerup", atkUp);
    atk.addEventListener("pointercancel", atkUp);
    dodge.addEventListener("pointerdown", () => (this.dodgeFlag = true));
    pot.addEventListener("pointerdown", () => (this.potionFlag = true));

    // Mouse no desktop: botão esquerdo fora dos controles = atacar.
    const canvasDown = (e: PointerEvent) => {
      if (e.pointerType === "mouse" && e.button === 0 && (e.target as HTMLElement).tagName === "CANVAS") this.pressAttack(true);
    };
    const canvasUp = (e: PointerEvent) => {
      if (e.pointerType === "mouse" && e.button === 0) this.pressAttack(false);
    };
    this.root.addEventListener("pointerdown", canvasDown);
    window.addEventListener("pointerup", canvasUp);
    this.cleanup.push(() => window.removeEventListener("pointerup", canvasUp));

    this.root.append(zone, buttons);
  }

  /** Atualiza o rótulo do botão de poção. */
  setPotions(n: number): void {
    const b = this.root.querySelector(".tbtn-pot");
    if (b) b.innerHTML = `✚<small>poção ×${n}</small>`;
  }
}

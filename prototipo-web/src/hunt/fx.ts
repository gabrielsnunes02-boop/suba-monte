import * as THREE from "three";

interface Particle {
  mesh: THREE.Mesh;
  vel: THREE.Vector3;
  life: number;
  max: number;
}

/** Partículas simples com pool (sem alocar durante a luta). */
export class Particles {
  private pool: Particle[] = [];
  private active: Particle[] = [];
  private geo = new THREE.TetrahedronGeometry(0.12);

  constructor(private scene: THREE.Scene) {}

  burst(pos: THREE.Vector3, color: THREE.ColorRepresentation, count: number, speed = 6, up = 4): void {
    for (let i = 0; i < count; i++) {
      const p = this.pool.pop() ?? this.create();
      (p.mesh.material as THREE.MeshBasicMaterial).color.set(color);
      p.mesh.position.copy(pos);
      p.mesh.visible = true;
      const a = Math.random() * Math.PI * 2;
      const s = speed * (0.4 + Math.random() * 0.6);
      p.vel.set(Math.cos(a) * s, up * (0.5 + Math.random()), Math.sin(a) * s);
      p.max = p.life = 0.35 + Math.random() * 0.35;
      p.mesh.scale.setScalar(0.7 + Math.random() * 0.9);
      this.active.push(p);
    }
  }

  update(dt: number): void {
    for (let i = this.active.length - 1; i >= 0; i--) {
      const p = this.active[i];
      p.life -= dt;
      if (p.life <= 0) {
        p.mesh.visible = false;
        this.active.splice(i, 1);
        this.pool.push(p);
        continue;
      }
      p.vel.y -= 14 * dt;
      p.mesh.position.addScaledVector(p.vel, dt);
      p.mesh.rotation.x += dt * 8;
      p.mesh.rotation.y += dt * 6;
      p.mesh.scale.multiplyScalar(0.97);
    }
  }

  private create(): Particle {
    const mesh = new THREE.Mesh(this.geo, new THREE.MeshBasicMaterial({ color: 0xffffff }));
    mesh.visible = false;
    this.scene.add(mesh);
    return { mesh, vel: new THREE.Vector3(), life: 0, max: 1 };
  }
}

/** Números de dano e textos flutuantes em DOM, projetados do mundo 3D. */
export class FloatingText {
  private items: { el: HTMLElement; pos: THREE.Vector3; life: number }[] = [];
  private v = new THREE.Vector3();

  constructor(private layer: HTMLElement, private camera: THREE.Camera) {}

  spawn(pos: THREE.Vector3, text: string, cls = ""): void {
    const el = document.createElement("div");
    el.className = `ftext ${cls}`;
    el.textContent = text;
    this.layer.appendChild(el);
    const jitter = new THREE.Vector3((Math.random() - 0.5) * 0.8, 0, (Math.random() - 0.5) * 0.8);
    this.items.push({ el, pos: pos.clone().add(jitter), life: 0.9 });
  }

  update(dt: number, w: number, h: number): void {
    for (let i = this.items.length - 1; i >= 0; i--) {
      const it = this.items[i];
      it.life -= dt;
      it.pos.y += dt * 1.6;
      if (it.life <= 0) {
        it.el.remove();
        this.items.splice(i, 1);
        continue;
      }
      this.v.copy(it.pos).project(this.camera);
      it.el.style.transform = `translate(${(this.v.x * 0.5 + 0.5) * w}px, ${(-this.v.y * 0.5 + 0.5) * h}px) translate(-50%, -50%)`;
      it.el.style.opacity = String(Math.min(1, it.life * 2.5));
    }
  }

  clear(): void {
    this.items.forEach((i) => i.el.remove());
    this.items = [];
  }
}

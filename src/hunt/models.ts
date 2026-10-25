// Modelos 3D procedurais em low-poly (sem assets externos: o jogo inteiro pesa poucos KB de arte).
import * as THREE from "three";
import type { BeastDef, PartId } from "../game/data";

let gradient: THREE.DataTexture | null = null;

function toonGradient(): THREE.DataTexture {
  if (!gradient) {
    const data = new Uint8Array([90, 170, 255]);
    gradient = new THREE.DataTexture(data, 3, 1, THREE.RedFormat);
    gradient.minFilter = THREE.NearestFilter;
    gradient.magFilter = THREE.NearestFilter;
    gradient.needsUpdate = true;
  }
  return gradient;
}

export function toon(color: THREE.ColorRepresentation, emissive?: THREE.ColorRepresentation, intensity = 0): THREE.MeshToonMaterial {
  return new THREE.MeshToonMaterial({
    color,
    gradientMap: toonGradient(),
    emissive: emissive ?? 0x000000,
    emissiveIntensity: intensity,
  });
}

/** Normais por face: visual facetado de low-poly. */
export function faceted<T extends THREE.BufferGeometry>(g: T): THREE.BufferGeometry {
  const n = g.index ? g.toNonIndexed() : g;
  n.computeVertexNormals();
  return n;
}

function mesh(geo: THREE.BufferGeometry, mat: THREE.Material, shadow = true): THREE.Mesh {
  const m = new THREE.Mesh(geo, mat);
  m.castShadow = shadow;
  m.receiveShadow = false;
  return m;
}

// ---------------------------------------------------------------- caçador

export interface PlayerModel {
  root: THREE.Group;
  body: THREE.Group;
  armPivot: THREE.Group;
  blade: THREE.Mesh;
  bladeMat: THREE.MeshToonMaterial;
  legs: THREE.Group[];
  armorMat: THREE.MeshToonMaterial;
}

export function buildPlayer(armorColor: string, bladeColor: string): PlayerModel {
  const root = new THREE.Group();
  const body = new THREE.Group();
  root.add(body);

  const armorMat = toon(armorColor);
  const skin = toon("#f1c27d");
  const dark = toon("#2b2b38");

  const torso = mesh(faceted(new THREE.CapsuleGeometry(0.42, 0.7, 3, 7)), armorMat);
  torso.position.y = 1.15;
  body.add(torso);

  const head = mesh(faceted(new THREE.IcosahedronGeometry(0.33, 1)), skin);
  head.position.y = 1.95;
  body.add(head);

  const hood = mesh(faceted(new THREE.ConeGeometry(0.4, 0.5, 6)), armorMat);
  hood.position.set(0, 2.2, -0.05);
  body.add(hood);

  const scarf = mesh(faceted(new THREE.TorusGeometry(0.33, 0.1, 4, 8)), dark);
  scarf.rotation.x = Math.PI / 2;
  scarf.position.y = 1.68;
  body.add(scarf);

  const legs: THREE.Group[] = [];
  for (const side of [-1, 1]) {
    const pivot = new THREE.Group();
    pivot.position.set(0.2 * side, 0.65, 0);
    const leg = mesh(faceted(new THREE.CylinderGeometry(0.13, 0.11, 0.65, 5)), dark);
    leg.position.y = -0.32;
    pivot.add(leg);
    body.add(pivot);
    legs.push(pivot);
  }

  const armPivot = new THREE.Group();
  armPivot.position.set(0.5, 1.45, 0.05);
  const arm = mesh(faceted(new THREE.CylinderGeometry(0.1, 0.09, 0.55, 5)), armorMat);
  arm.rotation.x = Math.PI / 2;
  arm.position.z = 0.25;
  armPivot.add(arm);

  const bladeMat = toon(bladeColor, bladeColor, 0.25);
  const blade = mesh(faceted(new THREE.BoxGeometry(0.1, 0.18, 1.7)), bladeMat);
  blade.position.set(0, 0, 1.35);
  armPivot.add(blade);
  const guard = mesh(new THREE.BoxGeometry(0.4, 0.08, 0.1), dark);
  guard.position.z = 0.5;
  armPivot.add(guard);
  body.add(armPivot);

  root.traverse((o) => (o.castShadow = o instanceof THREE.Mesh));
  return { root, body, armPivot, blade, bladeMat, legs, armorMat };
}

// ---------------------------------------------------------------- feras

export interface BeastModel {
  root: THREE.Group;
  /** Grupo que balança/inclina (atordoada, morta) sem mexer na posição. */
  pose: THREE.Group;
  head: THREE.Group;
  tailRoot: THREE.Group;
  tailSegments: THREE.Group[];
  legs: THREE.Group[];
  spikes: THREE.Mesh[];
  eyes: THREE.MeshBasicMaterial;
  bodyMats: THREE.MeshToonMaterial[];
  partMats: Record<PartId, THREE.MeshToonMaterial>;
  anchors: Record<PartId, THREE.Object3D>;
}

export function buildBeast(def: BeastDef): BeastModel {
  const v = def.visual;
  const root = new THREE.Group();
  const pose = new THREE.Group();
  root.add(pose);

  const bodyMat = toon(v.corCorpo);
  const detailMat = toon(v.corDetalhe);
  const partMats: Record<PartId, THREE.MeshToonMaterial> = {
    cabeca: toon(v.corCorpo),
    costas: toon(v.corDetalhe),
    cauda: toon(v.corCorpo),
  };
  const bodyY = v.pernas + v.altura / 2;

  const body = mesh(faceted(new THREE.SphereGeometry(1, 9, 6)), bodyMat);
  body.scale.set(v.largura / 2, v.altura / 2, v.comprimento / 2);
  body.position.y = bodyY;
  pose.add(body);

  const belly = mesh(faceted(new THREE.SphereGeometry(1, 7, 5)), detailMat);
  belly.scale.set(v.largura * 0.4, v.altura * 0.3, v.comprimento * 0.4);
  belly.position.y = bodyY - v.altura * 0.25;
  pose.add(belly);

  // Cabeça
  const head = new THREE.Group();
  head.position.set(0, bodyY + v.altura * 0.15, v.comprimento / 2);
  const skull = mesh(faceted(new THREE.SphereGeometry(1, 7, 5)), partMats.cabeca);
  skull.scale.set(v.largura * 0.36, v.altura * 0.36, Math.max(0.6, v.comprimento * 0.16));
  skull.position.z = 0.25;
  head.add(skull);
  const snout = mesh(faceted(new THREE.BoxGeometry(v.largura * 0.42, v.altura * 0.26, v.comprimento * 0.2)), partMats.cabeca);
  snout.position.set(0, -v.altura * 0.08, 0.35 + v.comprimento * 0.14);
  head.add(snout);
  const eyes = new THREE.MeshBasicMaterial({ color: v.corOlhos });
  for (const s of [-1, 1]) {
    const eye = new THREE.Mesh(new THREE.OctahedronGeometry(0.1), eyes);
    eye.position.set(s * v.largura * 0.24, v.altura * 0.12, 0.45 + v.comprimento * 0.06);
    head.add(eye);
  }
  if (def.visual.espinhos !== "placas") {
    for (const s of [-1, 1]) {
      const ear = mesh(faceted(new THREE.ConeGeometry(0.16, 0.5, 4)), detailMat);
      ear.position.set(s * v.largura * 0.22, v.altura * 0.4, 0.1);
      ear.rotation.z = -s * 0.3;
      head.add(ear);
    }
  }
  pose.add(head);

  // Costas (espinhos/placas)
  const spikes: THREE.Mesh[] = [];
  const back = new THREE.Group();
  back.position.y = bodyY + v.altura * 0.42;
  const nSpikes = Math.round(v.comprimento * 1.6);
  for (let i = 0; i < nSpikes; i++) {
    const t = nSpikes === 1 ? 0.5 : i / (nSpikes - 1);
    const z = (t - 0.5) * v.comprimento * 0.75;
    let geo: THREE.BufferGeometry;
    let mat: THREE.Material = partMats.costas;
    if (v.espinhos === "chamas") {
      geo = new THREE.ConeGeometry(0.18, 0.7 + Math.sin(t * Math.PI) * 0.5, 4);
      mat = toon("#ffb347", "#ff5a1f", 0.6);
    } else if (v.espinhos === "placas") {
      geo = new THREE.BoxGeometry(v.largura * 0.9, 0.2, v.comprimento / nSpikes);
    } else {
      geo = new THREE.ConeGeometry(0.14, 0.45, 3);
    }
    const s = mesh(faceted(geo), mat);
    const h = Math.cos((t - 0.5) * Math.PI) * v.altura * 0.12;
    s.position.set(0, h + (v.espinhos === "placas" ? -0.05 : 0.25), z);
    if (v.espinhos === "placas") s.rotation.x = (t - 0.5) * 0.9;
    back.add(s);
    spikes.push(s);
  }
  pose.add(back);

  // Cauda (cadeia de segmentos)
  const tailRoot = new THREE.Group();
  tailRoot.position.set(0, bodyY + v.altura * 0.1, -v.comprimento / 2 + 0.2);
  const tailSegments: THREE.Group[] = [];
  let parent: THREE.Object3D = tailRoot;
  const segLen = v.comprimento * 0.17;
  for (let i = 0; i < v.caudaSegmentos; i++) {
    const seg = new THREE.Group();
    seg.position.z = i === 0 ? 0 : -segLen;
    const r = Math.max(0.12, (v.largura * 0.28) * (1 - i / (v.caudaSegmentos + 1)));
    const m = mesh(faceted(new THREE.SphereGeometry(1, 6, 4)), partMats.cauda);
    m.scale.set(r, r, segLen * 0.65);
    m.position.z = -segLen / 2;
    seg.add(m);
    if (i === v.caudaSegmentos - 1) {
      const tip =
        v.espinhos === "placas"
          ? mesh(faceted(new THREE.DodecahedronGeometry(0.45)), detailMat)
          : mesh(faceted(new THREE.ConeGeometry(0.2, 0.6, 4)), v.espinhos === "chamas" ? toon("#ffb347", "#ff5a1f", 0.8) : detailMat);
      tip.position.z = -segLen;
      if (!(tip.geometry instanceof THREE.DodecahedronGeometry)) tip.rotation.x = -Math.PI / 2;
      seg.add(tip);
    }
    parent.add(seg);
    tailSegments.push(seg);
    parent = seg;
  }
  pose.add(tailRoot);

  // Pernas
  const legs: THREE.Group[] = [];
  for (const sz of [1, -1]) {
    for (const sx of [-1, 1]) {
      const pivot = new THREE.Group();
      pivot.position.set(sx * v.largura * 0.36, v.pernas + 0.1, sz * v.comprimento * 0.28);
      const leg = mesh(faceted(new THREE.CylinderGeometry(0.22, 0.17, v.pernas + 0.2, 5)), bodyMat);
      leg.position.y = -(v.pernas + 0.2) / 2;
      pivot.add(leg);
      const paw = mesh(faceted(new THREE.BoxGeometry(0.4, 0.15, 0.5)), detailMat);
      paw.position.set(0, -v.pernas - 0.05, 0.08);
      pivot.add(paw);
      pose.add(pivot);
      legs.push(pivot);
    }
  }

  const tailMid = tailSegments[Math.min(2, tailSegments.length - 1)];
  const anchors: Record<PartId, THREE.Object3D> = { cabeca: head, costas: back, cauda: tailMid };

  return {
    root, pose, head, tailRoot, tailSegments, legs, spikes, eyes,
    bodyMats: [bodyMat, detailMat, partMats.cabeca, partMats.costas, partMats.cauda],
    partMats, anchors,
  };
}

// ---------------------------------------------------------------- cenário

export interface Biome {
  chao: string;
  borda: string;
  ceu: string;
  arvore: string;
  pedra: string;
}

export const BIOMES: Record<string, Biome> = {
  onca_brasa: { chao: "#c9a24a", borda: "#7a5530", ceu: "#f4b67a", arvore: "#9a7b2a", pedra: "#8b6a4f" },
  tatu_musgo: { chao: "#5d9a45", borda: "#4a3524", ceu: "#9ad3e6", arvore: "#2f7a3a", pedra: "#7c8a7a" },
  jacare_mare: { chao: "#4f8a72", borda: "#2d3e3a", ceu: "#7fb5c9", arvore: "#2c6650", pedra: "#56706e" },
};

export const ARENA_RADIUS = 30;

export function buildArena(scene: THREE.Scene, biome: Biome, rng: () => number): void {
  scene.background = new THREE.Color(biome.ceu);
  scene.fog = new THREE.Fog(biome.ceu, 45, 110);

  const ground = new THREE.Mesh(faceted(new THREE.CylinderGeometry(ARENA_RADIUS + 4, ARENA_RADIUS - 2, 6, 28, 1)), toon(biome.chao));
  ground.position.y = -3;
  ground.receiveShadow = true;
  scene.add(ground);
  const under = new THREE.Mesh(faceted(new THREE.ConeGeometry(ARENA_RADIUS - 2, 22, 10)), toon(biome.borda));
  under.rotation.x = Math.PI;
  under.position.y = -17;
  scene.add(under);

  // Grama/flores decorativas (instanciadas)
  const tuft = faceted(new THREE.ConeGeometry(0.15, 0.5, 3));
  const tufts = new THREE.InstancedMesh(tuft, toon(new THREE.Color(biome.chao).multiplyScalar(0.8)), 260);
  const m = new THREE.Matrix4();
  for (let i = 0; i < 260; i++) {
    const a = rng() * Math.PI * 2;
    const r = Math.sqrt(rng()) * (ARENA_RADIUS + 2);
    m.makeTranslation(Math.cos(a) * r, 0.2, Math.sin(a) * r);
    tufts.setMatrixAt(i, m);
  }
  scene.add(tufts);

  // Árvores e pedras na borda (área central fica livre para a luta)
  const trunkMat = toon("#5b3b22");
  const leafMat = toon(biome.arvore);
  const rockMat = toon(biome.pedra);
  for (let i = 0; i < 26; i++) {
    const a = rng() * Math.PI * 2;
    const r = ARENA_RADIUS - 3 + rng() * 6;
    const x = Math.cos(a) * r;
    const z = Math.sin(a) * r;
    if (rng() < 0.6) {
      const tree = new THREE.Group();
      const h = 2 + rng() * 2;
      const trunk = mesh(faceted(new THREE.CylinderGeometry(0.25, 0.35, h, 5)), trunkMat);
      trunk.position.y = h / 2;
      const crown = mesh(faceted(new THREE.IcosahedronGeometry(1.4 + rng(), 0)), leafMat);
      crown.position.y = h + 0.8;
      tree.add(trunk, crown);
      tree.position.set(x, 0, z);
      scene.add(tree);
    } else {
      const rock = mesh(faceted(new THREE.DodecahedronGeometry(0.8 + rng() * 1.4, 0)), rockMat);
      rock.position.set(x, 0.3, z);
      rock.rotation.set(rng(), rng(), rng());
      scene.add(rock);
    }
  }

  // O Monte ao fundo
  const mountain = new THREE.Group();
  const mMat = toon("#7d7f95");
  const peak = new THREE.Mesh(faceted(new THREE.ConeGeometry(38, 70, 7)), mMat);
  peak.position.y = 10;
  const snow = new THREE.Mesh(faceted(new THREE.ConeGeometry(12.5, 23, 7)), toon("#f4f6ff"));
  snow.position.y = 33.5;
  mountain.add(peak, snow);
  mountain.position.set(-20, -25, -95);
  scene.add(mountain);

  // Nuvens
  const cloudMat = toon("#ffffff");
  for (let i = 0; i < 9; i++) {
    const c = new THREE.Group();
    for (let k = 0; k < 3; k++) {
      const s = new THREE.Mesh(faceted(new THREE.IcosahedronGeometry(2 + rng() * 2, 0)), cloudMat);
      s.position.set(k * 2.5, rng(), rng());
      c.add(s);
    }
    const a = rng() * Math.PI * 2;
    c.position.set(Math.cos(a) * (55 + rng() * 20), -8 + rng() * 20, Math.sin(a) * (55 + rng() * 20));
    scene.add(c);
  }
}

export function buildGatherNode(kind: "minerio" | "fibra"): THREE.Group {
  const g = new THREE.Group();
  if (kind === "minerio") {
    const rock = mesh(faceted(new THREE.DodecahedronGeometry(0.5, 0)), toon("#6b6b78"));
    rock.position.y = 0.3;
    g.add(rock);
    for (let i = 0; i < 3; i++) {
      const c = mesh(faceted(new THREE.OctahedronGeometry(0.22)), toon("#7fd6ff", "#3aa8ff", 0.6));
      c.position.set((i - 1) * 0.3, 0.75, (i % 2) * 0.2);
      c.scale.y = 1.8;
      g.add(c);
    }
  } else {
    for (let i = 0; i < 4; i++) {
      const leaf = mesh(faceted(new THREE.ConeGeometry(0.25, 0.9, 3)), toon("#7ad65a", "#3f8f2a", 0.25));
      leaf.position.set(Math.cos(i * 1.6) * 0.25, 0.45, Math.sin(i * 1.6) * 0.25);
      leaf.rotation.z = Math.cos(i) * 0.4;
      g.add(leaf);
    }
  }
  return g;
}

/** Indicador de ataque no chão: contorno + preenchimento que cresce até o golpe. */
export function buildTelegraph(
  tipo: "setor" | "investida" | "circulo",
  raio: number,
  angulo: number,
  comprimento: number,
): { group: THREE.Group; fill: THREE.Mesh } {
  const group = new THREE.Group();
  const outlineMat = new THREE.MeshBasicMaterial({ color: 0xff2a2a, transparent: true, opacity: 0.22, depthWrite: false });
  const fillMat = new THREE.MeshBasicMaterial({ color: 0xff3b1f, transparent: true, opacity: 0.45, depthWrite: false });
  let geo: THREE.BufferGeometry;
  if (tipo === "investida") {
    geo = new THREE.PlaneGeometry(raio * 2, comprimento).rotateX(-Math.PI / 2).translate(0, 0, comprimento / 2);
  } else if (tipo === "circulo" || angulo >= 360) {
    geo = new THREE.CircleGeometry(raio, 40).rotateX(-Math.PI / 2);
  } else {
    const half = THREE.MathUtils.degToRad(angulo / 2);
    geo = new THREE.CircleGeometry(raio, 32, -Math.PI / 2 - half, half * 2).rotateX(-Math.PI / 2);
  }
  const outline = new THREE.Mesh(geo, outlineMat);
  const fill = new THREE.Mesh(geo, fillMat);
  outline.renderOrder = 1;
  fill.renderOrder = 2;
  group.add(outline, fill);
  group.position.y = 0.06;
  return { group, fill };
}

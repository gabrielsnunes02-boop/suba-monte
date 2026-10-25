import { BEASTS, ELEMENT_INFO, GEAR, MATERIALS, MAX_UPGRADE, PERKS, weaknessOf, type Gear } from "../game/data";
import { elementMultiplier, gearValue, upgradeCost, xpForRank } from "../game/formulas";
import {
  applyHuntResult,
  canCraft,
  canUpgrade,
  craft,
  equip,
  loadProfile,
  resetProfile,
  saveProfile,
  upgrade,
  type HuntResult,
  type Profile,
} from "../game/profile";
import { Hunt } from "../hunt/hunt";

type Screen = "home" | "cacar" | "forja" | "equip" | "inventario";

const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);

function el(e: string): string {
  const i = ELEMENT_INFO[e as keyof typeof ELEMENT_INFO];
  return `<span class="el" style="--c:${i.cor}">${i.icone} ${i.nome}</span>`;
}

function matName(id: string): string {
  return MATERIALS[id]?.nome ?? id;
}

function statLine(g: Gear, level: number): string {
  const v = gearValue(g, level);
  return g.slot === "arma" ? `Poder <b>${v}</b>` : `Defesa <b>${Math.round(v * 100)}%</b>`;
}

export class App {
  private profile: Profile = loadProfile();
  private screen: Screen = "home";
  private result: { r: HuntResult; subiu: number } | null = null;

  constructor(private root: HTMLElement) {
    root.addEventListener("click", (e) => this.onClick(e));
    this.render();
  }

  private set(p: Profile): void {
    this.profile = p;
    saveProfile(p);
    this.render();
  }

  private go(s: Screen): void {
    this.screen = s;
    this.result = null;
    this.render();
    this.root.scrollTop = 0;
  }

  private toast(msg: string): void {
    const t = document.createElement("div");
    t.className = "toast";
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 1800);
  }

  private onClick(e: Event): void {
    const t = (e.target as HTMLElement).closest<HTMLElement>("[data-a]");
    if (!t) return;
    const a = t.dataset.a!;
    const id = t.dataset.id ?? "";
    try {
      switch (a) {
        case "go":
          this.go(id as Screen);
          break;
        case "hunt":
          this.startHunt(id);
          break;
        case "craft":
          this.set(craft(this.profile, id));
          this.toast(`Fabricado: ${GEAR[id].nome}`);
          break;
        case "upgrade":
          this.set(upgrade(this.profile, id));
          this.toast(`${GEAR[id].nome} +${this.profile.equipamentos[id]}`);
          break;
        case "equip":
          this.set(equip(this.profile, id));
          this.toast(`Equipado: ${GEAR[id].nome}`);
          break;
        case "reset":
          if (confirm("Apagar todo o progresso deste aparelho?")) {
            this.profile = resetProfile();
            this.go("home");
          }
          break;
      }
    } catch (err) {
      this.toast((err as Error).message);
    }
  }

  private startHunt(feraId: string): void {
    this.root.innerHTML = "";
    document.body.classList.add("in-hunt");
    new Hunt(document.body, this.profile, feraId, (r) => {
      document.body.classList.remove("in-hunt");
      const { profile, subiuRank } = applyHuntResult(this.profile, r);
      this.profile = profile;
      saveProfile(profile);
      this.result = { r, subiu: subiuRank };
      this.render();
    });
  }

  // ------------------------------------------------------------ telas

  private render(): void {
    const p = this.profile;
    const body = this.result
      ? this.renderResult()
      : { home: () => this.renderHome(), cacar: () => this.renderHunts(), forja: () => this.renderForge(), equip: () => this.renderEquip(), inventario: () => this.renderInventory() }[this.screen]();
    const back = this.screen !== "home" || this.result ? `<button class="back" data-a="go" data-id="home">‹ Acampamento</button>` : "";
    this.root.innerHTML = `
      <header class="top">
        ${back || `<div class="logo">SUBA <b>MONTE</b><small>Caçadores da Montanha</small></div>`}
        <div class="wallet"><span>Rank ${p.rank}</span><span>🪙 ${p.moedas}</span></div>
      </header>
      <main class="screen">${body}</main>`;
  }

  private renderHome(): string {
    const p = this.profile;
    const w = GEAR[p.equipado.arma];
    const a = GEAR[p.equipado.armadura];
    const need = xpForRank(p.rank);
    const gearCard = (g: Gear) => `
      <div class="gear-mini">
        <div class="gear-slot">${g.slot === "arma" ? "Arma" : "Armadura"}</div>
        <div class="gear-name">${g.nome} <span class="lvl">+${p.equipamentos[g.id]}</span></div>
        <div class="gear-stats">${statLine(g, p.equipamentos[g.id])} · ${el(g.elemento)}</div>
        ${g.perk ? `<div class="perk">✦ ${PERKS[g.perk].nome}: ${PERKS[g.perk].descricao}</div>` : ""}
      </div>`;
    return `
      <section class="hero-card">
        <div class="mountain-art" aria-hidden="true"></div>
        <h1>O Monte espera, caçador.</h1>
        <p>Cace feras, quebre suas partes, forje o equipamento delas e suba cada vez mais alto.</p>
        <div class="xp"><div class="xp-label">Rank ${p.rank} · ${p.xp}/${need} XP</div><div class="bar xpbar"><i class="fill" style="width:${(p.xp / need) * 100}%"></i></div></div>
      </section>
      <button class="btn primary big" data-a="go" data-id="cacar">⚔ Caçar</button>
      <div class="grid2">
        <button class="btn tile" data-a="go" data-id="forja">🔨<span>Forja</span></button>
        <button class="btn tile" data-a="go" data-id="equip">🛡<span>Equipamento</span></button>
        <button class="btn tile" data-a="go" data-id="inventario">🎒<span>Inventário</span></button>
        <button class="btn tile" data-a="go" data-id="cacar">📖<span>Bestiário</span></button>
      </div>
      <section class="card"><h2>Loadout</h2>${gearCard(w)}${gearCard(a)}</section>
      <p class="foot">Progresso salvo neste aparelho (funciona offline). <button class="link" data-a="reset">Apagar progresso</button></p>`;
  }

  private renderHunts(): string {
    const p = this.profile;
    const weapon = GEAR[p.equipado.arma];
    return `<h2 class="title">Escolha sua presa</h2>
      ${BEASTS.map((b) => {
        const locked = p.rank < b.rankMinimo;
        const weak = weaknessOf(b.elemento);
        const mult = elementMultiplier(weapon.elemento, b.elemento);
        const best = p.bestiario[b.id];
        const multTxt = mult > 1 ? `<span class="good">vantagem ×${mult}</span>` : mult < 1 ? `<span class="bad">desvantagem ×${mult}</span>` : `<span>neutro ×1</span>`;
        return `<article class="beast-card ${locked ? "locked" : ""}" style="--c:${ELEMENT_INFO[b.elemento].cor}">
          <div class="beast-head">
            <div><h3>${b.nome}</h3><small>${b.apelido}</small></div>
            <div class="tier">Tier ${b.tier}</div>
          </div>
          <p>${b.descricao}</p>
          <div class="chips">${el(b.elemento)} <span class="chip">Fraca a: ${weak ? el(weak) : "—"}</span></div>
          <div class="chips"><span class="chip">Sua arma: ${multTxt}</span>
          ${best ? `<span class="chip">Abates ${best.abates}${best.melhorTempo !== null ? ` · recorde ${best.melhorTempo}s` : ""}</span>` : ""}</div>
          <div class="drops">Partes: ${b.partes.map((x) => `${x.nome} → ${matName(x.drop)}`).join(" · ")}</div>
          ${locked ? `<button class="btn" disabled>🔒 Requer Rank ${b.rankMinimo}</button>` : `<button class="btn primary" data-a="hunt" data-id="${b.id}">Caçar ${b.nome}</button>`}
        </article>`;
      }).join("")}`;
  }

  private recipe(need: Record<string, number>, coins: number): string {
    const inv = this.profile.inventario;
    const items = Object.entries(need).map(([k, v]) => {
      const have = inv[k] ?? 0;
      return `<span class="chip ${have >= v ? "ok" : "miss"}">${matName(k)} ${have}/${v}</span>`;
    });
    items.push(`<span class="chip ${this.profile.moedas >= coins ? "ok" : "miss"}">🪙 ${coins}</span>`);
    return `<div class="chips">${items.join("")}</div>`;
  }

  private renderForge(): string {
    const p = this.profile;
    const craftable = Object.values(GEAR).filter((g) => !(g.id in p.equipamentos));
    const owned = Object.values(GEAR).filter((g) => g.id in p.equipamentos);
    return `<h2 class="title">Forja</h2>
      <p class="sub">Fabricar é garantido: sem chance de falha. Partes quebradas dão materiais extras.</p>
      <h3 class="section">Fabricar</h3>
      ${craftable.length ? craftable.map((g) => `
        <article class="card gear-card">
          <div class="row"><b>${g.nome}</b>${el(g.elemento)}</div>
          <div class="gear-stats">${statLine(g, 0)}${g.fera ? ` · da ${BEASTS.find((b) => b.id === g.fera)?.nome}` : ""}</div>
          ${g.perk ? `<div class="perk">✦ ${PERKS[g.perk].nome}: ${PERKS[g.perk].descricao}</div>` : ""}
          ${this.recipe(g.receita, g.custo)}
          <button class="btn ${canCraft(p, g) ? "primary" : ""}" data-a="craft" data-id="${g.id}" ${canCraft(p, g) ? "" : "disabled"}>Fabricar</button>
        </article>`).join("") : `<p class="sub">Você já fabricou tudo!</p>`}
      <h3 class="section">Melhorar (+0 a +${MAX_UPGRADE})</h3>
      ${owned.map((g) => {
        const lvl = p.equipamentos[g.id];
        const cost = upgradeCost(g, lvl);
        return `<article class="card gear-card">
          <div class="row"><b>${g.nome} <span class="lvl">+${lvl}</span></b>${el(g.elemento)}</div>
          <div class="gear-stats">${statLine(g, lvl)}${cost ? ` → ${statLine(g, lvl + 1)}` : ""}</div>
          ${cost ? this.recipe(cost.materiais, cost.moedas) + `<button class="btn ${canUpgrade(p, g.id) ? "primary" : ""}" data-a="upgrade" data-id="${g.id}" ${canUpgrade(p, g.id) ? "" : "disabled"}>Melhorar</button>` : `<div class="good">Nível máximo!</div>`}
        </article>`;
      }).join("")}`;
  }

  private renderEquip(): string {
    const p = this.profile;
    const owned = Object.values(GEAR).filter((g) => g.id in p.equipamentos);
    const group = (slot: "arma" | "armadura", title: string) => `
      <h3 class="section">${title}</h3>
      ${owned.filter((g) => g.slot === slot).map((g) => {
        const on = p.equipado[slot] === g.id;
        return `<article class="card gear-card ${on ? "equipped" : ""}">
          <div class="row"><b>${g.nome} <span class="lvl">+${p.equipamentos[g.id]}</span></b>${el(g.elemento)}</div>
          <div class="gear-stats">${statLine(g, p.equipamentos[g.id])}</div>
          ${g.perk ? `<div class="perk">✦ ${PERKS[g.perk].nome}: ${PERKS[g.perk].descricao}</div>` : ""}
          ${on ? `<div class="good">Equipado</div>` : `<button class="btn" data-a="equip" data-id="${g.id}">Equipar</button>`}
        </article>`;
      }).join("")}`;
    return `<h2 class="title">Equipamento</h2>
      <p class="sub">Dica: use a arma do elemento que vence a fera (Fogo ► Natureza ► Água ► Fogo) e a armadura do mesmo elemento dela.</p>
      ${group("arma", "Armas")}${group("armadura", "Armaduras")}`;
  }

  private renderInventory(): string {
    const inv = Object.entries(this.profile.inventario).filter(([, v]) => v > 0);
    return `<h2 class="title">Inventário</h2>
      ${inv.length ? `<div class="inv">${inv.map(([k, v]) => {
        const m = MATERIALS[k];
        return `<div class="inv-item r-${m?.raridade ?? "comum"}"><b>${v}×</b> ${esc(matName(k))}<small>${esc(m?.descricao ?? "")}</small></div>`;
      }).join("")}</div>` : `<p class="sub">Vazio. Vá caçar!</p>`}`;
  }

  private renderResult(): string {
    const { r, subiu } = this.result!;
    const b = BEASTS.find((x) => x.id === r.feraId)!;
    const loot = Object.entries(r.loot);
    return `<section class="result ${r.vitoria ? "win" : "lose"}">
        <h2>${r.vitoria ? "Caçada concluída!" : "Caçada falhou"}</h2>
        <p>${b.nome} · ${Math.floor(r.tempo / 60)}:${String(r.tempo % 60).padStart(2, "0")} · ${r.partesQuebradas} parte(s) quebrada(s)</p>
        ${subiu ? `<div class="rankup">⬆ Subiu para o Rank ${this.profile.rank}!</div>` : ""}
        <div class="chips center"><span class="chip ok">+${r.xp} XP</span>${r.moedas ? `<span class="chip ok">🪙 +${r.moedas}</span>` : ""}</div>
        ${loot.length ? `<div class="inv">${loot.map(([k, v]) => `<div class="inv-item r-${MATERIALS[k]?.raridade ?? "comum"}"><b>${v}×</b> ${esc(matName(k))}</div>`).join("")}</div>` : `<p class="sub">Nenhum material.</p>`}
      </section>
      <button class="btn primary big" data-a="go" data-id="forja">🔨 Ir para a Forja</button>
      <div class="grid2">
        <button class="btn" data-a="hunt" data-id="${r.feraId}">Caçar de novo</button>
        <button class="btn" data-a="go" data-id="home">Acampamento</button>
      </div>`;
  }
}

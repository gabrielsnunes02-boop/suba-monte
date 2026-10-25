import { describe, expect, it } from "vitest";
import { BEASTS, GEAR, MAX_UPGRADE, weaknessOf } from "./data";
import {
  applyXp,
  computeDamage,
  elementMultiplier,
  elementalResistance,
  gearValue,
  rollLoot,
  upgradeCost,
  xpForRank,
} from "./formulas";
import { applyHuntResult, canCraft, craft, equip, newProfile, upgrade } from "./profile";

const seq = (...vals: number[]) => {
  let i = 0;
  return () => vals[i++ % vals.length];
};

describe("elementos", () => {
  it("segue o ciclo fogo > natureza > água > fogo", () => {
    expect(elementMultiplier("fogo", "natureza")).toBe(1.5);
    expect(elementMultiplier("natureza", "agua")).toBe(1.5);
    expect(elementMultiplier("agua", "fogo")).toBe(1.5);
    expect(elementMultiplier("natureza", "fogo")).toBe(0.75);
    expect(elementMultiplier("fogo", "fogo")).toBe(1);
    expect(elementMultiplier("neutro", "agua")).toBe(1);
  });

  it("calcula fraqueza", () => {
    expect(weaknessOf("fogo")).toBe("agua");
    expect(weaknessOf("natureza")).toBe("fogo");
    expect(weaknessOf("neutro")).toBeNull();
  });

  it("armadura resiste ao próprio elemento e sofre com o que a vence", () => {
    expect(elementalResistance("fogo", "fogo")).toBe(0.8);
    expect(elementalResistance("fogo", "agua")).toBe(1.2);
    expect(elementalResistance("neutro", "agua")).toBe(1);
  });

  it("toda fera tem um counter craftável", () => {
    for (const b of BEASTS) {
      const fraco = weaknessOf(b.elemento);
      expect(Object.values(GEAR).some((g) => g.slot === "arma" && g.elemento === fraco)).toBe(true);
    }
  });
});

describe("dano", () => {
  const base = { base: 40, motion: 1, perkBonus: 0, crit: false, elementMult: 1, partMult: 1, defense: 0 };

  it("aplica todos os multiplicadores", () => {
    expect(computeDamage(base)).toBe(40);
    expect(computeDamage({ ...base, crit: true })).toBe(60);
    expect(computeDamage({ ...base, elementMult: 1.5, partMult: 1.3, defense: 0.1 })).toBe(70);
  });

  it("limita bônus de perks a +100% e nunca dá menos que 1", () => {
    expect(computeDamage({ ...base, perkBonus: 5 })).toBe(80);
    expect(computeDamage({ ...base, base: 0 })).toBe(1);
  });
});

describe("upgrade", () => {
  it("custa mais a cada nível e pede material raro a partir do +5", () => {
    const g = GEAR.lamina_brasa;
    const c0 = upgradeCost(g, 0)!;
    const c5 = upgradeCost(g, 5)!;
    expect(c0.materiais).toEqual({ couro_brasa: 1 });
    expect(c5.materiais).toEqual({ couro_brasa: 6, coracao_brasa: 1 });
    expect(c5.moedas).toBeGreaterThan(c0.moedas);
    expect(upgradeCost(g, MAX_UPGRADE)).toBeNull();
  });

  it("aumenta o valor do item em 8% por nível", () => {
    expect(gearValue(GEAR.espada_ferro, 0)).toBe(40);
    expect(gearValue(GEAR.espada_ferro, 10)).toBe(72);
  });
});

describe("progressão", () => {
  it("sobe vários ranks de uma vez", () => {
    const r = applyXp(1, 0, xpForRank(1) + xpForRank(2) + 5);
    expect(r).toEqual({ rank: 3, xp: 5, subiu: 2 });
  });

  it("rola loot de forma determinística com rng injetado", () => {
    const loot = rollLoot(BEASTS[0].loot, seq(0, 0.99, 0.5, 0.5, 0.99));
    expect(loot.couro_brasa).toBe(3);
    expect(loot.garra_brasa).toBe(2);
    expect(loot.coracao_brasa).toBeUndefined();
  });
});

describe("perfil", () => {
  it("fluxo completo: caçar → fabricar → melhorar → equipar", () => {
    let p = newProfile();
    expect(canCraft(p, GEAR.lamina_brasa)).toBe(false);

    p = applyHuntResult(p, {
      feraId: "onca_brasa", vitoria: true, tempo: 120, partesQuebradas: 2,
      loot: { couro_brasa: 5, garra_brasa: 2 }, moedas: 400, xp: 80,
    }).profile;
    expect(p.bestiario.onca_brasa.abates).toBe(1);
    expect(canCraft(p, GEAR.lamina_brasa)).toBe(true);

    p = craft(p, "lamina_brasa");
    expect(p.equipamentos.lamina_brasa).toBe(0);
    expect(p.inventario.garra_brasa).toBeUndefined();
    expect(canCraft(p, GEAR.lamina_brasa)).toBe(false);

    p = upgrade(p, "lamina_brasa");
    expect(p.equipamentos.lamina_brasa).toBe(1);

    p = equip(p, "lamina_brasa");
    expect(p.equipado.arma).toBe("lamina_brasa");
    expect(() => equip(p, "lamina_mare")).toThrow();
  });
});

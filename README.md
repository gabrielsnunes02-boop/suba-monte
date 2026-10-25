# Suba Monte — Caçadores da Montanha

Jogo de caçada a feras para celular, inspirado em **Dauntless** e **Monster Hunter**.
Você caça feras, quebra suas partes, leva os materiais para a forja, fabrica e melhora o equipamento delas, e encara feras mais fortes.

> Documento de design / pesquisa completa: [`docs/pesquisa-dauntless-mobile.md`](docs/pesquisa-dauntless-mobile.md)

## Estado atual: protótipo jogável (vertical slice)

Roda no navegador do celular ou do computador e pode ser instalado como app (PWA). Funciona offline depois do primeiro acesso, e o progresso fica salvo no aparelho.

**O que já existe**

| Sistema | O que tem |
|---|---|
| Combate | Combo leve de 3 golpes, ataque carregado (segurar), esquiva com invencibilidade e stamina, **esquiva perfeita** (câmera lenta), poções, mira assistida, hit-stop e tremor de câmera |
| Feras | 3 feras com IA própria: **Onça-Brasa** (Fogo), **Tatu-Musgo** (Natureza), **Jacaré-Maré** (Água, Tier 2) |
| Caçada | Ataques **telegrafados no chão** (área vermelha que enche até o golpe), **fúria** com 40% de vida, **atordoamento** por golpes na cabeça, partes **feridas** (+30% dano) e **quebráveis**, **cauda cortável**, 3 desmaios permitidos |
| Elementos | Fogo ► Natureza ► Água ► Fogo (×1,5 / ×0,75 de dano; armadura resiste ao próprio elemento) |
| Coleta | Minério e fibra espalhados pela ilha |
| Forja | Fabricação determinística (arma + armadura de cada fera), upgrade +0 a +10 (material raro a partir do +5) |
| Builds | Cada peça tem perk temático: Quebra-Ossos, Caçador Paciente, Esquiva Afiada, Último Fôlego, Pele Grossa, Fôlego Longo |
| Progressão | Rank de caçador (desbloqueia feras), bestiário com abates e recorde de tempo |

## Controles

| Ação | Celular | Teclado/Mouse |
|---|---|---|
| Mover | Joystick (metade esquerda da tela) | WASD / setas |
| Ataque leve (combo) | Tocar ⚔ | J, Enter ou clique |
| Ataque carregado | Segurar ⚔ e soltar | Segurar J ou o clique |
| Esquiva | ⤴ | Espaço, K ou Shift |
| Poção | ✚ | Q ou E |

Dica: jogue com o celular **na horizontal**.

## Rodando

```bash
npm install
npm run dev        # servidor local; abra o endereço "Network" no celular (mesma rede Wi-Fi)
npm test           # testes das fórmulas, forja e progressão
npm run build      # gera a versão final em dist/
npm run preview    # serve o build
```

Adicione `?debug` na URL para expor a caçada atual em `window.__hunt` (usado em testes automatizados).

## Tecnologia

- **TypeScript + Three.js** (3D low-poly procedural: nenhum modelo ou textura externa, o jogo inteiro tem ~160 KB gzip)
- **Vite** (build) e **Vitest** (testes)
- PWA: `manifest.webmanifest` + service worker (offline)
- Tudo de balanceamento fica em [`src/game/data.ts`](src/game/data.ts)

```
src/
  game/        regras puras, sem 3D (testáveis)
    data.ts      feras, ataques, materiais, equipamentos, perks, elementos
    formulas.ts  dano, elementos, upgrade, XP, loot
    profile.ts   perfil, forja, upgrade, equipar, salvar (localStorage)
  hunt/        a caçada em 3D
    hunt.ts      cena, câmera, loop, HUD, fim da caçada
    player.ts    estados do caçador (combo, carregado, esquiva, poção…)
    beast.ts     IA da fera (perseguir, preparar, atacar, fúria, atordoar, partes)
    models.ts    modelos procedurais, cenário e indicadores no chão
    input.ts     joystick virtual, botões de toque e teclado
    fx.ts        partículas e números de dano
  ui/app.ts    telas do acampamento (caçar, forja, equipamento, inventário, resultado)
```

## Como publicar

- **Web:** qualquer hospedagem estática serve a pasta `dist/` (GitHub Pages, Vercel, Netlify). O build usa caminhos relativos, então funciona em subpastas.
- **Lojas (Android/iOS):** empacotar o `dist/` com [Capacitor](https://capacitorjs.com/) (`npx cap add android`).

## Próximos passos (roadmap)

1. Mais armas (martelo para atordoar, lança, arco) com especiais
2. Núcleos (papéis: Guardião, Curandeiro, Fúria, Vento) e gemas nos slots
3. Co-op de até 4 jogadores (servidor autoritativo, ex.: Colyseus ou Nakama)
4. Mais feras por família (variantes elementais reaproveitando esqueletos) e chefe de temporada
5. Modelos e animações feitos por artista, som e música
6. Login/sincronização na nuvem do progresso

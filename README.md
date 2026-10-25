# Suba Monte — Caçadores da Montanha

Jogo de caçada a feras em **terceira pessoa** para celular, feito na **Godot 4**, inspirado em **Dauntless** e **Monster Hunter**.
Você caça feras, quebra suas partes, leva os materiais para a forja, fabrica e melhora o equipamento delas, e encara feras mais fortes.

> Pesquisa e documento de design: [`docs/pesquisa-dauntless-mobile.md`](docs/pesquisa-dauntless-mobile.md)

## O que já existe

| Sistema | O que tem |
|---|---|
| Câmera | Terceira pessoa atrás do caçador (estilo Dauntless), **trava de mira na fera** (botão MIRA), giro arrastando o dedo na metade direita |
| Combate | Combo leve de 3 golpes, ataque carregado (segurar), esquiva com invencibilidade e stamina, **esquiva perfeita** (câmera lenta), poções, mira assistida, hit-stop e tremor de câmera |
| Feras | **Onça-Brasa** (Fogo), **Tatu-Musgo** (Natureza), **Jacaré-Maré** (Água, Tier 2) |
| Caçada | Ataques **avisados no chão** (área vermelha que enche até o golpe), **fúria** com 40% de vida, **atordoamento** por golpes na cabeça, partes **feridas** (+30% de dano) e **quebráveis**, **cauda cortável**, 3 desmaios permitidos |
| Elementos | Fogo ► Natureza ► Água ► Fogo (×1,5 / ×0,75 de dano; armadura resiste ao próprio elemento) |
| Coleta e forja | Minério e fibra na ilha; fabricação garantida; upgrade +0 a +10 (material raro a partir do +5) |
| Builds | Perks: Quebra-Ossos, Caçador Paciente, Esquiva Afiada, Último Fôlego, Pele Grossa, Fôlego Longo |
| Progressão | Rank de caçador (libera feras), bestiário com abates e recorde, progresso salvo no aparelho (offline) |
| Visual | Ilha flutuante estilizada (toon), céu, neblina, grama animada por shader, árvores, o Monte ao fundo |

Todos os modelos são gerados por código (nenhum asset externo). Trocar por modelos de artista depois é só substituir as funções em `scripts/hunt/models.gd`.

## Controles

| Ação | Celular | Teclado | Controle |
|---|---|---|---|
| Mover | Joystick (metade esquerda) | WASD / setas | Analógico esquerdo |
| Girar câmera | Arrastar na metade direita | Arrastar com o mouse | Analógico direito |
| Ataque leve / carregado | Tocar / segurar ATACAR | J (segure para carregar) | X |
| Esquiva | ESQUIVA | Espaço | A |
| Poção | POÇÃO | Q | Y |
| Trava de mira | MIRA | Tab | R3 |
| Pausa | Botão II | Esc | Start |

## Como abrir e testar

1. Baixe a **Godot 4.4** (ou mais nova): https://godotengine.org/download
2. Abra a Godot → **Importar** → escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar no computador (o mouse simula o toque).

### No celular Android

1. Na Godot: **Editor → Gerenciar modelos de exportação → Baixar e instalar**.
2. **Editor → Configurações do editor → Exportar → Android**: aponte o Java (JDK 17) e o Android SDK
   (guia oficial: https://docs.godotengine.org/pt-br/4.x/tutorials/export/exporting_for_android.html).
3. **Projeto → Exportar → Adicionar… → Android → Exportar projeto** para gerar o `.apk`, ou use o botão
   **Implantação com um clique** (ícone do Android no canto superior direito) com o celular ligado no USB em modo desenvolvedor.

O projeto usa o renderizador **Mobile** (Vulkan), em paisagem, com compressão de texturas ETC2/ASTC já ligada.

## Testes

```bash
# regras do jogo (dano, elementos, forja, upgrade, progressão)
godot --headless --path . --script res://tests/run_tests.gd

# caçada completa jogada por um bot (sem tela)
godot --headless --path . -- --bot=onca_brasa --seconds=90
```

## Estrutura

```
project.godot            configuração (renderizador Mobile, paisagem, toque)
scenes/main.tscn         cena inicial
scripts/
  main.gd                entrada: controles, acampamento ↔ caçada, modo bot de teste
  core/                  regras puras, sem cena (testadas)
    game_data.gd           feras, ataques, materiais, equipamentos, perks, elementos
    formulas.gd            dano, elementos, upgrade, XP, loot
    profile_logic.gd       perfil, forja, upgrade, equipar, salvar (user://perfil.json)
  hunt/                  a caçada em 3D
    hunt.gd                monta a ilha, liga tudo, tempo (hit-stop/câmera lenta), fim
    player.gd              estados do caçador (combo, carregado, esquiva, poção…)
    beast.gd               IA da fera (perseguir, avisar, atacar, fúria, atordoar, partes)
    camera_rig.gd          câmera em terceira pessoa com trava de mira
    models.gd              modelos procedurais, cenário, grama, avisos no chão
    fx.gd                  partículas e números de dano
  ui/
    hub.gd                 acampamento (caçar, forja, equipamento, inventário, resultado)
    hud.gd                 HUD da caçada e pausa
    touch_controls.gd      joystick, câmera e botões com multitoque
tests/run_tests.gd       testes das regras
prototipo-web/           primeiro protótipo (TypeScript + Three.js), mantido como referência
```

## Próximos passos

1. Modelos e animações de artista (glTF/Blender) no lugar dos procedurais, som e música
2. Mais armas (martelo para atordoar, lança, arco) com especiais
3. Núcleos (papéis: Guardião, Curandeiro, Fúria, Vento) e gemas nos slots
4. Co-op de até 4 jogadores (multiplayer da Godot com servidor dedicado)
5. Mais feras por família e chefe de temporada

# Pesquisa completa: Dauntless → base para um Monster Hunter mobile

> Documento de referência para criar um jogo **inspirado** em Dauntless (e, por tabela, em Monster Hunter) para celular.
> Parte 1 descreve o Dauntless original. Parte 2 traduz isso em decisões de design e tecnologia para mobile.
>
> **Legenda de confiança:** ✅ confirmado em fontes públicas · ⚠️ de memória/comunidade, conferir antes de usar como dado exato.
> Números de balanceamento do Dauntless mudaram muito entre patches; use-os como **ordem de grandeza**, não como valores finais.

---

## Sumário

1. [Ficha técnica e história do jogo](#1-ficha-técnica-e-história-do-jogo)
2. [Por que ele foi descontinuado](#2-por-que-ele-foi-descontinuado)
3. [Tecnologia](#3-tecnologia)
4. [Construção de mundo (lore e ambientação)](#4-construção-de-mundo)
5. [Loop principal de gameplay](#5-loop-principal-de-gameplay)
6. [Combate e mecânicas de caça](#6-combate-e-mecânicas-de-caça)
7. [Feras (Behemoths)](#7-feras-behemoths)
8. [Sistema elemental](#8-sistema-elemental)
9. ["Classes": armas, Omnicélulas e papéis](#9-classes-armas-omnicélulas-e-papéis)
10. [Armaduras, lanternas e células (perks)](#10-armaduras-lanternas-e-células-perks)
11. [Builds](#11-builds)
12. [Dano: como funcionava](#12-dano-como-funcionava)
13. [Coleta, fabricação e upgrade](#13-coleta-fabricação-e-upgrade)
14. [Níveis e progressão](#14-níveis-e-progressão)
15. [Modos de jogo e endgame](#15-modos-de-jogo-e-endgame)
16. [Monetização](#16-monetização)
17. [Lições: o que funcionou e o que não funcionou](#17-lições)
18. [Proposta: versão mobile](#18-proposta-versão-mobile)
19. [Fontes](#19-fontes)

---

# PARTE 1 — O DAUNTLESS ORIGINAL

## 1. Ficha técnica e história do jogo

| Item | Detalhe |
|---|---|
| Desenvolvedora | **Phoenix Labs** (Vancouver, Canadá), fundada em 2014 por ex-funcionários de Riot, BioWare e Blizzard ✅ |
| Gênero | Action RPG cooperativo de caça a monstros ("hunting game"), *free-to-play* ✅ |
| Inspiração direta | Série **Monster Hunter** (Capcom) — loop caçar → coletar partes → fabricar equipamento → caçar algo mais forte ✅ |
| Plataformas | PC (Epic Games Store; Steam no fim da vida), PS4, Xbox One, Nintendo Switch; versões PS5/Xbox Series depois ✅ |
| Beta aberto | Maio de 2018 (PC) ⚠️ |
| Lançamento 1.0 | 21 de maio de 2019 — já com *cross-play* e *cross-progression* completos entre todas as plataformas, algo raro na época ✅ |
| Donos | Adquirida pela **Garena** (~2020) e depois pela **Forte** (empresa de blockchain, 2022–2023) ✅ |
| Última grande atualização | **Awakening** — dezembro de 2024 (junto com o lançamento na Steam) ✅ |
| Encerramento | Anunciado em 24/02/2025; servidores desligados em **29 de maio de 2025** (23h45 PST) ✅ |
| Público | Milhões de jogadores na primeira semana do 1.0 (a Phoenix Labs divulgou ~4 milhões) ⚠️ |

**Linha do tempo resumida**

- **2018** – Beta aberto, PC.
- **2019** – Lançamento 1.0 em consoles com cross-play; Hunt Pass (passe de batalha); **Escalations** (modo endgame em camadas); chegada ao Switch no fim do ano.
- **2020** – Novas armas e feras; **Trials** (contra o tempo) e **Gauntlet** (ranqueado sazonal); **Reforged**: grande revisão de progressão, com **Hunting Grounds** (ilhas abertas com várias feras) e **Mastery**.
- **2021–2023** – Ritmo de conteúdo cai; novas feras e eventos sazonais; estúdio vendido para a Forte.
- **Dez/2024** – **Awakening**: remove o sistema clássico de fabricar armas a partir das feras, reseta grande parte da progressão, remove várias moedas (Aetherdust, Aethersparks, Aetherhearts, Chronostones, Cache Coins) e o elemento Neutro. Recepção muito negativa ("Overwhelmingly Negative" na Steam) ✅
- **Jan/2025** – Demissões em massa na Phoenix Labs ✅
- **Fev/2025** – Anúncio do fim. **Mai/2025** – Servidores desligados ✅

## 2. Por que ele foi descontinuado

Fatores que aparecem em praticamente todas as análises:

1. **Awakening quebrou o pilar central.** O jogo era "mate o monstro para fazer a arma do monstro". A atualização removeu esse vínculo e apagou o progresso dos veteranos. Perder a fantasia central + perder o progresso = êxodo.
2. **Endgame raso.** Mesmo antes disso, os jogadores reclamavam que as builds convergiam para poucas opções "meta" e que faltava conteúdo difícil e duradouro.
3. **Ritmo de conteúdo lento** depois de 2020, enquanto Monster Hunter: World/Iceborne/Rise elevavam o padrão.
4. **Instabilidade corporativa.** Trocas de dono (Garena → Forte), foco da Forte em blockchain, demissões.
5. **Serviço online obrigatório.** Sem servidores, o jogo simplesmente deixou de existir — nem o modo solo sobreviveu.

> **Lição para o seu projeto:** nunca desmonte o loop "fera → partes → equipamento", e planeje desde o início um modo offline/solo que sobreviva ao fim dos servidores.

## 3. Tecnologia

| Camada | O que o Dauntless usava |
|---|---|
| Motor | **Unreal Engine 4** ✅ |
| Estilo visual | Estilizado/"cartunesco" (cel-shading leve, cores saturadas, silhuetas fortes) — escolha que reduzia custo de arte e rodava bem até no Switch ✅ |
| Rede | Sessões cooperativas de até **4 jogadores** em servidores dedicados; *matchmaking* por fera/dificuldade ✅ |
| Plataformas | Uma conta única (login Epic/Phoenix Labs) com **cross-play e cross-save** em PC, PlayStation, Xbox e Switch ✅ |
| Mundo | **Ilhas pequenas e instanciadas** (não mundo aberto contínuo). Cada caçada carregava uma ilha flutuante — tecnicamente barato e ótimo para matchmaking ✅ |
| Hub social | **Ramsgate**: cidade-hub com dezenas de jogadores, lojas, ferreiro, quadro de missões ✅ |
| Live ops | Temporadas com Hunt Pass, eventos sazonais, rotação de modificadores ✅ |

**Por que isso importa para mobile:** ilhas instanciadas, grupos de 4, estilo estilizado e um hub social são *exatamente* o formato que cabe num celular. O Dauntless já era uma arquitetura "mobile-friendly" disfarçada.

## 4. Construção de mundo

### Premissa
- O mundo se partiu num cataclismo e virou as **Ilhas Despedaçadas** (*Shattered Isles*): pedaços de terra flutuando no céu ✅
- O **Éter** (*Aether*), energia mágica que vaza das fendas do mundo, é o recurso mais valioso e o que alimenta as feras ✅
- **Behemoths** são criaturas gigantes atraídas e modificadas pelo éter. Elas ameaçam a humanidade e "consomem" as ilhas ✅
- Os **Slayers** (Caçadores) são uma ordem que caça behemoths para proteger os assentamentos e usa as partes delas para fabricar armas e armaduras ✅
- Aeronaves (*airships*) levam os caçadores do hub para as ilhas ✅

### Locais e facções
- **Ramsgate** — cidade-fortaleza, último grande bastião humano, onde fica a guilda dos Slayers ✅
- Regiões/ilhas com biomas variados: florestas, desertos, tundra, vulcões, pântanos, ruínas antigas ✅
- Ameaças maiores ao longo da história: **feras corrompidas pelo Umbral** (escuridão), um culto/força ligado ao éter corrompido, e "titãs" que ameaçam ilhas inteiras ⚠️

### Como a narrativa era entregue
- Pouca cutscene; muito texto em NPCs e missões. A história era considerada fraca pela comunidade — o jogo vivia do combate.
- **Oportunidade para você:** um mundo com identidade própria e narrativa curta, mas presente (diálogos rápidos, "fichas" de cada fera num bestiário), diferencia muito no mobile.

## 5. Loop principal de gameplay

```
  Hub (cidade)
    │  escolher caçada / montar build
    ▼
  Viagem para a ilha (loading curto)
    │
    ▼
  Rastrear a fera ──► coletar recursos pelo caminho
    │
    ▼
  Combate (5–15 min) ──► quebrar partes, cortar cauda, ferir pontos
    │
    ▼
  Recompensas: partes da fera + materiais + moeda
    │
    ▼
  Hub: fabricar / melhorar arma, armadura, células
    │
    └──► fera mais forte (tier acima) ──► repete
```

- **Sessão média:** 5–15 min por caçada ✅ — perfeito para mobile.
- **Progressão em "degraus":** cada fera nova exige equipamento das feras anteriores.
- **Fantasia:** "eu sou o que eu caço" — sua armadura parece com a fera que você matou.

## 6. Combate e mecânicas de caça

### Controles e movimentação
- Terceira pessoa, ação em tempo real, **sem lock-on obrigatório** ✅
- **Esquiva (dodge)** com *i-frames* (frames de invencibilidade) que consome **stamina** ✅
- **Sprint** consome stamina ✅
- Ataque leve / pesado, combos, ataques carregados e **especiais de arma** ✅
- **Animation commitment**: ataques pesados te prendem na animação — o "jogo" é ler a fera e escolher a janela certa (herança de Monster Hunter) ✅

### Mecânicas da caçada
| Mecânica | Como funcionava |
|---|---|
| **Rastreamento** | Fera escondida na ilha; pistas/aether e flares para avisar o grupo ✅ |
| **Partes quebráveis** | Cabeça, chifres, garras, asas, costas; quebrar = loot extra e às vezes enfraquece um ataque ✅ |
| **Cortar cauda** | Só com armas de corte (espada, machado, lâminas, lança) ✅ |
| **Ferimento (wound)** | Acumular dano numa parte deixa ela "ferida": recebe **mais dano** dali em diante ✅ |
| **Stagger / Knockdown** | Armas de impacto (martelo, socos) acumulam "atordoamento" na cabeça; ao encher, a fera cai e fica vulnerável ✅ |
| **Enrage (fúria)** | Com pouca vida ou após certo tempo, a fera fica mais rápida/agressiva e ganha ataques novos ✅ |
| **Exaustão / fuga** | A fera foge para outra área da ilha para se recuperar ✅ |
| **Danger Meter** | Cada caçador derrubado enche um medidor coletivo; chegou a 100% = caçada falha ✅ |
| **Reviver aliados** | Caçador derrubado pode ser levantado por um aliado (canalizando no lugar) ✅ |
| **Cura** | Poções com cargas limitadas e reposição limitada; lanternas e omnicélulas de suporte ✅ |
| **Telegraphing** | Ataques da fera com sinais claros (postura, brilho, som) — essencial para combate justo ✅ |

### Ritmo de uma luta típica
1. Abertura: fera calma → grupo aplica dano em partes.
2. Primeira quebra de parte/ferimento → ciclo de "punir" e "esquivar".
3. ~50–30% de vida: **fúria** → fase nova.
4. Final: fera exausta → grupo finaliza.

## 7. Feras (Behemoths)

### Famílias (arquétipos)
O jogo organizava as feras em famílias com variantes elementais — um ótimo truque de produção: **um esqueleto/rig, várias feras**.

| Família / arquétipo | Exemplos | Ideia de design |
|---|---|---|
| Aves / feras aladas | **Shrike** (ave lendária), **Quillshot** (dispara espinhos) | Ataques aéreos, mergulhos, projéteis |
| Leão/felino flamejante | **Embermane** (fogo) | Agressivo, investidas |
| Rinocerontes/pedregosos | **Skarn** (terra), **Charrogg** | Tanques, armadura que quebra |
| Lagartos elétricos | **Drask**, **Stormclaw** | Áreas elétricas no chão |
| Feras de gelo | **Pangar**, **Boreus**, **Riftstalker** | Lentidão, terreno congelado |
| Tubarão de areia | **Gnasher** (cavador), variantes elementais | Mergulha no chão, ataques surpresa |
| Feras de fendas/teleporte | **Riftstalker** | Teleporte, padrões imprevisíveis |
| Feras "chefões" de ilha | **Thrax**, **Valomyr**, **Malkarion**, **Shrowd** | Mecânicas de arena, fases |
| Feras Umbral/Radiante | **Shrowd** (umbral), **Koshai**, **Rezakiri**, **Nayzaga**, **Kharabak**, **Torgadoro**, **Agarus**, **Urska**, **Hellion**, **Bloaz** | Endgame |

> Use os nomes só como referência de estudo — **não** use nomes, visuais ou lore do Dauntless no seu jogo. A classificação em famílias acima é aproximada ⚠️.

### Variações de dificuldade ⚠️
- **Normal → Dangerous → Heroic** (e versões **Heroic+**). Mesma fera, mais vida/dano e às vezes ataques novos.
- Feras **elementais variantes** (ex.: Gnasher → Gnasher de fogo/gelo/raio).
- Feras **Lendárias/Chefes de evento** com mecânicas únicas.

### Anatomia de design de uma fera (checklist útil)
1. **Silhueta legível** a distância (essencial em tela pequena!).
2. **3–5 ataques básicos** + **2–3 ataques de fúria**.
3. **Partes quebráveis** (2–4) com recompensas diferentes.
4. **Elemento** (ataque) + **fraqueza** (defesa).
5. **Comportamento de fuga** e **ponto fraco**.
6. **Tema de recompensa**: a armadura/arma "carrega" a identidade da fera (perk temático).

## 8. Sistema elemental

### Elementos ✅
**Fogo (Blaze), Gelo (Frost), Raio (Shock), Terra (Terra), Radiante (Radiant), Umbral (Umbral)** e **Neutro** (removido no Awakening).

### Ciclo de vantagens ✅
```
Fogo ──► Gelo ──► Raio ──► Terra ──► Fogo        (cada um é forte contra o próximo)

Radiante ◄──► Umbral                            (fortes um contra o outro)
```

### Regras
- Arma de elemento **forte** contra a fera → bônus de dano.
- Armadura de elemento **forte contra o ataque** da fera → resistência; **fraco** → vulnerabilidade.
- Isso força o jogador a ter **várias builds** (uma por elemento) — principal motor de "farm" e de tempo de jogo.

## 9. "Classes": armas, Omnicélulas e papéis

**Dauntless não tinha classes fixas.** A "classe" era a combinação **arma + Omnicélula + build**. Você trocava tudo livremente no hub.

### Armas ✅ (7 tipos)
| Arma | Estilo | Papel | Recurso especial |
|---|---|---|---|
| **Espada (Sword)** | Rápida e versátil | DPS equilibrado | Medidor que libera modo/golpe especial; corta cauda |
| **Machado (Axe)** | Lento, golpes carregados | DPS pesado | Ataques carregados enormes; corta |
| **Martelo (Hammer)** | Impacto + "tiros" de éter | Stagger / atordoar | Munição: disparos que também impulsionam o jogador |
| **Lança de guerra (War Pike)** | Alcance médio, estocadas + disparos | DPS/ferimento | Ferimento rápido de partes; modo de tiro |
| **Lâminas de corrente (Chain Blades)** | Muito rápido, aéreo | DPS agressivo/mobilidade | Puxar-se até a fera; combos no ar |
| **Socos de éter (Aether Strikers)** | Corpo a corpo, combos | Stagger + DPS | Medidor de "momentum" que fortalece combos |
| **Repetidoras (Repeaters)** | Pistolas duplas à distância | DPS à distância | **Modulares**: cano, câmara, empunhadura e prisma montados separadamente |

Cada arma tinha **Especiais** e **Passivas** selecionáveis (após 2020), dando 2–3 "subestilos" por arma ⚠️.

### Omnicélulas (o mais próximo de uma "classe") ✅ ⚠️
Item equipado que define seu **papel** com uma **habilidade ativa (ultimate)** e **passivas**:

| Omnicélula | Papel |
|---|---|
| **Bastion** | Tanque/defesa — escudos, reduzir dano |
| **Artificer** | Suporte — cura e utilidade para o grupo |
| **Conduit** | Dano elemental / em cadeia |
| **Discipline** | Precisão/cortes — dano físico consistente |
| **Iceborne** | Sobrevivência por sangue/vida — tanquear com cura |
| **Revenant** | Alto risco, alta recompensa — dano custando vida |
| **Tempest** | Velocidade, mobilidade e esquiva |

### Papéis no grupo (emergentes)
- **DPS** (maioria), **Tanque** (Bastion/Iceborne), **Suporte** (Artificer + lanternas de suporte), **Controle/Stagger** (martelo/socos).
- O jogo **não obrigava** composição — qualquer grupo de 4 podia ganhar. Bom para matchmaking aleatório.

## 10. Armaduras, lanternas e células (perks)

### Loadout completo ✅
```
Arma  +  Capacete  +  Peitoral  +  Manoplas  +  Botas  +  Lanterna  +  Omnicélula
  │        │            │            │           │
  └── cada peça tem: perk inato da fera + 1 ou 2 slots de célula
```

### Armaduras
- **4 peças**: cabeça, torso, braços, pernas ✅
- Cada peça vem de uma fera e tem: **defesa**, **elemento** (resistência/fraqueza) e um **perk inato** temático ✅
- Bônus por **conjunto completo** não era o foco; o foco era **somar perks** ⚠️

### Lanternas ✅
Item de utilidade com 2 usos: **toque** (efeito instantâneo) e **segurar** (efeito contínuo). Cada lanterna veio de uma fera. Exemplos de tipos: buff de dano, cura em área, escudo, dano extra.

### Células e Perks ✅ ⚠️
- **Perks** são bônus passivos (ex.: +dano crítico, +stamina, esquiva melhor, cura ao acertar, dano aumentado com vida cheia).
- Fontes de perks: armas, armaduras (inato) e **células** encaixadas em slots.
- **Tipos de slot/célula**: **Poder (Power), Técnica (Technique), Defesa (Defence), Mobilidade (Mobility), Utilidade (Utility)** ✅
- Cada célula tinha nível (+1 a +3) e **perks somavam até +6**; certos níveis destravavam efeitos maiores (thresholds) ⚠️
- Células eram obtidas em caçadas, por moedas ou em "bolsas" (cell bags), o que gerou debate sobre aleatoriedade ⚠️

**Exemplos de perks (arquétipos):**
| Categoria | Exemplo de efeito |
|---|---|
| Poder | +dano com vida cheia; +dano em partes feridas; +dano após esquiva perfeita |
| Técnica | +chance crítica; +recarga do especial; +dano de ferimento |
| Defesa | +vida; redução de dano ao bloquear; cura ao usar poção |
| Mobilidade | esquiva mais longa; menos stamina por esquiva; corrida mais rápida |
| Utilidade | lanterna recarrega mais rápido; reviver aliados mais rápido; bônus ao grupo |

## 11. Builds

A build é a **escolha combinada** de: arma (tipo + elemento), 4 peças de armadura (perks + resistência), células nos slots, lanterna e omnicélula.

### Arquétipos de build mais usados ⚠️
| Arquétipo | Como montava | Ponto fraco |
|---|---|---|
| **Crítico/Rage** | Perks de chance e dano crítico + dano condicional | Exige posicionamento |
| **"Glass cannon" Revenant** | Revenant + perks que convertem vida em dano | Morre fácil |
| **Tanque Bastion** | Defesa + escudos + aggro | Dano baixo |
| **Suporte Artificer** | Cura + lanterna de cura + utilidade | Solo fraco |
| **Elemental** | Arma do elemento fraco da fera + perks elementais | Precisa de uma build por elemento |
| **Esquiva/Tempest** | Mobilidade, esquiva perfeita, stamina | Curva de habilidade alta |

### Problema clássico
A comunidade convergia para **2–3 builds "meta"** por arma, porque alguns perks (dano bruto) eram muito superiores. **Para o seu jogo:** balancear perks por **situação** (condicionais) e não por números brutos, e trocar o meta via **modificadores sazonais**.

## 12. Dano: como funcionava

O jogo nunca publicou a fórmula exata, mas a comunidade mapeou os componentes ⚠️:

```
Dano final ≈ PoderBase_da_Arma
            × MultiplicadorDoGolpe        (cada ataque tem um valor/peso)
            × (1 + BônusDePerks)          (perks de poder, condicionais)
            × MultiplicadorCrítico        (se crítico)
            × MultiplicadorElemental      (forte/neutro/fraco vs. a fera)
            × MultiplicadorDaParte        (parte ferida/ponto fraco recebe mais)
            − (Defesa da fera, em %)
```

### Tipos de dano/efeito por golpe ✅
| Tipo | O que faz |
|---|---|
| **Dano bruto** | Reduz a vida da fera |
| **Dano em parte** | Acumula para quebrar uma parte específica |
| **Ferimento** | Deixa a parte vulnerável (+dano recebido) |
| **Stagger/atordoamento** | Acumula para derrubar a fera (martelo/socos) |
| **Dano elemental** | Multiplicado conforme o ciclo de elementos |
| **Corte vs. impacto** | Corte corta cauda; impacto atordoa melhor |

### Do lado do jogador
- Defesa da armadura reduz dano recebido; resistência elemental reduz dano do elemento.
- **i-frames** na esquiva anulam o golpe por completo (habilidade > números).
- Fúria da fera aumenta o dano dela.

## 13. Coleta, fabricação e upgrade

### Coleta ✅
- **Durante a caçada**: plantas, minérios, veios de éter, pequenos animais e baús espalhados pelas ilhas.
- **Partes da fera** ao final (e extras por partes quebradas/cauda cortada).
- **Raridade das partes** (comum → incomum → raro → épico) ⚠️; partes raras davam acesso a itens melhores.
- **Usos dos coletáveis**: poções, consumíveis (bombas/flares), materiais de upgrade.

### Fabricação ✅
- **Ferreiro no hub (Foundry/Forja)**: recipes = partes da fera + materiais coletados + moeda (Rams).
- Cada fera desbloqueava uma **árvore de armas** (uma por tipo de arma) e **4 peças de armadura** + lanterna.
- Fabricação **determinística** (sem chance de falha) — muito elogiado.

### Upgrade (pré-Awakening) ⚠️
- Armas e armaduras tinham níveis de melhoria (+1 até +10/+15, variando por era).
- Cada nível pedia **mais partes da mesma fera** + materiais genéricos de upgrade (ex.: Aetherdust/fragmentos) + Rams.
- Níveis altos davam acesso a slots de célula melhores ou perks mais fortes.
- Na era **Reforged** (2020), o sistema passou para **"tiers"** de poder alinhados com a dificuldade das ilhas.
- **Awakening** substituiu tudo por um sistema novo de armas genéricas e removeu as moedas antigas — o motivo principal da revolta.

### Economia (moedas) ✅
| Moeda | Uso |
|---|---|
| **Rams** | Moeda comum — fabricar, melhorar, lojas |
| **Platinum** | Moeda premium (dinheiro real) — cosméticos, Hunt Pass |
| Moedas de endgame (Aetherdust, Aethersparks, Aetherhearts, Chronostones, Cache Coins) | Upgrades, células, recompensas de modos — removidas no Awakening |

## 14. Níveis e progressão

Dauntless tinha **várias camadas de progressão paralelas** ✅ ⚠️:

| Camada | O que é |
|---|---|
| **Progressão de equipamento** | A principal: o seu "nível" real é o poder da sua build |
| **Slayer Level / Mastery** | Nível de conta via XP; recompensas por dominar armas e feras (matar X vezes, quebrar partes, etc.) |
| **Maestria de arma** | Progressão por tipo de arma (desbloqueia especiais/cosméticos) |
| **Maestria de fera/ilha** | Objetivos por fera/ilha (Reforged) |
| **Hunt Pass** | Passe de temporada (trilha grátis + premium) |
| **Escada de dificuldade** | Normal → Dangerous → Heroic → Heroic+; tiers de ilha |

> Não havia atributos de personagem (força/agilidade). **O personagem é o equipamento.** Isso simplifica muito o balanceamento — recomendável manter.

## 15. Modos de jogo e endgame

| Modo | Descrição |
|---|---|
| **Caçada / Patrulha** | Escolhe uma fera ou uma ilha e vai caçar (solo ou matchmaking) ✅ |
| **Escalations** | Sequência de caçadas em camadas com modificadores, culminando num chefe; recompensas exclusivas ✅ |
| **Trials** | Fera fixa, contra o tempo, ranking semanal ✅ |
| **Gauntlet** | Sequência de feras em tempo limitado, ranking sazonal ✅ |
| **Hunting Grounds** | Ilha aberta com várias feras e eventos (Reforged) ✅ |
| **Eventos sazonais** | Feras/cosméticos temporários (Halloween, inverno, etc.) ✅ |

## 16. Monetização

- **Free-to-play** com foco em **cosméticos**: skins de arma/armadura, tinturas, emotes, efeitos ✅
- **Hunt Pass** (passe de batalha) ✅
- **Platinum** (moeda premium) ✅
- Não era considerado pay-to-win; críticas pontuais a "boosts"/aceleradores e células aleatórias ⚠️

---

## 17. Lições

### ✅ O que funcionou (manter)
1. Loop **fera → partes → equipamento temático**.
2. **Sessões curtas** (5–15 min) e **ilhas instanciadas**.
3. **Sem classes fixas**: troca livre de arma = muita rejogabilidade.
4. **Estilo visual estilizado** — envelhece bem e roda em hardware fraco.
5. **Cross-play/cross-save**.
6. **Telegraphing claro** dos ataques — combate justo.
7. **F2P com cosméticos** e fabricação determinística.

### ❌ O que não funcionou (evitar)
1. Mudar radicalmente o loop central e **resetar progressão**.
2. Endgame raso; **meta de builds** estreito.
3. História fraca.
4. Dependência total de servidor (jogo morreu junto).
5. Moedas demais e confusas.

---

# PARTE 2 — PROPOSTA: VERSÃO MOBILE

## 18. Proposta: versão mobile

> Nome provisório: **"Caçadores do Éter"** (troque à vontade). Tudo aqui é **original** — inspirado no gênero, sem copiar nomes, arte ou lore protegidos.

### 18.1 Pilares de design
1. **"Você é o que você caça."** Toda fera gera equipamento com identidade visual e perk temático.
2. **Caçadas de 3–8 minutos.** Jogável no ônibus.
3. **Combate de habilidade com controles de toque justos.** Esquiva com i-frames continua sendo o coração.
4. **Co-op de 4 (ou solo com companheiros IA).**
5. **Progressão que nunca é apagada.**
6. **Funciona offline no modo solo** (o progresso sincroniza quando online).

### 18.2 Tecnologia recomendada

| Camada | Recomendação | Alternativas | Por quê |
|---|---|---|---|
| **Motor** | **Unity 6 (URP)** | Unreal 5 (mobile), Godot 4 | Ecossistema mobile maduro, builds leves, muitos assets, C#. Unreal é ótimo, mas pesado para mid-range Android |
| **Linguagem** | C# | — | — |
| **Arte** | Estilizada low/mid-poly + toon shader, texturas 512–1024 | — | Performance + identidade |
| **Animação** | Animator + *root motion* para ataques; *animation events* para hitboxes | — | Precisão de combate |
| **Rede (co-op)** | **Photon Fusion 2** (host/servidor) ou **Unity Netcode for GameObjects** + **Unity Relay/Multiplay** | Mirror/FishNet + servidor dedicado | Fusion tem predição/rollback pronto, ideal para ação |
| **Backend (contas, inventário, economia)** | **Nakama** (open source, self-host) ou **PlayFab** | Firebase, Supabase (só para dados não-tempo-real) | Inventário, economia, leaderboards, matchmaking, validação server-side |
| **Autenticação** | Login de convidado + Google Play Games / Game Center + vínculo de conta | — | Cross-save |
| **Dados de design** | ScriptableObjects + planilhas (Google Sheets → JSON) | — | Designers balanceiam sem programar |
| **Live ops** | Remote Config + eventos por calendário no backend | — | Temporadas sem update de loja |
| **Analytics** | Unity Analytics / GameAnalytics / Firebase | — | Funil, retenção, balanceamento |
| **Anti-cheat** | Validação de loot e crafting **no servidor**; cliente só pede | — | Inventário nunca confiável no cliente |
| **Performance-alvo** | 30 fps estáveis (60 opcional) em Android mid-range de ~3 anos; < 2 GB RAM; download inicial < 300 MB + pacotes sob demanda (Addressables) | — | Alcance de público |

> **Decisão atual:** o jogo é feito na **Godot 4** (renderizador Mobile, GDScript), com câmera em terceira pessoa estilo Dauntless. O primeiro protótipo em TypeScript + Three.js ficou em `prototipo-web/` como referência.

### 18.3 Controles de toque

```
 ┌─────────────────────────────────────────────┐
 │ [vida/stamina]           [mapa] [pausa]     │
 │                                             │
 │                                  [Especial] │
 │                         [Lanterna] [Ult]    │
 │  ( joystick )                               │
 │  ( virtual  )            [Pesado]           │
 │                     [Leve]     [ESQUIVA]    │
 │ [poção]                                     │
 └─────────────────────────────────────────────┘
```
- **Joystick virtual** à esquerda; câmera com arrastar na metade direita.
- **Mira assistida/soft lock** (alvo na fera ou na parte mais próxima, com botão para trocar de parte).
- **Esquiva** = botão grande. Esquiva perfeita (no último instante) → câmera lenta curta + bônus.
- **Toque = leve; segurar = carregado.** Combos por sequência/ritmo, não por comandos complexos.
- Suporte a **controle Bluetooth**.
- Feedback forte: vibração (haptics), *hit-stop*, sons e números de dano opcionais.

### 18.4 Mundo (original)
- **Premissa sugerida:** um mundo de **ilhas flutuantes** não é obrigatório; para se diferenciar, considere algo como "**arquipélago tropical brasileiro mítico**" ou "**cordilheira / montanhas**" (o repositório se chama *suba-monte* — "subir o monte" pode virar o tema: uma montanha gigante onde cada altitude é um bioma e cada fera é guardiã de um patamar).
- **Hub:** acampamento-base na base da montanha que evolui visualmente conforme você progride.
- **Biomas por altitude:** floresta úmida → cânions → vulcão → campos de neve → pico tempestuoso.
- **Feras inspiradas em folclore** (opção de identidade forte e original): ex. uma onça de fogo, uma serpente-rio, um tatu-titã de pedra, uma ave-trovão, um lobo de neve.

### 18.5 Feras — modelo de dados
```json
{
  "id": "onca_brasa",
  "nome": "Onça-Brasa",
  "familia": "felino",
  "tier": 2,
  "elemento_ataque": "fogo",
  "fraqueza": "gelo",
  "vida_base": 12000,
  "fases": [
    { "limiar_vida": 1.0, "ataques": ["investida", "patada", "rugido"] },
    { "limiar_vida": 0.4, "furia": true, "ataques": ["investida_tripla", "explosao_brasa"] }
  ],
  "partes": [
    { "id": "cabeca", "vida_parte": 1800, "quebravel": true, "multiplicador_dano": 1.2, "drop_extra": "presa_brasa" },
    { "id": "cauda", "vida_parte": 1200, "cortavel": true, "drop_extra": "cauda_brasa" },
    { "id": "costas", "vida_parte": 2000, "quebravel": true, "drop_extra": "placa_brasa" }
  ],
  "stagger_limite": 900,
  "loot": [
    { "item": "couro_brasa", "chance": 1.0, "qtd": [2, 3] },
    { "item": "garra_brasa", "chance": 0.6, "qtd": [1, 2] },
    { "item": "coracao_brasa", "chance": 0.05, "qtd": [1, 1] }
  ]
}
```

**Plano de conteúdo do MVP:** 8 feras em 3 famílias (reaproveitando esqueletos) + 1 chefe final de temporada.

| Tier | Feras | Papel |
|---|---|---|
| 1 | 2 feras tutorial | Ensinar esquiva, partes, elementos |
| 2 | 3 feras | Introduzir fúria, cortar cauda, stagger |
| 3 | 2 feras | Elementos combinados, ataques em área |
| Chefe | 1 | Duas fases, mecânica de arena |

### 18.6 Elementos
Manter um ciclo simples e legível em tela pequena:
```
Fogo ► Natureza ► Água ► Fogo        (triângulo básico)
Luz ◄► Sombra                         (par endgame)
```
- Forte: **×1,5** · Neutro: **×1,0** · Fraco: **×0,75** (sugestão; ajustar em playtest).
- Ícones e cores **sempre visíveis** na tela da fera e do item.

### 18.7 "Classes" — armas como classes
Seguir o modelo Dauntless (sem classe fixa; a arma define o estilo). MVP com **4 armas**, expandindo depois:

| Arma (MVP) | Estilo | Força | Corte/Impacto |
|---|---|---|---|
| Espada e escudo / Espada longa | Equilibrada | Fácil de aprender, bloqueio | Corte |
| Martelo | Lento, atordoa | Stagger/knockdown | Impacto |
| Lança | Alcance, estocadas | Ferir partes rápido | Corte (perfura) |
| Arco ou pistolas | Distância | Segurança, partes altas | — |
| *Depois:* lâminas duplas, manoplas, machado | — | — | — |

**Núcleos (equivalente às Omnicélulas)** — definem o papel no grupo:
| Núcleo | Ativa (ultimate) | Passiva |
|---|---|---|
| Guardião | Escudo para o grupo | +defesa, atrai a fera |
| Curandeiro | Cura em área | +eficácia de poções/aliados |
| Fúria | +dano por 10 s ao custo de vida | +dano com vida baixa |
| Vento | Esquivas ilimitadas por 8 s | Esquiva perfeita mais fácil |
| Elementalista | Explosão do elemento da arma | +dano elemental |

### 18.8 Equipamento e builds
```
Arma + Capacete + Peitoral + Braços + Pernas + Amuleto (lanterna) + Núcleo
```
- Cada peça: **defesa**, **resistência elemental**, **1 perk inato** e **1 slot de gema** (célula).
- **Gemas (células)** em 4 tipos: Ataque, Técnica, Defesa, Utilidade. Nível 1–3; perk soma até **5**, com efeito extra em 3 e 5.
- **Bônus de conjunto** opcional (2 e 4 peças da mesma fera) → dá identidade sem obrigar.
- **Presets de build** (salvar 5 loadouts) e botão **"build recomendada para esta fera"** — essencial em mobile.

**Exemplos de perks com design condicional (evitam meta único):**
| Perk | Efeito | Condição |
|---|---|---|
| Caçador Paciente | +20% dano | Após 3 s sem tomar dano |
| Quebra-Ossos | +30% dano em partes | Parte já ferida |
| Último Fôlego | +25% dano | Vida < 30% |
| Esquiva Afiada | Próximo golpe crítico | Após esquiva perfeita |
| Pele de Brasa | −20% dano de fogo | Sempre |
| Mãos Rápidas | Poções 40% mais rápidas | Sempre |

### 18.9 Fórmula de dano (proposta)
```
dano = base_arma
     × mult_golpe                  // leve 1.0, pesado 1.8, carregado 2.5, especial 3.0
     × (1 + soma_bônus_perks)      // aditivos entre si, limitados a +100%
     × (crit ? 1.5 : 1.0)          // chance base 5%
     × mult_elemento               // 1.5 / 1.0 / 0.75
     × mult_parte                  // normal 1.0, ferida 1.3, ponto fraco 1.5
     × (1 − defesa_fera)           // 0–40%

dano_parte = dano × fator_parte_arma      // corte 1.0, impacto 0.8
stagger    = valor_stagger_golpe × fator  // impacto 1.5, corte 0.5 (só cabeça)
```
- Calcular dano **no host/servidor** e replicar.
- Dano recebido: `dano_fera × mult_golpe_fera × (1 − defesa_jogador) × mult_resist_elemental`.
- Tabelas em planilha → JSON, para balancear sem recompilar.

### 18.10 Coleta, fabricação e upgrade
**Coleta**
- Nós de coleta na ilha (plantas, minério, ninhos) com toque rápido (1 s) — sem minigame.
- Coleta **automática** de drops ao passar por cima.
- Fim da caçada: partes base + extras por **partes quebradas/cauda** + bônus de primeira vitória diária.

**Fabricação (determinística, sem chance de falha)**
```
Arma "Garra de Brasa" (Tier 2):
  3× couro_brasa + 2× garra_brasa + 5× minério_ferro + 800 moedas
```
- Árvore por fera: 1 arma de cada tipo + 4 armaduras + 1 amuleto.
- Mostrar **"onde conseguir"** em todo material faltante (botão que leva à caçada certa).

**Upgrade**
- Níveis **+0 → +10** por item. Custos crescem ~×1,35 por nível.
- +1 a +5: materiais da própria fera + materiais comuns.
- +6 a +10: materiais raros da fera (ex.: coração) + material de tier.
- **Ascensão** (ao chegar em +10): sobe um tier, ganha slot extra/perk mais forte — permite usar sua arma favorita no endgame (corrige um problema do Dauntless).
- **Nunca** cobrar dinheiro real por upgrade de poder; aceleradores, se houver, só de tempo e com limite.

### 18.11 Níveis e progressão
| Camada | Função |
|---|---|
| **Rank de Caçador (RC)** | Nível de conta; desbloqueia tiers de feras e modos |
| **Poder do equipamento** | O "nível real"; cada caçada recomenda um poder mínimo |
| **Maestria de arma** | Desbloqueia combos/especiais extras e cosméticos |
| **Bestiário** | Completar objetivos por fera (quebrar todas as partes, vencer sem morrer) → títulos, gemas |
| **Passe de temporada** | Trilha grátis generosa + premium cosmética |

Curva de XP sugerida: `xp_para_nível(n) = 100 × n^1.6` (ajustar em telemetria).

### 18.12 Modos
| Modo | Fase |
|---|---|
| Campanha solo com companheiros IA (offline) | MVP |
| Caçada co-op 2–4 (matchmaking + sala com amigos por código) | MVP |
| Caçadas diárias com modificadores | MVP |
| Escalada (sequência de feras subindo a montanha, estilo Escalations) | v1.1 |
| Contra o tempo semanal (ranking) | v1.1 |
| Chefe de raide sazonal | v1.2 |

### 18.13 Monetização ética
- **Grátis para jogar**, **cosmética** (skins, tinturas, efeitos de arma, emotes, acampamento).
- **Passe de temporada** + **assinatura** opcional (conveniências não competitivas).
- **Sem loot boxes pagas**, sem venda de poder. Isso vira marketing ("sem pay-to-win").

### 18.14 Roadmap sugerido

| Fase | Duração | Entrega |
|---|---|---|
| **0. Pré-produção** | 1–2 meses | Documento de design, arte conceitual, protótipo cinza de **1 arma vs. 1 fera** em celular real |
| **1. Vertical slice** | 3–4 meses | 2 armas, 3 feras, crafting básico, hub simples, solo offline |
| **2. Alpha** | 4–6 meses | 4 armas, 8 feras, co-op 4, backend, build/gemas, upgrade |
| **3. Beta fechado** | 2–3 meses | Balanceamento por telemetria, onboarding, performance em aparelhos fracos |
| **4. Soft launch** | 2–3 meses | 1–2 países (ex.: Brasil + outro), métricas de retenção D1/D7/D30 |
| **5. Lançamento global** | — | Temporada 1 |

**Primeiro passo prático:** o protótipo "1 arma × 1 fera" num Android médio. Se esquivar e acertar a fera for divertido no toque em 5 minutos, o resto do jogo tem base. Se não for, nenhum sistema de crafting salva.

### 18.15 Cuidados legais
- "Dauntless" e "Monster Hunter" são marcas registradas; **não use** os nomes, logos, feras, arte, sons ou textos.
- **Mecânicas de jogo não têm proteção de direitos autorais** (esquiva, crafting com partes, elementos) — inspirar-se no gênero é legítimo.
- Crie nomes, visuais e mundo próprios; registre sua marca.

### 18.16 Concorrentes no mobile (pesquisar antes de lançar)
- **Monster Hunter Now** (Niantic/Capcom, AR, 2023) — caçada rápida com localização.
- **Monster Hunter Outlanders** (Capcom + TiMi, mundo aberto mobile, anunciado em 2024) ⚠️ verificar status atual.
- **Monster Hunter Stories** (por turnos), além de diversos "hunting games" chineses.
- Espaço livre: um hunting game **cooperativo, de sessões curtas, com estilo estilizado e monetização justa** — exatamente o que o Dauntless era e que hoje não existe no celular.

---

## 19. Fontes

- [Dauntless (video game) — Wikipedia](https://en.wikipedia.org/wiki/Dauntless_(video_game))
- [Inverse — Dauntless is shutting down two years after dev's controversial acquisition](https://inverse.com/gaming/dauntless-monster-hunter-free-to-play-shut-down-phoenix-labs-blockchain)
- [GoNintendo — Dauntless to shut down May 29th, 2025](https://gonintendo.com/contents/45759-dauntless-to-shut-down-may-29th-2025)
- [Pocket Tactics — Dauntless faces shutdown after underwhelming update](https://www.pockettactics.com/dauntless/shut-down)
- [Checkpoint Gaming — Dauntless no longer receiving support](https://checkpointgaming.net/news/2025/02/dauntless-no-longer-receiving-support-will-go-offline-later-this-year)
- [GoNintendo — Devs apologize for Awakening, share roadmap](https://gonintendo.com/contents/43923-dauntless-devs-apologize-for-missing-the-mark-with-latest-update-share-roadmap-of)
- [GosuGamers — Dauntless launches on Steam with overwhelmingly negative reviews](https://gosugamers.net/entertainment/news/73960-dauntless-launches-on-steam-with-overwhelmingly-negative-reviews-due-to-controversial-updates)
- [SteamDB — notas do patch Awakening](https://steamdb.info/patchnotes/16646813)
- [Dauntless Wiki (Fandom) — Aetherhearts](https://dauntless.fandom.com/wiki/Aetherhearts) — a wiki da Fandom é a melhor fonte para dados detalhados de feras, perks e armas de cada era.

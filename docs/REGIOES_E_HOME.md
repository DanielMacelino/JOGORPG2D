# Achados regionais, fases e página inicial

## Equipamentos

As seis regiões têm dez equipamentos próprios: quatro acessórios compartilhados e uma arma para cada classe. O chefe sorteia entre os cinco itens compatíveis com o personagem, priorizando descobertas. A fase 10 aumenta o peso dos épicos e entrega dois cristais. Itens repetidos viram mais 100 de ouro; não são equipados automaticamente.

| Região | Efeito dos sinetes e talismãs |
|---|---|
| Ermos de Vespera | Retaliação aos inimigos próximos |
| Colina Oca | Flechas ricocheteiam, conservando 80% do dano por salto |
| Cratera Rubra | Queimadura por três segundos |
| Castelo Sem Aurora | Chance de crítico adicional |
| Bosque da Geada | Lentidão ao acertar |
| Charco Esquecido | Mais duração e dano das invocações |

As armas reforçam a identidade da classe: vida e defesa para o Sentinela, explosões maiores para a Tecelã, ricochetes para a Batedora, alvos e críticos para a Lâmina, invocações para o Guardião e ataque/defesa para o Arauto. Efeitos de peças diferentes se somam. O inventário informa a origem de cada achado. Os equipamentos regionais são obtidos por vitória; as escolhas de nível continuam desbloqueando os equipamentos anteriores.

## Dez fases por região

| Fase | Nome | Encontro |
|---|---|---|
| 1 | Limiar | Sobrevivência e chefe |
| 2 | Maré da noite | Hordas adicionais |
| 3 | Caçada aos marcados | Três elites marcados e chefe |
| 4 | Altar da vigília | Defesa do altar contra invasores |
| 5 | Fendas antigas | Selar três fendas permanecendo nos círculos |
| 6 | Conselho dos elites | Cinco elites marcados e chefe |
| 7 | Último bastião | Defesa do altar com invasões maiores e mais frequentes |
| 8 | Tempestade arcana | Áreas perigosas durante as ondas |
| 9 | Cerco dos campeões | Quatro elites marcados e hordas adicionais |
| 10 | Trono da dimensão | Campeões e soberano; força regional aumentada |

Os invasores atacam o altar de verdade; sua destruição causa derrota. A provocação do Sentinela pode interromper a aproximação deles. Selar uma fenda exige 1,6 segundo dentro da área, com progresso acumulado, e concede experiência. A vitória e o drop do chefe ficam pendentes até concluir a caçada ou selar as fendas. Matar o chefe antes disso não pula o objetivo. A seleção de fases e a HUD mostram as instruções.

## Chefes

| Chefe | Ataques próprios |
|---|---|
| Rei do Espinheiro | Corte em linha e explosões laterais |
| Guardião do Ossuário | Anel com centro seguro e leques espectrais |
| Coração da Caldeira | Erupções persistentes e anel de fogo |
| Rei Sem Aurora | Corte de sangue em linha e leques rubros |
| Ancião do Inverno | Cruz de gelo e leques amplos |
| Rainha do Charco | Esporos persistentes e anel com centro seguro |

Abaixo de 50% de vida, cada chefe entra em Fúria: ataques mais frequentes, mais dano e, conforme o padrão, mais projéteis ou áreas. Os ataques são sinalizados antes de acertar. Linhas, anéis, círculos e leques têm geometria e dano próprios.

## Home

A página inicial segue a referência enviada: floresta noturna, portal à direita, título e ações à esquerda, moedas no topo, identidade do personagem e cinco cartões na base. As informações vêm do save. Preparar personagem reúne classes, arsenal, talentos, melhorias, forja e relíquias. Registros reúne bestiário, conquistas, caçadas e estatísticas. Jogar online e Configurações formam uma linha de botões com ícones e alturas iguais, abaixo das ações principais.

A arte está em [home-portal.png](../assets/art/home-portal.png); a composição é feita em `scripts/ui/menu/home_screen.gd`. Textos e botões são controles do Godot, separados da pintura. Os botões principais ficam alinhados e próximos, e os dados do personagem ficam agrupados. Os cartões se reorganizam em uma, duas, três ou cinco colunas conforme a largura disponível; a página permite rolagem quando necessário. As alturas acompanham o conteúdo, sem reservar espaços vazios. O fundo e os recortes dos cartões preservam suas proporções.

## Arte e prompt

Foi usada a ferramenta integrada `image_gen`, com a imagem enviada como referência. O resultado foi copiado para o projeto e o original permaneceu na pasta de geração do Codex. Não foram feitas capturas de tela do jogo.

Prompt usado:

> Use case: stylized-concept. Asset type: 16:9 widescreen background illustration for the home screen of the dark fantasy game Ashenwild. Reference: the most recent user-attached home screen image, composition and atmosphere only. Generate only the background painting, no interface, no typography, no words, no buttons, no panels. Match the reference closely: misty moonlit pine forest and ruined gothic arches, a small cloaked adventurer seen from behind at approximately 64% width, standing on mossy rocks facing a tall weathered stone portal at 80% width, portal glowing with restrained amber-gold light, crescent moon high on the right, dark overhanging branches framing the top and foreground. Entire left 40% must stay very dark and quiet with usable negative space for live menu text. Palette deep forest greens and charcoal, weathered stone, warm gold glow; cinematic painterly illustration with natural texture, disciplined details, atmospheric perspective. Portal and character clearly legible but no oversaturated bloom. Canvas landscape 1920x1080 or similar 16:9. No HUD, icons, writing, watermark, logos.

## Validação

`tests/regional_features.gd` verifica os 60 itens e os sorteios de todas as regiões/classes, ricochetes com dano real, queimadura, lentidão, duração das invocações, persistência, objetivos e bloqueio de recompensas, ataques e segunda etapa dos seis chefes, além dos botões e dimensões da home em oito resoluções e texto a 100%/120%. Também verifica alinhamento e distância entre os botões, altura dos grupos e reorganização dos cartões. Execute pelo harness com save separado: `powershell -ExecutionPolicy Bypass -File tests/run_regression.ps1 -Combat`.

A regressão e a rodada de 12 amostras terminaram sem erros ou avisos: seis derrotas com personagens parados e seis vitórias em movimento na primeira fase. Os objetivos das demais modalidades foram verificados pelos testes de integração. O encerramento do harness aguarda o mixer de áudio liberar seus buffers.

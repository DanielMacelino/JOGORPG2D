# Inventário, maestria e soberanos

O Arsenal mostra os itens em uma grade de ícones, com filtro por espaço e paginação sem rolagem. Clique para equipar e passe o mouse para consultar nome, raridade, atributos, origem e poder. A borda verde e a marca de seleção identificam itens equipados. A ordem é decrescente pela pontuação calculada em `EquipmentData.power_score()`, incluindo atributos e efeitos; essa pontuação serve para ordenar e não substitui a comparação de builds.

## Melhorias permanentes

Cada personagem tem oito atributos com sete patamares individuais. Cada atributo recebe dez compras por patamar; os outros sete precisam concluir seus passos antes do próximo patamar. As compras universais anteriores são reiniciadas e o ouro é reembolsado uma vez. Veja `PERSONAGENS_E_NATUREZA.md` para a migração.

| Patamar | Bônus de cada compra | Bônus acumulado ao completar o atributo |
| --- | --- | --- |
| Aprendiz | 0,02% | 0,2% |
| Iniciado | 0,03% | 0,5% |
| Veterano | 0,05% | 1% |
| Mestre | 0,07% | 1,7% |
| Ascendente | 0,10% | 2,7% |
| Semideus | 0,15% | 4,2% |
| Divino | 0,20% | 6,2% |

São 560 compras no total. Preços começam menores e crescem com o patamar e os passos locais. O save calcula o preço real e valida o bloqueio coletivo. Resistência e chance de crítico aplicam o ganho sobre o percentual restante, com retornos decrescentes. Toda compra continua útil, sem chegar à imunidade ou garantir críticos apenas pelas melhorias. A interface mostra o ganho efetivo acumulado. Memória Ancestral aumenta somente XP; Fortuna aumenta ouro e XP. Vida e dano percentuais também consideram os equipamentos.

## Três poderes por expedição

`AbilityData.active_power` distingue ataques, auras e magias de modificadores de atributos. O jogador pode aprender três poderes ativos diferentes. Depois disso, o sorteio oferece upgrades dos poderes escolhidos e passivos, incluindo novos passivos. O poder inicial da classe fica fora dos três espaços e pode ser aprimorado. As habilidades mantêm o limite de cinco ranks; habilidades maximizadas deixam o sorteio. Enquanto existe um poder elegível, uma das cartas oferece um poder ou seu upgrade. Os outros espaços usam o sorteio ponderado. A validação de compra e a geração de cartas aplicam a mesma regra no solo e no servidor online.

## Soberanos da fase 10

Cada região usa sua versão Soberano do chefe original. Além da dificuldade da fase, o chefe recebe 2,8 vezes a vida, 30% mais dano e 8% mais velocidade. Cada soberano acrescenta um padrão regional: pinças, anéis espectrais, fissuras de lava, cortes cruzados, prisão de gelo ou esporos persistentes. Aos 50% de vida acelera; aos 25% entra em fúria final, com cadência maior e uma salva extra. Ataques extras continuam sinalizados por pelo menos 1,35 segundo. As escoltas aumentam sem remover o teto de 144 inimigos. A fase rende 65% a mais que seu multiplicador normal.

## Validação

`tests/inventory_mastery_powers.gd` cobre as 560 compras, bloqueios, custo, persistência e efeito real dos atributos; limite de poderes, passivos e sorteios; seis soberanos e suas fúrias; ícones, ordenação, detalhes e equipamento. A regressão geral também verifica responsividade e o restante da progressão. O teste online usa saves isolados e pode simular atraso, variação e perda de pacotes.

Protocolo online atual: `ashenwild-coop-14`. Pacotes antigos não conectam com esta atualização.

# Progressão individual e Guardião da Seiva

## Melhorias e migração do save

Cada classe tem seu próprio conjunto de oito melhorias e seus sete patamares. Ouro e cristais continuam na carteira da conta; a compra fortalece apenas o personagem selecionado. A partida e o perfil online consultam os níveis da classe efetivamente escolhida.

Na primeira abertura desta atualização, as melhorias universais antigas são zeradas e seu ouro é devolvido usando os preços da versão anterior. A marca `character_meta_schema = 1` impede um segundo reembolso ao recarregar. A migração grava o arquivo por substituição atômica. XP, talentos, equipamentos e campanha permanecem preservados.

| Patamar | Bônus por compra | Total acumulado ao concluir o atributo |
| --- | --- | --- |
| Aprendiz | 0,02% | 0,2% |
| Iniciado | 0,03% | 0,5% |
| Veterano | 0,05% | 1% |
| Mestre | 0,07% | 1,7% |
| Ascendente | 0,10% | 2,7% |
| Semideus | 0,15% | 4,2% |
| Divino | 0,20% | 6,2% |

Os preços aumentam aproximadamente 40%, com o mesmo crescimento por nível e patamar. MAX continua exigindo ouro para todos os níveis restantes do atributo no patamar atual. O bloqueio dos oito atributos também é individual.

## Relíquias

Coleção, três espaços equipados e progresso dos desafios são independentes por classe. As relíquias antigas são preservadas no personagem selecionado durante a migração; os demais começam sua própria coleção. As conquistas gerais continuam sendo registros da conta e não concedem automaticamente relíquias a outro personagem.

Os desafios da coleção usam os abates, chefes, elites, ouro recebido em expedições, ondas, habilidades e espécies daquele personagem. O Cristal do Tempo exige 25 ondas dessa classe. A Pena de Fênix exige vencer a fase 10 das seis regiões com ela. O menu explica a condição real de cada desbloqueio. Resultados online são atribuídos à classe jogada, mesmo que o personagem selecionado no menu seja outro.

## Guardião da Seiva

- Ataque básico com 14 de dano base e área pequena. O dano principal vem da tropa.
- Chamado da Seiva: dois brotos animados com `amgguard.png`, por 16 segundos, a cada 18 segundos. A tropa cresce até seis; bônus excedentes de quantidade também fortalecem o dano das invocações.
- Alcateia do Bosque: lobos móveis que perseguem e mordem os inimigos.
- Guardiões de Casca: criaturas de natureza mais fortes, com dano e duração por nível.
- Bosque Desperto: árvores estacionárias atacam com raízes até 270 unidades e aplicam lentidão.
- Florescimento Ancestral: invoca uma árvore ancestral por 18 segundos e recupera 15% da vida. O dano vem da árvore, sem explosão imediata do personagem.
- Abraço das Raízes e Eclosão do Éter mantêm opções de controle/área. Orbe de Brasa e Círculo de Espinhos deixam a seleção dessa classe.

Cada nova invocação substitui o grupo anterior do mesmo tipo. Quantidades são limitadas para manter o cooperativo estável. Dano e recuperação são creditados ao dono da invocação. As árvores e os brotos têm animações e aparecem também para os convidados.

## Mundo 2 e inimigos

Multiplicadores básicos das regiões: `1 / 3,1 / 4,6 / 6,4 / 8,5 / 11`. A partir da segunda região, inimigos comuns e elites têm também um piso de vida que cresce por região, onda, fase e dificuldade. No início do mundo 2, esse piso é de 90 de vida; as criaturas frágeis não são eliminadas pelo ataque básico ou crítico de um conjurador novo.

Os inimigos anteriores permanecem. Os quatro assets novos usam Sprite2D, recortes próprios, transparência e filtro nearest, com retratos do mesmo arquivo no bestiário:

- `BloodMonster.png`: Sanguinário da Fenda, nas regiões avançadas.
- `canarinho.png`: Canário Errante, nas regiões de floresta, geada e pântano.
- `zoombi.png`: Zumbi de Esporos, nas criptas, castelo e pântano.
- `slime.png`: Gosma da Maré Azul, nas seis regiões. A folha usa células retangulares de 96 × 32, preservando os seis quadros completos.

Os inimigos estão em `assets/art/enemies/pixel/`; o aliado está em `assets/art/allies/amgguard.png`. Protocolo online: `ashenwild-coop-14`; todos devem usar a mesma atualização.

## Verificação

`tests/character_nature_update.gd` cobre reembolso e recarga sem duplicação, falha de gravação preservando o save antigo, compras e relíquias por classe, perfis online, dano real dos aliados, árvores estacionárias, limites da tropa e resistência de todos os inimigos do mundo 2. A suíte geral cobre os nove sprites de inimigos, progressão, MAX, navegação e responsividade. O teste ENet cobre as quatro novas espécies, brotos, árvores e descobertas da classe correta com atraso e perda de pacotes simulados.

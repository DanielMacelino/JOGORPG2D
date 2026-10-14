# Melhorias permanentes

A página segue o gabinete de artefatos: cenário de castelo, molduras ornamentadas, ícones de atributos, cards à esquerda e detalhes à direita. Os dados continuam sendo os oito atributos reais do catálogo; a referência visual não transforma melhorias em relíquias nem adiciona raridades fictícias.

- Filtros: Todos, Força, Habilidades, Movimento, Defesa e Economia.
- Cards: ícone, nome, bônus atual e próximo, nível de 0 a 10 no patamar, barra de progresso, custo e ação Aprimorar.
- Detalhes: ilustração, nome, patamar, efeito acumulado, próximo nível, compras acumuladas e explicação da progressão.
- Cabeçalho: ouro, cristais, patamar atual e progresso coletivo de 0 a 80. Dez compras em cada um dos oito atributos liberam o próximo patamar. As taxas e os custos seguem `PermanentUpgrades`.
- A compra usa o preço calculado pelo SaveManager e atualiza a página sem recriá-la. Filtro, seleção, página e aba permanecem. A ação fica desabilitada quando falta ouro, o atributo termina o patamar ou há uma partida em andamento.
- Cinco cards por página em telas largas; três nas estreitas e dois nas baixas. Abas de lista e detalhes aproveitam a largura de janelas menores. Nenhum ScrollContainer é usado.

A implementação fica em `scripts/ui/upgrades_panel.gd`. As ilustrações escaláveis ficam em `assets/art/upgrades` e podem ser reconstruídas com `tools/generate_upgrade_icons.py`.

O harness isolado inclui `tests/upgrades_screen.gd`, verificando compras persistidas, valores antes/depois, transição de patamar, limite de nível, falta de ouro, filtros e paginação, além do encaixe de todos os oito painéis de detalhes em cinco resoluções. Os testes anteriores de botões e navegação também continuam exercitando as compras reais.

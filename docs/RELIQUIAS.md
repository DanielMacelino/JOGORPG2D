# Relíquias

A página usa o cenário de castelo e floresta dos Registros, molduras ornamentadas e ilustrações próprias para os 12 artefatos existentes. Não altera a posse, as condições de desbloqueio ou os efeitos do catálogo.

- Três espaços ativos no topo; clicar em um seleciona sua relíquia. A ação Remover libera o espaço.
- Cards com título, descrição, conquista, raridade e ação de equipamento. Os artefatos bloqueados usam uma ilustração de cadeado e revelam a conquista necessária ao serem selecionados.
- Painel de detalhes com arte sobre pedestal, efeitos, citação e ação contextual. O limite de três artefatos impede equipar outro até liberar um espaço.
- Seis cards por página em telas largas; quatro em telas estreitas e dois em janelas baixas. Nessas janelas, as abas Relíquias e Detalhes aproveitam a largura disponível. Não há rolagem.
- Seleção, página e aba permanecem ao redimensionar a janela. Equipar e remover atualizam a própria página e persistem pelo SaveManager.

`scripts/ui/relics_panel.gd` contém a interface; `relics_presentation.gd`, os textos auxiliares; `assets/art/relics`, os SVGs. O gerador `tools/generate_relic_icons.py` permite editar as ilustrações sem fontes ou emojis.

`tests/relics_screen.gd`, executado pelo harness isolado, verifica os desbloqueios reais, ilustrações distintas, limite e persistência dos equipamentos, paginação completa, manutenção da seleção e encaixe dos cards e detalhes em cinco resoluções e duas preferências de escala.

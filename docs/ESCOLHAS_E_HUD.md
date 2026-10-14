# Escolhas de habilidade e painel de combate

Os cartões usam o anexo como referência: molduras ornamentadas, ilustração sutil dentro do cartão, ícone central em losango, título em fonte serifada, etiqueta com nível atual → próximo, raridade e indicação de classe/geral, descrição cumulativa e ação Escolher. Toda a área do cartão aceita clique ou confirmação pelo teclado. O jogo permanece ao fundo.

Nas janelas largas, as três cartas ficam lado a lado. Nas estreitas, viram cartões horizontais empilhados. O ícone, o texto e a ação se adaptam ao espaço para manter as três opções sem rolagem. A escala do texto é calculada medindo as fontes antes de ajustar os controles, evitando refazer o layout várias vezes no mesmo quadro.

A HUD tem retrato da classe, barra vermelha de vida e barra verde de XP. As informações usam valores reais e permanecem em uma linha. Durante a seleção, os indicadores de onda e chefe cedem espaço ao título; em telas pequenas, as informações secundárias também cedem espaço às cartas. Ao terminar a escolha, a HUD completa retorna.

Em Registros, Ouro de Véspera e Cristais são unidades inteiras do layout. O fluxo pode levar um rótulo completo para a linha seguinte, mas não o quebra letra por letra.

Arquivos: `scripts/ui/level_choice_card.gd`, `scripts/ui/ability_choice_screen.gd`, `scripts/ui/battle_portrait.gd`, `scripts/ui/ability_art.gd`, `scripts/game/game_controller.gd`, `scripts/network/coop_game.gd` e `scripts/ui/menu/records_screen.gd`. As ilustrações e ícones existentes foram reutilizados; as molduras e efeitos são desenhados pelo Godot.

Verificação: a regressão cobre oito resoluções e duas escalas, texto legível, três escolhas sem rolagem, moedas em uma linha, HUD sem sobreposição, preservação das ofertas ao redimensionar e retorno dos indicadores após escolher. O teste online usa quatro instâncias com XP coletivo, pausa, escolhas e espera pelo grupo. Os testes usam saves isolados e não capturam telas.

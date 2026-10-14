# Galeria de personagens

A página reaproveita as seis artes e animações de personagem existentes. Os cards têm molduras ornamentadas, cor própria de cada classe, estado de seleção, atributos básicos, habilidade inicial, expedições realizadas e progresso de XP individual. As informações vêm de ContentCatalog, SaveManager e TalentManager.

Em telas largas, três cards aparecem juntos. As setas inferiores levam aos demais viajantes. Telas intermediárias mostram dois cards, e janelas estreitas ou baixas mostram um por página. Em janelas baixas com largura suficiente, arte e informações ficam lado a lado. A página não usa rolagem. Descrições maiores também ficam disponíveis nas dicas de mouse.

Escolher uma classe atualiza os cards na própria página. Recrutar mantém os preços e a concessão da arma inicial do SaveManager, permite pagar com ouro ou cristais e seleciona a classe recrutada. Os saldos e estados dos botões são atualizados sem perder a página atual. A confirmação aparece na própria galeria, sem abrir janelas sobrepostas.

`scripts/ui/characters_panel.gd` contém a interface. `tests/characters_screen.gd` verifica as seis classes, valores de atributos, XP e expedições reais, seleção persistida, recrutamento com ambas as moedas, arma inicial, falta de saldo, navegação de retorno e encaixe em cinco resoluções. O teste de responsividade existente também percorre a nova galeria.

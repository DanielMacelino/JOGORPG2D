# Ajustes de combate e interface — 13/10/2026

A evolução de uma expedição exige 45 XP para o primeiro nível. Os seguintes usam `45 + nível × 28 + nível^1,5 × 8`. O XP coletivo dos orbes é ajustado pelo tamanho do grupo para compensar as ondas com mais inimigos. Cada personagem conserva seu nível permanente, talentos, equipamentos e habilidades próprios.

No cooperativo, subir de nível pausa o mundo para todos. As ofertas são individuais, os nomes de quem falta escolher aparecem para quem já escolheu, e uma rodada só termina quando todos respondem. Um identificador de rodada impede escolhas repetidas ou atrasadas de aplicarem um bônus duas vezes. Jogadores desconectados saem da espera.

Os convidados enviam inputs a cada passo de física, aplicam o movimento imediatamente e reconciliam o resultado com os estados do anfitrião, enviados a 30 Hz. Dano, coleta e combate continuam calculados no anfitrião. Essa mudança reduz a espera visual pelo movimento; não elimina o atraso da conexão entre computadores.

Chefes têm dez vezes a vida anterior. Na quinta fase de cada região recebem mais 60% de vida, e os ganhos dessa fase têm multiplicador adicional de 25%. As tentativas derrotadas continuam concedendo as recompensas já conquistadas ao concluir a rodada; o jogador pode repeti-las para investir em melhorias. Não há uma exigência artificial de perder duas ou três vezes: a necessidade de repetir depende da classe, equipamentos e execução.

O dano cresce com as ondas e as fases posteriores incluem mais conjuradores. O roubo de vida preserva a soma dos bônus, mas usa um orçamento de recuperação de até 1,5% da vida máxima por segundo, indicado nas descrições dessas habilidades. Acertar uma multidão deixa de restaurar uma barra inteira instantaneamente. Regeneração e curas diretas continuam sendo aplicadas pelos seus efeitos, e os bônus de cada escolha se somam.

Os personagens, monstros, invocações, projéteis e explosões usam desenhos menores; os alcances de ataque permanecem os mesmos. As habilidades adquiridas aparecem em ícones pequenos no HUD, com borda de raridade e número do nível. As escolhas mostram Básica, Média, Avançada, Épica ou Deus e a transição de nível. Habilidades no nível cinco saem do sorteio.

Melhorias tem filtros Todos, Força, Habilidades, Movimento e Outros. Comprar preserva a posição da lista. A Forja tem filtros por classe e Todos, incluindo equipamentos compartilhados no filtro de cada classe. Voltar percorre a navegação anterior. Folhas, partículas e pequenas animações de hover usam desenho nativo e não dependem de novas imagens.

Os testes usam saves isolados e não capturam telas. A regressão verifica compra com rolagem, filtros, ícones, navegação, exclusão de habilidades no máximo, níveis das cartas, bloqueio de dano aliado e vida dos chefes. O teste online usa quatro instâncias reais com ENet, incluindo a opção Continuar quando todas as habilidades de um jogador já chegaram ao máximo. O teste de pressão compara ficar parado e circular com personagens iniciais: ambos podem perder; o movimento deve prolongar a sobrevivência e upgrades iniciais não podem tornar o personagem imune. Esse teste não mede um jogador experiente nem garante um número fixo de tentativas para vencer.

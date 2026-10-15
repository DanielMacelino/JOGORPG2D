# Transmutação de equipamentos

## Interface e favoritos

A composição usa três painéis a partir de 900 pixels disponíveis, dois entre 720 e 899 (Itens e Ritual juntos, Detalhes separado) e um painel por seção abaixo disso. A grade calcula as colunas pela largura e altura disponíveis e preserva a seleção ao redimensionar. O ritual usa uma mesa de pedra com anéis de bronze, um cristal verde-água e quatro espaços com os ingredientes reais. Molduras retas em metal envelhecido, abas verdes e ações em cobre seguem a referência. Transmutação preserva a opacidade anterior de 90%; menu principal e Mundos usam 100%.

A Fusão mostra a grade de equipamentos à esquerda, quatro espaços ao redor de um círculo animado no centro e os detalhes à direita. Em telas estreitas, as abas Itens, Ritual e Detalhes alternam esses painéis sem rolagem. Os filtros incluem categoria, classe e raridade; mudar a categoria preserva os ingredientes já selecionados. A previsão informa as chances reais e a possibilidade de manter a raridade; os atributos finais dependem do sorteio. O ritual tem sons de seleção, preparação e resultado, e o resultado aparece em um pop-up.

A estrela no ícone do Arsenal favorita todas as cópias daquele equipamento. Favoritos não aparecem nas Trocas ou na Fusão e não podem ser consumidos pela Forja. Receitas que usam ou produzem um item favorito também são ocultadas. A proteção é validada novamente no sistema de inventário antes de consumir recursos e persiste no save.

Os detalhes dos itens aparecem sem atraso ao passar o mouse. Esc aciona o mesmo botão Voltar da página; durante a fusão, a navegação continua bloqueada até revelar o resultado salvo.

Abra Arsenal e clique em TRANSMUTAR, ao lado de IR PARA A FORJA. As abas são Fusão, Aposta, Trocas e Como Funciona. O botão SELECIONAR 4 MAIS FRACOS fica sempre no rodapé interno do painel de inventário, inclusive quando há poucos itens. Os seis marcos foram movidos para baixo dos painéis da Fusão, um abaixo do outro. Em telas estreitas ou muito baixas, RECOMPENSAS GARANTIDAS expande a lista no mesmo espaço, sem outra aba nem rolagem.

O resultado aparece em um pop-up sobre a tela atual, com atributos, raridade e eventual item extra; fechar o pop-up preserva os filtros. Em telas estreitas, Itens, Ritual e Detalhes alternam o painel visível. A ajuda tem quatro subseções para evitar uma página longa de texto.

## Fusão

Selecione quatro unidades da mesma raridade, da classe escolhida ou compartilhadas. Cópias do mesmo item podem preencher mais de um espaço, desde que existam em quantidade suficiente. Selecionar automaticamente prioriza os equipamentos mais fracos. Equipamentos em uso por qualquer classe e todas as armas iniciais ficam protegidos.

A fusão consome os quatro ingredientes e entrega um equipamento da próxima raridade em caso de sucesso; caso contrário, entrega um da mesma raridade. Ambos os resultados avançam os marcos. O resultado pertence à classe escolhida. Não há custo de ouro ou cristais. Deus é a raridade máxima e não participa como ingrediente.

| Ingredientes | Próxima raridade | Chance inicial | Marco repetível |
| --- | --- | --- | --- |
| 4 Comuns | Incomum | 40% | Cada 10 tentativas: +1 Incomum |
| 4 Incomuns | Raro | 32% | Cada 20 tentativas: +1 Raro |
| 4 Raros | Épico | 25% | Cada 30 tentativas: +1 Épico |
| 4 Épicos | Lendário | 18% | Cada 40 tentativas: +1 Lendário |
| 4 Lendários | Semideus | 12% | Cada 50 tentativas: +1 Semideus |
| 4 Semideuses | Deus | 8% | Cada 60 tentativas: +1 Deus |

Cada tentativa sem melhora soma dois pontos percentuais à chance daquela raridade, até quinze pontos extras. Melhorar a raridade reinicia esse bônus. Os marcos usam o total de tentativas por raridade de cada personagem e se repetem a cada intervalo. O item extra é entregue mesmo quando a tentativa não melhora a raridade; o bônus não substitui o resultado normal.

As recompensas podem avançar para a raridade seguinte sem exigir a dificuldade da receita equivalente na Forja. Preferem equipamentos ainda não possuídos; se a coleção estiver completa, uma cópia real é adicionada. Quantidades aparecem no ícone e no detalhe do inventário. Cópias não multiplicam atributos de um item equipado e a Forja consome apenas as unidades pedidas na receita.

## Persistência

Saves anteriores continuam tratando cada ID possuído como uma unidade. `equipment_quantities` guarda quantidades explícitas e `transmutation` guarda tentativas, falhas e o último resultado. Os dados novos também são apagados pelo reset total.

O sorteio e os ingredientes são resolvidos sobre uma cópia do save. O arquivo completo é escrito em temporário e substituído antes de iniciar a animação. Se a escrita falhar, o inventário anterior permanece intacto. Enquanto o resultado estiver pendente de exibição, nenhuma nova fusão pode ocorrer. Redimensionar, fechar e reabrir a tela apenas mostra o resultado já salvo. Continuar confirma a visualização sem entregar itens novamente.

A fusão não funciona durante partidas solo ou online. Nenhum save de teste é o save real do jogador.

## Validação

`tests/transmutation.gd` verifica as seis raridades de entrada, sucessos e falhas com sementes determinísticas, marcos repetidos, cópias, proteção de equipamentos, quantidades, falhas de gravação, reabertura, confirmação idempotente, rodapé fixo e receitas da Forja. A navegação real e as quatro abas são verificadas em seis resoluções e duas escalas de texto.

## Aposta

Escolha um prêmio no catálogo da classe atual, limitado às receitas da Forja já liberadas pela dificuldade e região. Não é necessário já possuir os ingredientes da receita nem o dinheiro para forjá-la: a Aposta tem seus próprios sacrifícios. Itens favoritos ficam fora do catálogo. Itens de outras classes e recompensas de regiões/dificuldades bloqueadas não podem ser solicitados, inclusive por chamadas diretas ao sistema.

Ofereça de 4 a 12 unidades do inventário do personagem, inclusive cópias repetidas e raridades diferentes. Favoritos, equipados e armas iniciais ficam protegidos. O catálogo tem busca, filtro de raridade e páginas; a seção Sacrifícios permite adicionar uma cópia com o clique e retirar uma com o botão direito. A seleção automática oferece quatro dos itens livres mais fracos. Os quatro primeiros sacrifícios aparecem também ao redor da mesa e podem ser retirados pelo clique.

A chance depende da soma do valor dos sacrifícios em relação ao prêmio, com mínimo de 1% e máximo de 90%. Para o cálculo, o valor de cada equipamento é `3^índice_da_raridade × (1 + √poder/35)`; a probabilidade é `0,20 × soma_dos_valores / valor_do_prêmio`, limitada ao intervalo indicado. A interface mostra a porcentagem antes da confirmação, junto da quantidade que será consumida e da consolação em caso de falha.

Os sacrifícios são consumidos em ambos os resultados. Sucesso entrega exatamente uma cópia do prêmio escolhido. Falha entrega ouro pelos itens Comuns/Incomuns/Raros e cristais pelos Épicos ou superiores. A consolação corresponde a 25% do valor de venda agregado por moeda, arredondado para baixo, com mínimo de uma unidade de cada moeda presente. A oferta exige pelo menos quatro equipamentos, mantendo a consolação abaixo da venda normal do conjunto. Exemplos: quatro Comuns devolvem 15 ouro na falha; quatro Épicos devolvem 1 cristal. Não há cobrança adicional de ouro ou cristais.

Apostas não avançam os marcos nem alteram o bônus de falhas da Fusão. O registro de tentativas/vitórias fica em `transmutation.wagers`, individual para cada personagem. Ouro e cristais continuam compartilhados. O mesmo resultado pendente e a mesma gravação atômica da Fusão garantem consumo único, proteção contra clique duplo, reabertura sem novo sorteio e confirmação idempotente. A falha aparece no pop-up com a consolação; o sucesso mostra o item e seus atributos.

`tests/equipment_wager.gd` verifica sete raridades de sacrifício, vitórias e falhas determinísticas, compensação, consumo exato, ofertas de cópias, proteção de favoritos/equipados/iniciais, limites, catálogo por classe e progresso, rollback de gravação, separação dos personagens, dinheiro compartilhado e o pop-up pendente após reabrir a tela.

## Trocas por ouro e cristais

A aba Trocas filtra itens livres por classe e raridade, incluindo Deus. Escolha o item e a quantidade; o valor aparece antes da confirmação. Comum rende 15 ouro, Incomum 40 ouro e Raro 100 ouro por unidade. Épico rende 1 cristal, Lendário 3 cristais, Semideus 8 e Deus 20 por unidade.

A troca protege todos os equipamentos em uso e armas iniciais. O valor é calculado no sistema de inventário, sem aceitar um preço informado pela interface, e usa a mesma gravação atômica da fusão. Quantidades restantes continuam no inventário. O reset total também limpa o registro das trocas.

Os filtros Lendário e demais raridades usam texto sem quebra de palavras e uma linha própria para a transição de raridades. O estado sem itens fica fora da grade de ícones. O título Forja usa uma linha única.

## Arte do ritual

Arquivo: `assets/art/transmutation-ritual.png`, criado pela ferramenta integrada de imagegen. A imagem é somente a mesa; cristal animado, slots, ingredientes, chance e botões são elementos nativos da Godot. A ilustração usa filtragem linear e os equipamentos preservam sua filtragem própria.

Prompt final:

> Use case: stylized-concept. Production game UI illustration for an alchemical fusion ritual panel, square composition. Dark fantasy RPG, antique hand-painted stone and bronze. A large round heavy stone alchemy table seen slightly from above, inset with three concentric brass rings engraved with tiny NON-ALPHABETIC geometric marks and arcs, a worn moss-green inner disk. The table fills almost all the canvas, its full circular shape visible, table front has thick chipped stone bevel and carved radial blocks. Faint teal-green arcane lines trace an elegant star within the circle. Keep the exact center and the four cardinal positions EMPTY and visually quiet: the game will draw a central magic diamond and four equipment sockets at top/right/bottom/left. At the top right OUTSIDE the round table, three small antique laboratory glass bottles and a mortar on the dim stone workbench, subtle green, burgundy and amber liquids. Warm restrained brass highlights, muted gray stone, desaturated olive, soft teal light in grooves, strong readable rim. Elegant old hand-painted RPG inventory art, grounded materials, fine detail, no exaggerated neon. No characters, no text, no letters, no digits, no labels, no UI border, no buttons, no sockets, no items placed on the ritual disk. Opaque dark gray stone-workshop background to all edges.

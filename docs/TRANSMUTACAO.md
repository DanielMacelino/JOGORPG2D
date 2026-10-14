# Transmutação de equipamentos

Abra Arsenal e clique em TRANSMUTAR, ao lado de IR PARA A FORJA. As abas Fusão, Marcos, Trocas e Como Funciona não usam rolagem de página. Os seis marcos aparecem juntos, um abaixo do outro, em retângulos compactos mantendo o tamanho das letras. O resultado da fusão aparece em um pop-up sobre a tela atual, com atributos, raridade e eventual item extra; fechar o pop-up preserva a classe e a raridade selecionadas. Em telas estreitas, Escolher itens e Ritual dividem a mesma área; selecionar o quarto item abre o ritual.

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

Cada tentativa sem melhora soma dois pontos percentuais à chance daquela raridade, até quinze pontos extras. Melhorar a raridade reinicia esse bônus. Os marcos usam o total de tentativas por raridade, compartilhado entre classes, e se repetem a cada intervalo. O item extra é entregue mesmo quando a tentativa não melhora a raridade; o bônus não substitui o resultado normal.

As recompensas podem avançar para a raridade seguinte sem exigir a dificuldade da receita equivalente na Forja. Preferem equipamentos ainda não possuídos; se a coleção estiver completa, uma cópia real é adicionada. Quantidades aparecem no ícone e no detalhe do inventário. Cópias não multiplicam atributos de um item equipado e a Forja consome apenas as unidades pedidas na receita.

## Persistência

Saves anteriores continuam tratando cada ID possuído como uma unidade. `equipment_quantities` guarda quantidades explícitas e `transmutation` guarda tentativas, falhas e o último resultado. Os dados novos também são apagados pelo reset total.

O sorteio e os ingredientes são resolvidos sobre uma cópia do save. O arquivo completo é escrito em temporário e substituído antes de iniciar a animação. Se a escrita falhar, o inventário anterior permanece intacto. Enquanto o resultado estiver pendente de exibição, nenhuma nova fusão pode ocorrer. Redimensionar, fechar e reabrir a tela apenas mostra o resultado já salvo. Continuar confirma a visualização sem entregar itens novamente.

A fusão não funciona durante partidas solo ou online. Nenhum save de teste é o save real do jogador.

## Validação

`tests/transmutation.gd` verifica as seis raridades de entrada, sucessos e falhas com sementes determinísticas, marcos repetidos, cópias, proteção de equipamentos, quantidades, falhas de gravação, reabertura, confirmação idempotente e receitas da Forja. A navegação real e as quatro abas são verificadas em cinco resoluções e duas escalas de texto.

## Trocas por ouro e cristais

A aba Trocas filtra itens livres por classe e raridade, incluindo Deus. Escolha o item e a quantidade; o valor aparece antes da confirmação. Comum rende 15 ouro, Incomum 40 ouro e Raro 100 ouro por unidade. Épico rende 1 cristal, Lendário 3 cristais, Semideus 8 e Deus 20 por unidade.

A troca protege todos os equipamentos em uso e armas iniciais. O valor é calculado no sistema de inventário, sem aceitar um preço informado pela interface, e usa a mesma gravação atômica da fusão. Quantidades restantes continuam no inventário. O reset total também limpa o registro das trocas.

Os filtros Lendário e demais raridades usam texto sem quebra de palavras e uma linha própria para a transição de raridades. O estado sem itens fica fora da grade de ícones. O título Forja usa uma linha única.

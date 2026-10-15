# Forja: bancada de receitas

A página usa o cenário de oficina existente, molduras ornamentadas e três colunas: filtros, receitas e detalhes do resultado. As categorias seguem os equipamentos que o catálogo realmente oferece: Todas, Armas, Armaduras e Acessórios.

- Filtros de personagem, espaço, raridade, tipo de arma e disponibilidade. O menu lateral muda com a categoria.
- O botão **O que consigo craftar**, acima das receitas, alterna o filtro de disponibilidade real sem descartar os demais filtros.
- Busca por nome, família ou região. Ordenação por poder, menor custo ou nome, com desempate estável pelo identificador da receita.
- Cinco cards por página nas telas largas, dois em janelas menores e um nas mais baixas. Cards exibem ícone, raridade, classe, poder e custos reais.
- Detalhes exibem os atributos do resultado, os ingredientes e suas quantidades disponíveis/necessárias, os custos e as condições ainda não cumpridas.
- Clicar numa receita abre a comparação com o item equipado no mesmo espaço da classe do resultado; itens compartilhados usam a classe selecionada. O painel mostra o equipamento atual, o poder e os atributos antes/depois, incluindo perdas de efeitos exclusivos do item antigo. Ganhos são verdes e perdas, vermelhas; diferenças percentuais são exibidas em pontos percentuais. Setas permitem consultar todos os atributos sem rolagem, e **Ver receita** retorna aos materiais.
- Ouro, cristais e quantidade de itens são lidos do inventário real. Não é exibida uma capacidade fictícia de mochila.
- Forjar mantém as regras e os preços do SaveManager. A página atualiza saldo, ingredientes, disponibilidade e confirmação na própria tela, preservando a receita e a página selecionadas.
- Telas estreitas usam as abas Filtros, Receitas e Detalhes; nenhum ScrollContainer é usado.

Implementação: `scripts/ui/forge_panel.gd`. A camada de fundo usa `prepare-workshop.png` quando a rota é `forge`.

O teste isolado `tests/forge_workbench.gd` verifica ordenação, categorias, armas, contagens reais, consumo de cópias, cobrança, persistência, seleção e encaixe das seções e das quatro categorias em cinco resoluções. Os testes de catálogo, navegação e responsividade continuam exercitando filtros e botões reais de fabricação.

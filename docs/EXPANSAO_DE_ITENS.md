# Expansao do catalogo

## Equipamentos

6.048 equipamentos adicionados, alem dos anteriores. A matriz e 6 classes x 6 espacos x 6 regioes x 4 familias x 7 tiers. Sao 864 familias completas, com variantes Comum, Incomum, Raro, Epico, Lendario, Semideus e Deus.

Os espacos sao arma, elmo, armadura, botas, anel e amuleto. As familias Fortaleza, Assalto, Horizonte e Ritual oferecem combinacoes diferentes de defesa/vida, dano/ataque, movimento/coleta e efeitos exclusivos da classe. Itens superiores incluem efeitos regionais como queimadura, lentidao, retaliacao, ricochete e maior duracao de invocacoes. O atributo principal usa a identidade da classe para preservar Sentinela como tanque e as classes frageis como atacantes.

As escalas aumentam por tier. As dificuldades minimas sao Facil para Comum/Incomum, Medio para Raro, Moderado para Epico, Dificil para Lendario, Semideus para Semideus e Deus para Deus. IDs sao deterministas; o catalogo cresce sem apagar os equipamentos antigos do save.

## Obtencao e forja

Drops de chefes respeitam regiao, classe e dificuldade da partida. Recompensas de nivel continuam concedendo os itens antigos iniciais e depois escolhem itens novos elegiveis para a regiao/classe. O mesmo sistema funciona nas recompensas pessoais do cooperativo.

5.184 receitas novas evoluem um item para o proximo tier da mesma familia. Exigem o item anterior, ouro, cristais, classe liberada e progressao da regiao/dificuldade. Nao se pode fabricar um item novo que ja pertence ao jogador. Quando o ingrediente estava equipado, a forja troca o espaco automaticamente pelo resultado, evitando manter um item consumido no equipamento.

A pagina da Forja usa filtros de classe, espaco, tier, busca e So possiveis. Apenas 2 ou 3 receitas sao montadas por pagina, conforme a janela, sem scroll. A consulta de receitas usa um indice por ID, evitando varrer milhares de registros a cada cartao.

## Habilidades

294 habilidades/passivas novas: 252 exclusivas (42 por classe) e 42 compartilhadas. Sao seis escolas por classe e seis escolas compartilhadas, cada uma com os sete tiers. Usam efeitos reais existentes no combate: vida, defesa, dano, ataque, movimento, alcance, area, critico, perfuracao, retaliacao, coleta e atributos de invocacao. Os icones reutilizam os assets das habilidades existentes.

Cada escolha soma os bonus, ate o limite de cinco niveis. Os novos tiers exigem os niveis 1, 2, 4, 7, 10, 14 e 18 da expedicao, alem da dificuldade correspondente. Tiers altos possuem menores pesos nas ofertas. Escolas do druida melhoram quantidade, duracao, dano e ataque das invocacoes.

## Dados e testes

item_tiers.gd define nomes, escalas, probabilidades e requisitos. equipment_expansion.gd e ability_expansion.gd geram os catalogos. forge_panel.gd concentra a nova interface. Nenhum novo asset de personagem foi criado.

Testes verificam contagens, familias completas, IDs/receitas, crescimento de atributos, isolamento por classe, acumulacao das habilidades, requisitos, drops regionais, consumo e substituicao de item equipado, persistencia, filtros e paginacao. A responsividade da Forja participa da verificacao de dez menus, cinco resolucoes e duas escalas de texto. Sem screenshots e sem exportar executavel nesta alteracao.

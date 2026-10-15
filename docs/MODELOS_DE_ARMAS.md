# Modelos de equipamentos

`assets/art/equipment/armsmodels.png` é a folha original de 448×448 pixels: 91 células ocupadas de 32×32. Nenhum pixel foi recortado ou regravado no arquivo. `weapon_models.gd` cria AtlasTexture com recorte protegido e usa filtro nearest nos ícones e personagens.

| Coluna | Uso |
| --- | --- |
| 1 | Espadas do Sentinela e Arauto do Sol |
| 2 | Cetros/cajados da Tecelã |
| 3 | Armas do Guardião da Seiva |
| 4 | Arcos da Batedora |
| 5 | Escudos pareados com as espadas do Sentinela |
| 6 | Dois novos conjuntos de espada e escudo alternativo |
| 7 | Tridente, martelo, besta, lâminas, chicote, machado, cetro e foice em famílias próprias; modelos de adaga também substituem os da Lâmina da Noite |
| Demais | Elmo, couraça, perneiras, botas e amuleto em novos equipamentos |

As treze linhas das colunas principais são distribuídas pelos sete tiers e pelas variantes das famílias existentes, mantendo a evolução visual de cima para baixo. Os escudos continuam no mesmo espaço da arma, conforme a escolha do usuário. As perneiras usam o espaço de armadura existente. Os atributos dos equipamentos anteriores, seus IDs, quantidades, favoritos e receitas continuam válidos. Os nomes de martelo das espadas antigas do Arauto foram ajustados para corresponder ao novo modelo.

São vinte novas famílias, cada uma com sete raridades: 140 equipamentos, 120 receitas de evolução e distribuição nos drops regionais por classe/dificuldade. O catálogo gerado passa a 6188 equipamentos em 884 famílias, com 5304 receitas geradas. Os filtros da Forja usam o tipo real do item e incluem lança, machado, chicote e foice.

As armas em combate e nos retratos seguem o equipamento selecionado. Os pontos de empunhadura acompanham as articulações existentes, sem esticar o sprite. No cooperativo, o perfil e os snapshots de jogadores carregam o ID da arma: o anfitrião e cada cliente veem os modelos efetivamente equipados. O protocolo atual é `ashenwild-coop-14`.

`tests/weapon_models.gd` verifica o uso de todas as 91 células ocupadas, o mapeamento de classes, os escudos pareados, a validade dos recortes, os novos itens/receitas, persistência do item equipado e filtros por tipo. O teste ENet usa armas distintas para anfitrião e cliente e verifica os IDs recebidos nos dois lados.

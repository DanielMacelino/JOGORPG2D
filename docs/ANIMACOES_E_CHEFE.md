# Animacoes e confronto final

As seis classes usam os mesmos desenhos de personagem, agora separados em 54 camadas vetoriais. Pernas alternam na caminhada; capa, cabeca e bracos acompanham o movimento. Ataques possuem duracoes e poses por classe; as adagas alternam os lados, a Batedora puxa o arco e os conjuradores movimentam o cajado. Menu e Arsenal usam uma pose de repouso animada. Nao foram criados novos personagens.

character_animator.gd calcula as poses. tools/generate_character_layers.py regenera as camadas a partir dos SVGs originais e verifica que nenhuma forma foi omitida ou duplicada. Alteracoes nos desenhos originais precisam atualizar os indices de camadas antes de regenerar.

skill_effect.gd desenha gelo, fogo, raizes, invocacao, laminas, flechas, tempo, vazio e provocacao com formas animadas. Os efeitos sao cosmeticos; dano e alcance continuam nos sistemas de combate. Limite global de 24 efeitos simultaneos. Ataques de monstros e invocacoes possuem impulsos curtos; monstros aparecem com uma animacao de crescimento.

Na onda final, seis monstros corpo a corpo chegam com o chefe. Os grupos seguintes aumentam de tres para quatro, com tres corpo a corpo e uma vaga para a variedade normal da regiao. O multiplayer acrescenta acompanhantes conforme o tamanho da equipe. O limite de 144 inimigos continua valendo.

A musica fornecida musicaboss.mp3 foi movida para assets/audio/music. Comeca com o chefe, repete enquanto ele vive, respeita o volume de musica e para na morte do chefe, derrota ou saida da partida. Clientes recebem esse estado do anfitriao; snapshots nao reiniciam a faixa.

A vitoria exibe equipamentos de todas as subidas de nivel e do chefe. Cada jogador online ve seus proprios itens ja creditados no save local. Repetidos convertidos em ouro sao identificados. Icones, raridade e origem aparecem em paginas de um ou dois cards, com descricao no tooltip e sem rolagem. O painel se ajusta ao tamanho da janela.

O protocolo cooperativo agora e ashenwild-coop-6, pois foram adicionados campos de animacao, efeitos e musica. Os participantes precisam da mesma versao ao gerar o proximo executavel. Esta alteracao nao exporta um executavel.

Testes: animation_update.gd verifica poses, alternancia de adagas, ataques reais, efeitos replicaveis, escolta nas seis regioes, inicio/fim/idempotencia da musica, itens concedidos, paginacao e quatro resolucoes. online_integration.gd verifica esses estados e os itens pessoais com ENet real.

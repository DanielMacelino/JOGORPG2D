# Constelacoes

Seis arvores por classe, cada uma com 193 nos (centro gratuito + 192 talentos), totalizando 1.158 nos por classe e 6.954 nos nas seis classes.

- Geral: circulo, equilibrio de atributos, ouro/XP e coleta.
- Furia: chama com caminhos ramificados, dano, cadencia e ataques criticos.
- Vigor: coracao, vida, defesa e regeneracao.
- Astucia: olho, precisao, movimento, dano critico e percepcao.
- Sobrevivencia: folha, recuperacao, roubo de vida, defesa e abrigo.
- Tecnica: hexagono, poder da classe, ataque, area e talentos de invocacao do druida.

## Manutencao

Cada categoria tem seu arquivo independente em scripts/data/talents/: general.gd, fury.gd, vigor.gd, cunning.gd, survival.gd, technique.gd. Esses arquivos declaram nome, cor, forma, sequencia de passivas, nomes, talentos maiores e supremos. tree_builder.gd concentra IDs, conexoes, custos, afinidades de classe e geracao dos grafos. talent_manager.gd cuida de pontos, compras, validacao, soma de bonus e devolucoes. O combate continua recebendo a soma de todas as categorias, independentemente da arvore aberta no menu.

## Interface

Seletores de categoria ficam acima da area de trabalho. So o grafo escolhido aparece no centro; detalhes do no ficam a direita e o personagem aparece a esquerda em telas largas. O desenho pode receber zoom/arraste e possui Ver tudo. Em janelas estreitas, selecionar um no abre seus detalhes no mesmo espaco, com retorno para Ver arvore. A pagina inteira cabe na janela sem ScrollContainer. Cada categoria recorda sua selecao e enquadramento durante a visita a pagina.

## Saves

A escolha confirmada pelo jogador foi reiniciar os talentos antigos e devolver os pontos. talent_schema 3 faz isso uma unica vez, mantendo XP/nivel de cada classe. Os pontos continuam pertencendo ao personagem e sao compartilhados pelas seis arvores. O limite existente de nivel/pontos permanece 216. Uma arvore completa custa 216 pontos. Redistribuir arvore devolve apenas seus pontos e preserva as outras categorias.

## Validacao

Os testes percorrem os 36 grafos e comprovam tamanho, conectividade, isolamento de categorias, custos, talentos supremos, poder exclusivo, pontos compartilhados, isolamento entre classes, soma real de atributos, devolucao e migracao idempotente. A interface foi testada nas seis classes, cinco resolucoes e duas escalas de texto, incluindo seletores, aprendizado e retorno dos detalhes. Sem screenshots ou exportacao de executavel nesta alteracao.

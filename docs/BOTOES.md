# Botoes responsivos

O problema principal era a quebra automatica de palavras em botoes dentro de HFlowContainer. O Godot reservava somente a largura das margens, e os textos viravam colunas verticais. Os botoes comuns agora usam a largura natural do texto, enquanto o container distribui as opcoes em novas linhas quando necessario.

- Filtros de Melhorias e Forja ficam legiveis e conservam sua altura.
- A arvore calcula a altura do desenho depois de reservar espaco para seus controles. A contagem de pontos nao quebra em colunas. Zoom e acoes mantem alvos de clique utilizaveis.
- O hover usa brilho em vez de aumentar a escala do botao, preservando a area de clique e a separacao entre vizinhos.
- Ingredientes e custos da Forja podem ocupar mais de uma linha.
- Arsenal e online mantem controles maiores em janelas pequenas.
- Mapas usa seletores que nao reservam largura pelas opcoes bloqueadas mais longas; a grade de fases reduz suas colunas em telas estreitas.

Validacao: dez menus, cinco resolucoes, escalas de texto 1.0 e 1.2, tamanho de texto, limites horizontais, area de clique, hover e callbacks reais de comprar melhoria e forjar. Tambem foi executada a regressao geral. Sem screenshots ou exportacao de executavel.

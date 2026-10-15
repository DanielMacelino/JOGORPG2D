# Chefes regionais e inventários individuais

| Região | Arquivo original | Chefe |
| --- | --- | --- |
| 2 · Colina Oca / cemitério | boss_ceifador.png | Ceifador do Ossuário |
| 3 · Cratera Rubra | boss_geografo.png | Geógrafo da Caldeira |
| 4 · Castelo Sem Aurora | boss_rei.png | Rei Sem Aurora |
| 5 · Bosque da Geada | boss_lobo.png | Lobo do Inverno |
| 6 · Charco Esquecido | boss_rainha.png | Rainha do Charco |

As folhas originais estão em `assets/art/enemies/pixel/bosses/`. O ceifador usa células de 64 px. As demais folhas têm recortes e pontos de apoio por pose, definidos em `regional_boss_art.gd`. Movimento, espera e ataque usam Sprite2D com filtro nearest. O fundo quadriculado opaco de rei, lobo e rainha é removido no carregamento, por preenchimento conectado à borda de cada recorte, preservando áreas brancas cercadas pelo contorno. As imagens originais permanecem intactas; texturas preparadas ficam em cache antes da partida.

Os IDs antigos dos chefes foram preservados para manter bestiário, conquistas, ataques regionais e transições dos soberanos da fase 10. A região 1 continua com seu Minotauro na fase 10. Colisões e dano continuam usando o corpo reutilizável existente, sem colisões extras no sprite.

## Estoque por personagem

Inventário, quantidades, equipamentos, favoritos, materiais, histórico da forja, tentativas de fusão e seus marcos pertencem ao personagem. XP, talentos, melhorias e relíquias também são individuais. Ouro e cristais continuam compartilhados. Campanha, configurações e registros da conta são preservados.

A migração `character_inventory_schema = 1` acontece uma vez:

- Itens exclusivos vão para sua classe, mantendo as quantidades.
- Itens compatíveis com várias classes distribuem cópias entre quem já os equipava, priorizando o personagem selecionado. Sobras ficam com ele. Uma cópia não é duplicada para equipar dois personagens.
- Favoritos acompanham os itens distribuídos. Materiais e progresso de fusão/troca antigos ficam com o personagem selecionado.
- Cada personagem inicial mantém sua arma de início. Itens equipados sem uma cópia correspondente são removidos do conjunto.
- O arquivo é substituído somente após a gravação completa. Falha na gravação preserva o save anterior.

As telas existentes consultam uma projeção do estoque selecionado. Recompensas de partidas e perfis online usam explicitamente a classe que jogou, mesmo que outra esteja selecionada no menu. A forja só consome o estoque desse personagem. Uma cópia equipada ou favoritada de outro personagem não bloqueia uma cópia independente do estoque atual.

Protocolo online: `ashenwild-coop-14`. Inclui também criação tardia do sprite de invocações quando a identidade chega após um pacote perdido. Todos os amigos precisam da mesma atualização. Nenhum executável foi exportado nesta alteração.

# Inimigos das novas folhas de sprites

Os nove PNGs originais ficam em `assets/art/enemies/pixel/`, sem redimensionamento ou remoção de transparência. `pixel_enemy_sprites.gd` descreve as células de 32, 64, 80, 96 e 100 pixels, incluindo a folha retangular de 96 × 32 e os pontos de apoio de cada folha. `pixel_enemy.tscn` reutiliza a lógica existente de inimigos com um Sprite2D que seleciona quadros de repouso, movimento e ataque, usa filtro nearest, recorte de região e escala uniforme. O combate continua usando as colisões e consultas espaciais existentes. AtlasTexture fornece retratos individuais ao bestiário.

- Baú Raivoso (`loot_mimic`): mini chefe de muita vida e ataque próximo. Uma unidade nasce no início da quarta onda de cada fase, antes da quinta onda do chefe. Não faz parte do sorteio normal, não encerra a fase e mantém a escala de dificuldade e de jogadores. A reserva de limite de inimigos permite seu aparecimento mesmo com o campo cheio.
- Devorador Rubro (`red_orb`): criatura rápida de pouca vida. Usa a folha `bolavermelha.png`.
- Barril Voraz (`barrel_beast`): criatura de contato mais lenta e resistente. Usa `barril.png`.
- Demônio da Fenda (`demon_a`): combatente de machado, usando `Demon_A.png`, células de 100 px e escala uniforme de 3. Surge nas regiões 2–6 a partir da segunda onda. O bestiário usa um recorte do mesmo asset.
- Minotauro do Espinheiro (`minotaur`): chefe da fase 10 dos Ermos de Vespera, em todas as dificuldades. As fases 1–9 mantêm o Rei do Espinheiro. Possui cortes de machado anunciados, ondas de impacto, ataques adicionais de soberano e fúria final.

Os dois novos inimigos comuns entram nas seis regiões a partir da segunda onda e também podem reforçar o chefe. As espécies anteriores e os chefes das outras regiões continuam disponíveis.

## Loot do baú

Matar o baú garante um equipamento compatível com a classe e a região, respeitando o limite de dificuldade dos drops. O item é creditado e salvo imediatamente; a animação exibe o equipamento no local da morte e o HUD mostra seu nome. Não é necessário coletar um objeto no chão. Cópias repetidas contam como unidades reais no inventário. O item também aparece no resumo de recompensas, inclusive em derrota posterior.

No cooperativo, o anfitrião sorteia uma recompensa individual para cada participante. Uma RPC confiável de autoridade entrega os resultados; cada máquina salva apenas seu próprio equipamento. Recibos de drop e a trava por partida impedem duplicação. O protocolo atual é `ashenwild-coop-14`, exigindo a mesma versão entre amigos.

`tests/pixel_enemies.gd` verifica transparência e todos os quadros usados, limites dos recortes, filtro, escala e orientação, surgimento único na quarta onda, novas criaturas nas regiões, loot persistido sem duplicação e os ataques do Minotauro. O teste ENet também mata o baú, valida o item individual no cliente e o inclui no resumo final.

Os quatro inimigos de BloodMonster, canarinho, zoombi e slime e o aliado amgguard estão detalhados em `PERSONAGENS_E_NATUREZA.md`.

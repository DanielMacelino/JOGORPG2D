# Música das ondas, equipamentos e organização das habilidades

`music_match.mp3` foi movida para `assets/audio/music/`. Toca em loop a -15 dB no player, além do ajuste de música que o jogador já tem nas configurações. O início tem um fade de 0,8 s. O mesmo player troca para `musicaboss.mp3` ao surgir o chefe. Snapshots repetidos não reiniciam a trilha. Vitória, derrota e saída interrompem a música da partida; os menus retomam sua trilha habitual. Isso funciona no solo, anfitrião e convidados.

## Equipamentos

`assets_equipamentos.png` está em `assets/art/equipment/`. `accessory_models.gd` define 170 recortes: 16 elmos, 40 anéis, 33 botas, 32 peitorais e 49 amuletos. Os recortes evitam os títulos das categorias. AtlasTexture usa transparência original, proporção preservada, filtro nearest e limites de amostragem.

Todos os modelos estão representados no catálogo existente. Elmos, botas e armaduras usam conjuntos visuais próprios de cada classe; família e raridade selecionam variações estáveis. Anéis e amuletos também variam entre as famílias. `EquipmentIcon` aplica a mesma arte no Arsenal, forja, transmutação, trocas, recompensas e espaços vazios. Armas continuam com seus modelos próprios.

IDs, cópias, favoritos, atributos, receitas, materiais e estoque individual não mudam. O índice visual é calculado quando o catálogo carrega; não exige migração do save.

## Habilidades

O sorteio prioriza um poder ativo disponível, um passivo da classe e uma opção geral ou evolução de algo já aprendido. Quando faltar uma categoria, usa as alternativas válidas. Classes, níveis, dificuldade, limite de cinco níveis e teto de três poderes ativos continuam valendo.

As variantes de raridade de uma mesma escola não aparecem juntas na escolha. Após aprender uma variante, só ela pode continuar evoluindo nessa expedição; outra raridade da mesma escola não vira um segundo passivo independente. Os IDs existentes e seus bônus continuam disponíveis nas expedições futuras. Os passivos acumulam seus valores por nível como antes.

Os cards identificam poder/passivo e função: ataque, área, controle, invocação, defesa, movimento ou suporte. Isso mantém a direção de cada personagem: Sentinela em resistência e provocação, Tecelã em magia e área, Batedora em flechas e mobilidade, Lâmina em ataques rápidos, Guardião em invocações e Arauto em combate equilibrado.

Foram acrescentados três poderes, para completar as escolhas das classes que tinham poucas opções:

- Batedora: Disparo Imobilizante, com perfuração e lentidão; Chuva de Flechas, com dano em área no alvo distante.
- Lâmina da Noite: Leque de Adagas, com projéteis perfurantes em cone.

Os ataques geram dano, controle e efeitos reais; projéteis preservam seu efeito próprio ao receber os bônus do equipamento. Todas as seis classes podem escolher três poderes diferentes. O Guardião mantém sua tropa de natureza como foco.

Protocolo cooperativo: `ashenwild-coop-14`. Todos precisam da mesma atualização. Nenhum executável é exportado nesta alteração.

Validação específica: `tests/match_equipment_skills.gd`, além da regressão de menus, progressão, combate e do teste ENet com atraso, variação e perda de pacotes.

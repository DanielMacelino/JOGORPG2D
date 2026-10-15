# Forja, progressão e novos assets

- Toda forja entrega uma cópia real, mesmo quando o resultado já existe no Arsenal. Receitas geradas podem ser repetidas. O inventário mostra as cópias agrupadas, com `×2`, `×3` etc.
- Materiais, ouro, cristais, resultado e conjunto equipado são gravados em uma única transação. Se não for possível salvar, a compra é cancelada sem consumir nada. A última cópia de um ingrediente equipado é substituída pelo resultado compatível; cópias restantes mantêm o equipamento original.
- Favoritos continuam protegidos. Ferramentas iniciais continuam reutilizáveis.
- O botão **MAX**, ao lado de Aprimorar, compra todos os níveis restantes do atributo no patamar atual. Só habilita com ouro para a soma exata dos preços. Não atravessa a exigência de concluir os oito atributos para liberar o próximo patamar.
- **Poder** aparece no Arsenal e em Preparar Personagem: soma do `power_score()` dos equipamentos efetivamente usados pela classe. Cópias guardadas e equipamento de outra classe não contam.

## Dificuldade

O multiplicador básico das seis regiões agora é `1 / 1,85 / 2,8 / 4 / 5,4 / 7`. Os multiplicadores existentes por fase, dificuldade e chefe continuam aplicados. A primeira fase da segunda região já tem inimigos comuns mais fortes que os da décima fase da primeira região. Cada região também reduz o intervalo de reforços em 2,5 pontos percentuais adicionais.

No online, a vida usa `1 + 0,8 × (jogadores − 1)`. O dano mantém a escala de grupo existente e usa pressão adicional de `1,2 / 1,3 / 1,4` para dois, três ou quatro jogadores. Isso aumenta o dano em aproximadamente 9%, 13% e 17% em relação à atualização anterior, sem aumentar o limite de 144 inimigos ou a frequência dos pacotes.

## Assets e magia

- `assets/art/equipment/inventory.png`: recorte da moldura vazia, sem esticar a folha inteira, usado nos seis espaços ao redor do personagem.
- `assets/art/enemies/pixel/Demon_A.png`: Demônio da Fenda, adicional às espécies existentes. Surge da segunda região em diante, a partir da segunda onda. Células de 100 px; animações de repouso, caminhada e ataque; pivô nos pés e filtro nearest.
- `assets/art/abilities/hab01.png`: Eclosão do Éter, poder exclusivo da Tecelã e do Guardião da Seiva. Cena reutilizável `scenes/effects/arcane_bloom.tscn` com Sprite2D. Usa 16 quadros de 64 px, excluindo o rodapé da folha.
- A onda expande durante 0,96 s e atinge cada inimigo uma única vez. Por nível: dano `100 + 30 × nível`%, raio `130 + 16 × nível`, recarga `8 − 0,5 × nível` s. Ocupa um dos três espaços de poderes, respeita limite de nível e mostra os totais nos cards/HUD.
- O anfitrião calcula o dano; os convidados recebem a animação. Protocolo `ashenwild-coop-14`, exigindo a mesma atualização nos computadores.

## Verificação

`tests/forge_max_assets.gd` cobre cópias repetidas, consumo agregado, persistência, favoritos, falha de gravação, MAX sem compra parcial, patamares, poder por classe, progressão regional e dano da onda sem duplicação. A suíte também verifica Melhorias em cinco resoluções e duas escalas de texto. O teste ENet inclui o novo demônio e a animação da magia nos convidados, com atraso, variação e perda de pacotes simulados. Os testes usam saves isolados.

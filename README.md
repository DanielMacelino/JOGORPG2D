# Ashenwild: Riftbound Survivors

Protótipo jogável em Godot 4, feito em GDScript. Abra `project.godot` na Godot e pressione F5 para executar o projeto; a cena principal já está configurada.

A interface e a floresta usam uma direção visual própria, com ilustrações vetoriais, personagens em formas recortadas e tons de musgo, marfim e cobre. Veja [a direção visual e os arquivos de arte](docs/DIRECAO_VISUAL.md).

## O que já está implementado

- Seis classes: Sentinela, Tecelã e Batedora disponíveis desde o início; Lâmina da Noite, Guardião da Seiva e Arauto do Sol recrutáveis com ouro ou cristais.
- Seis regiões com dez fases cada. Completar as 60 fases abre a próxima dificuldade, de Fácil até Deus e ciclos seguintes; cada dificuldade mantém seu progresso.
- Ondas de grupos de monstros, ataques que limpam vários alvos, sequência de abates e coleta magnética. XP mais espaçado para reduzir interrupções, com evolução coletiva e pausa para escolhas no cooperativo.
- Nível permanente e seis constelações por classe: Geral, Fúria, Vigor, Astúcia, Sobrevivência e Técnica. Cada árvore tem 193 nós e um desenho próprio. Seletor acima, uma árvore no centro, zoom, arraste e redistribuição por árvore sem rolagem da página.
- Movimento WASD/setas, ataques automáticos específicos por classe, projéteis, dano crítico, efeitos, coleta de experiência e escolhas de nível.
- Classes com papéis distintos: Sentinela de muita vida e provocação, Tecelã de dano em área, Batedora e Lâmina com ataques muito rápidos, Guardião com invocações temporárias e Arauto equilibrado. Habilidades próprias e compartilhadas, com bônus cumulativos e totais visíveis.
- Pausa, chefes e conjuradores com ataques de área sinalizados, recompensa, telas de vitória/derrota e avanço para a próxima fase.
- Ouro, equipamento, classes, fases, dificuldades, níveis individuais e talentos gravados em `user://ashenwild_save.json`. Saves anteriores são migrados preservando o progresso.
- Inventário com personagem central, seis espaços de equipamento, lista lateral com ícones e raridades, filtros por categoria e troca de itens separada por classe. Layout adaptado para telas estreitas.
- Sessenta equipamentos regionais com efeitos de ricochete, queimadura, lentidão e invocações. Fases com hordas, caçadas, altares, fendas e tempestades; seis chefes com ataques próprios e segunda etapa.
- Home com portal na floresta, cinco cartões principais, dados reais do personagem e páginas agrupadas de preparação e registros. Veja [a descrição, arte e prompt](docs/REGIOES_E_HOME.md).
- Folhas e partículas leves nos menus, filtros em Melhorias e Forja, compras sem perder a posição da lista e Voltar para a página anterior. Habilidades mostram raridade e nível atual → próximo; habilidades no máximo saem dos sorteios.
- Registros com fundo de castelos e luar, quatro cartões ilustrados, ornamentos dourados e contadores reais. Veja [a implementação, arte e prompts](docs/REGISTROS.md).
- Escolhas de habilidade com molduras ornamentadas, ícones em losango e ação Escolher, mantendo três opções sem rolagem. HUD com retrato, vida e XP; veja [as escolhas e o painel de combate](docs/ESCOLHAS_E_HUD.md).
- Joystick virtual em dispositivos móveis, HUD adaptativa, volume, escala da interface, tela cheia e resolução no PC.
- Resources tipados para classes, inimigos, habilidades, equipamentos e mapas; dados iniciais montados em `scripts/autoload/content_catalog.gd` para facilitar a edição.
- Efeitos sonoros de abate, coleta e evolução, com volume independente. Inclui trilha de menu, cliques de interface e música para o chefe final.

## Controles

O botão **Jogar online** permite hospedar ou entrar numa sala cooperativa para até quatro jogadores pelo IP do Radmin VPN. Veja [como conectar e jogar em grupo](docs/ONLINE_RADMIN.md). O progresso de cada participante fica no seu computador.

- PC: WASD ou setas para mover; ESC abre o menu e pausa no modo solo; mouse para menus. No cooperativo, a partida continua.
- Celular/tablet: joystick virtual e botão de pausa.
- Árvore: arraste para explorar, roda ou botões +/− para aproximar, selecione um talento e clique em Aprender. Os botões Fúria/Vigor/Astúcia centralizam cada caminho.

## Organização

- `scenes/`: cenas de entrada e expedição.
- `scripts/autoload/`: save, catálogo, equipamento, áudio e estado da partida.
- `scripts/data/`: Resources de dados.
- `scripts/systems/`: waves, inimigos, habilidades, experiência e loot.
- `scripts/world/`: jogador, inimigos, cenário, projéteis e efeitos.
- `scripts/network/`: sala ENet, combate cooperativo e sincronização dos convidados.
- `scripts/ui/`: menus visuais e joystick touch.

Veja [a progressão e os ajustes de combate](docs/PROGRESSAO.md). Para rodar a regressão em uma cópia temporária com save separado: `powershell -ExecutionPolicy Bypass -File tests/run_regression.ps1`. Use `-GodotExecutable` para informar outro caminho do Godot.

No cooperativo, permaneça perto de um aliado caído por 4 segundos para reanimá-lo. Receber dano ou afastar-se reinicia o progresso. Ele retorna com 35% da vida e proteção por 2 segundos. Se todos caírem, a expedição termina.

- Catálogo ampliado com 6.048 equipamentos e 294 habilidades/passivas novas, separados por classe e sete tiers. A Forja oferece 5.184 receitas de evolução, com filtros e paginação sem scroll.

Animacoes de caminhada e ataques nas seis classes, efeitos de habilidades e invocacoes, escolta corpo a corpo na onda final, trilha musicaboss.mp3 e equipamentos da expedicao na tela de vitoria. Detalhes em docs/ANIMACOES_E_CHEFE.md.

Multiplayer: movimento local previsto e reconciliado com passos iguais no servidor, comandos redundantes, jogadores em fluxo prioritario de 60 Hz e entidades em lotes independentes com compressao distribuida por frame. Testes de atraso/perda e detalhes em docs/MULTIPLAYER_FLUIDEZ.md.

## Exportar para Windows e macOS

Use Godot 4.7.2 e instale os templates de exportação da mesma versão. Os presets Windows Desktop e macOS estão em `export_presets.cfg`; escolha o destino ao exportar. A pasta `builds/` e o cache `.godot/` não são versionados. O Godot recria o cache ao importar o projeto.

No macOS, exporte como ZIP para preservar as permissões do aplicativo. O preset universal inclui Intel e Apple Silicon, com assinatura ad-hoc e sem notarização Apple. A execução em um Mac real ainda precisa ser validada.

Para jogar entre Mac e Windows, use a mesma rede local ou uma VPN compatível com ambos. O Radmin VPN oferece versão apenas para Windows. Informe o IP do anfitrião na rede compartilhada e a mesma porta (padrão 24567 UDP). Todos devem usar o mesmo protocolo do jogo: `ashenwild-coop-7`.

Em Configurações, RESETAR TODO O PROGRESSO reinicia os dados locais do jogador somente após confirmação.

Inventário em grade de ícones com detalhes ao passar o mouse e ordem por poder; melhorias em sete patamares coletivos; três poderes ativos por partida com passivos livres; soberanos exclusivos na fase 10. Veja [as regras e a validação](docs/INVENTARIO_MESTRIA_E_SOBERANOS.md).

O Arsenal também oferece [Transmutação](docs/TRANSMUTACAO.md): quatro itens livres viram um, com chance de elevar a raridade, animação, bônus garantidos por tentativas e suporte a cópias no inventário.

Na Transmutação, os atributos do resultado aparecem em pop-up sobre a mesma tela. Todos os marcos ficam em uma lista compacta e a aba Trocas converte itens livres em ouro (Comum a Raro) ou cristais (Épico a Deus).

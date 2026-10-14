Quero que você desenvolva um jogo 2D completo na Godot Engine, com foco em PC e dispositivos móveis, inspirado na estrutura de jogos do gênero "survivors-like" (como Vampire Survivors), mas com uma identidade própria e forte foco em RPG, classes, equipamentos, progressão e construção de personagem.

## CONCEITO GERAL
O jogo será um RPG 2D de sobrevivência em ondas.

O jogador começa com um personagem extremamente fraco, equipado apenas com uma arma básica. Conforme sobrevive às waves, derrota inimigos, ganha experiência e avança pelas fases, ele desbloqueia novas habilidades, equipamentos e melhorias.

A progressão deve dar ao jogador a sensação de:

- Começar fraco.
- Evoluir durante a partida.
- Criar uma build diferente a cada partida.
- Sobreviver a ondas cada vez maiores.
- Enfrentar inimigos e chefes.
- Desbloquear equipamentos e habilidades.
- Escolher entre diferentes classes.
- Avançar para mapas e fases mais difíceis.
- Voltar ao menu após a partida e usar recursos/progressão para desbloquear novos conteúdos.
O jogo NÃO deve ser simplesmente um clone de Vampire Survivors. Utilize a estrutura de survivors-like como referência, mas crie sistemas, interface, personagens, inimigos, habilidades, equipamentos e identidade visual próprios.

# TECNOLOGIA
Utilize:

- Godot Engine 4.x
- GDScript
- Jogo 2D
- Sistema de cenas da Godot
- Resources quando forem úteis para dados de personagens, itens, habilidades e inimigos.
- Código organizado e modular.
- Arquitetura que facilite adicionar novos personagens, mapas, inimigos, habilidades e equipamentos futuramente.
O projeto deve ser organizado de forma profissional.
Ultilize tudo que ja estiver pre pronto para agilizar a ideia. se na internet tiver personagem ja pre prontos, pode usar, seja criativo, ta liberado tudo. 

Crie um menu inicial bonito e funcional.

A tela inicial deve apresentar:
- Personagem principal visível no centro ou em destaque.
- Animação idle do personagem.
- Fundo animado.
- Botão "Jogar".
- Botão "Personagens".
- Botão "Equipamentos".
- Botão "Habilidades".
- Botão "Mapas".
- Botão "Melhorias".
- Botão "Configurações".
- Botão "Sair" no PC.
No celular, o botão Sair pode ser omitido.

O personagem do menu deve poder mudar conforme o personagem selecionado.

Crie transições suaves entre os menus.

# MENU DE PERSONAGENS / CLASSES
O jogo deverá possuir sistema de classes.

Comece implementando pelo menos:

### Guerreiro
Características:

- Vida alta.
- Defesa alta.
- Velocidade baixa/média.
- Ataques corpo a corpo.
- Bom para iniciantes.
- Dano inicial baixo.

### Mago
Características:

- Vida baixa.
- Defesa baixa.
- Dano mágico alto.
- Ataques à distância.
- Grande potencial de área.

### Arqueiro
Características:

- Velocidade alta.
- Ataques à distância.
- Dano médio.
- Grande alcance.
- Pode disparar vários projéteis.

 PC

- WASD.
- Setas direcionais como alternativa.
- Mouse para interfaces.

#Celular
Criar controles virtuais na tela:

- Joystick virtual para movimentação.
- Botões de interface quando necessário.
O joystick deve funcionar com toque e permitir movimentação em 360 graus.

O personagem deve possuir:

- Vida.
- Vida máxima.
- Mana ou recurso equivalente, caso necessário.
- Dano.
- Defesa.
- Velocidade.
- Alcance.
- Velocidade de ataque.
- Chance de crítico.
- Multiplicador de crítico.
- Experiência.
- Nível.
- Ouro.
- Estatísticas adicionais.

# SISTEMA DE COMBATE
O combate deve ser automático.

O jogador controla principalmente a movimentação.

As habilidades e armas devem atacar automaticamente de acordo com suas características.

Exemplos:

- Espada: golpe automático em inimigos próximos.
- Arco: dispara automaticamente contra inimigos.
- Bola de fogo: procura inimigos e lança projéteis.
- Espinhos: causa dano ao redor do personagem.
- Raio: atinge inimigos aleatórios.
- Machado: lança machados em determinada direção.
- Aura: causa dano continuamente ao redor do jogador.
As habilidades devem ter:

- Dano.
- Cooldown.
- Alcance.
- Área.
- Quantidade de projéteis.
- Velocidade.
- Duração.
- Knockback.
- Chance de crítico.
- Nível.

SISTEMA DE WAVES
O jogo deve possuir um sistema completo de waves.

# SISTEMA DE FASES
O jogo deverá possuir várias fases.

Exemplo:

### Fase 1 — Floresta
Ambiente:

- Floresta.
- Árvores.
- Pedras.
- Vegetação.
- Área relativamente aberta.
Inimigos:

- Slime.
- Goblin.
- Lobo.
- Goblin arqueiro.
Boss:

- Rei Goblin.

### Fase 2 — Cemitério
Inimigos:

- Esqueleto.
- Zumbi.
- Morcego.
- Necromante.
Boss:

- Senhor dos Mortos.

### Fase 3 — Vulcão
Inimigos:

- Demônio.
- Elemental de fogo.
- Criatura de lava.
Boss:

- Senhor da Lava.

### Fase 4 — Castelo
Inimigos:

- Cavaleiro.
- Mago sombrio.
- Vampiro.
- Guarda amaldiçoado.
Boss:

- Rei Vampiro.
O sistema deve permitir adicionar mapas futuramente sem precisar modificar profundamente o código.

# MAPA
Crie mapas maiores que a tela.

O jogador deve poder andar pelo mapa enquanto a câmera acompanha o personagem.

Utilize:

- Camera2D.
- TileMap/TileMapLayer conforme a versão da Godot.
- Limites do mapa.
- Obstáculos.
- Áreas visualmente diferentes.
- Decoração.
O mapa deve ter sensação de exploração mesmo sendo um survivors-like.

Evite deixar tudo completamente vazio.

INIMIGOS
Crie um sistema genérico de inimigos.

Cada inimigo deve possuir:

Vida.

Dano.

Velocidade.

Defesa.

Experiência concedida.

Ouro concedido.

Tipo.

Comportamento.

Crie pelo menos:

Slime.

Goblin.

Lobo.

Esqueleto.

Zumbi.

Morcego.

Arqueiro.

Mago.

Elite.

Mini-boss.

Boss.

Os inimigos devem possuir comportamentos diferentes.

Exemplos:

Slime:

Persegue o jogador.

Lobo:

Muito rápido.

Pouca vida.

Arqueiro:

Mantém distância.

Ataca à distância.

Mago:

Lança projéteis.

Elite:

Mais vida.

Mais dano.

Pode possuir efeitos especiais.

Boss:

Vida muito alta.

Ataques especiais.

Padrões diferentes de ataque.

Barra de vida própria.

 EXPERIÊNCIA E LEVEL UP
Os inimigos devem deixar experiência ao morrer.

Quando o jogador coleta experiência suficiente:

Sobe de nível.

O jogo pausa temporariamente.

Aparece uma tela de escolha de melhorias.

Exemplo:

"ESCOLHA UMA MELHORIA"

[ Espada +1 ]
Dano da espada +20%

[ Velocidade +5% ]
Velocidade de movimento +5%

[ Bola de Fogo ]
Desbloqueia Bola de Fogo

[ Vida Máxima +10% ]
Aumenta a vida máxima.

Apresente 3 ou 4 opções aleatórias.

O jogador escolhe uma.

Depois:

A interface fecha.

O jogo continua.

A próxima melhoria será sorteada futuramente.

HABILIDADES
As habilidades devem ser desbloqueadas DURANTE A PARTIDA.

Cada habilidade pertence à partida atual.

Ao terminar a partida, as habilidades temporárias devem ser resetadas.

Utilize um sistema de raridade para algumas habilidades:

Comum.

Incomum.

Rara.

Épica.

Lendária.

Não torne as habilidades lendárias excessivamente comuns.

EQUIPAMENTOS
Além das habilidades temporárias da partida, o jogo deverá possuir equipamentos.

Exemplos:

Espada.

Capacete.

Peitoral.

Luvas.

Calças.

Botas.

Anel.

Amuleto.

Cada equipamento pode modificar atributos.

Exemplo:

Espada de Ferro:
+5 Dano

Espada Flamejante:
+15 Dano
+10% dano de fogo

Botas do Vento:
+10% velocidade

Anel do Guerreiro:
+5% dano físico

Equipamentos podem possuir raridade:

Comum.

Incomum.

Raro.

Épico.

Lendário.

 DIFERENÇA ENTRE EQUIPAMENTO E HABILIDADE
É importante separar esses dois sistemas.

HABILIDADES:

São adquiridas durante a partida.

São temporárias.

Desaparecem ao terminar a partida.

Fazem parte da build daquela partida.

EQUIPAMENTOS:

Podem ser obtidos como recompensas.

Podem permanecer entre partidas.

Podem ser equipados no personagem.

Alteram os atributos iniciais.
SISTEMA DE LOOT
Inimigos podem deixar:

Experiência.

Ouro.

Poções.

Baús.

Equipamentos.

Itens especiais.

Bosses devem possuir maior chance de recompensas.

Ao derrotar um boss, mostrar uma tela especial de recompensa.

Exemplo:

"CHEFE DERROTADO!"

Você recebeu:

250 Ouro.

Espada Flamejante.

1 Cristal Arcano.

HUD DURANTE A PARTIDA
A interface da partida deve mostrar:

No topo:

Barra de vida.

Nível.

Barra de experiência.

Wave atual.
No canto:

Quantidade de ouro.

Ícones das habilidades equipadas.

Nível de cada habilidade.

Quando o boss aparecer:

Mostrar uma grande barra de vida no topo.

No celular, adaptar a interface para não cobrir a área jogável.

MENU DE PAUSA
Durante a partida:

PC:

ESC.

Celular:

Botão de pausa.

Menu:

Continuar.

Configurações.

Reiniciar partida.

Sair para o menu.

Ao sair, mostrar confirmação.

TELA DE GAME OVER
Quando o jogador morrer:

Mostrar:

"VOCÊ FOI DERROTADO"

Informações:

Wave alcançada.

Nível.

Inimigos derrotados.

Ouro obtido.

Tempo sobrevivido.

Bosses derrotados.

Botões:

Jogar novamente.

Menu principal.

TELA DE VITÓRIA
Quando o boss final da fase for derrotado:

Mostrar:

"FASE CONCLUÍDA!"

Exibir:

Tempo.

Wave.

Inimigos derrotados.

Ouro.

Recompensas.

Equipamentos encontrados.

Botões:

Próxima fase.

Jogar novamente.

Menu principal.
RESPONSIVIDADE
Este é um requisito MUITO importante.

O jogo precisa funcionar tanto em:

Computador.

Notebook.

Tablet.

Celular.

Utilize resolução e âncoras adequadas na interface.

A UI não deve depender de posições fixas.

Use:

Containers.

Anchors.

Layout responsivo.

Escalonamento adequado.

Safe areas quando necessário.

No PC:

WASD.

Teclado.

Mouse.

No celular:

Joystick virtual.

Interface touch.

Botão de pausa.

Os elementos da HUD devem se adaptar ao tamanho da tela.

CONFIGURAÇÕES
Criar menu de configurações com:

Volume geral.

Música.

Efeitos sonoros.

Qualidade gráfica.

Tela cheia no PC.

Resolução no PC.

Vibração no celular.

Tamanho da interface.

Idioma.

Salvar configurações.

SISTEMA DE SAVE
Criar sistema de salvamento.

Salvar:

Personagens desbloqueados.

Classes desbloqueadas.

Equipamentos.

Melhorias permanentes.

Mapas desbloqueados.

Melhor pontuação.

Ouro.

Progresso geral.

O save deve ser feito localmente utilizando uma estrutura segura e simples, por exemplo JSON ou o sistema apropriado da Godot.

Criar também uma função para carregar o save quando o jogo iniciar.

SISTEMA DE DIFICULDADE
Criar uma fórmula de dificuldade escalável.

Por exemplo:

Conforme as waves aumentam:

HP dos inimigos aumenta.

Dano aumenta.

Quantidade aumenta.

Velocidade pode aumentar.

Porém, evite simplesmente multiplicar tudo de forma exagerada.

O jogo deve continuar permitindo builds fortes.


EFEITOS VISUAIS
Adicionar feedback visual.

Exemplos:

Número de dano aparecendo.

Flash vermelho quando inimigo recebe dano.

Partículas ao morrer.

Partículas ao coletar XP.

Efeito de level up.

Efeito de crítico.

Efeito especial para habilidades lendárias.

Explosões.

Efeitos de fogo.

Efeitos de gelo.

Efeitos mágicos.

Adicionar pequenas animações para deixar o combate satisfatório.

ÁUDIO
Criar estrutura para:

Música do menu.

Música durante a fase.

Música de boss.

Som de ataque.

Som de dano.

Som de morte.

Som de level up.

Som de coleta de XP.

Som de item.

Som de vitória.

Som de derrota.

Não precisa criar arquivos de áudio reais se eles não estiverem disponíveis. Nesse caso, deixe a estrutura preparada para receber os arquivos posteriormente.

ARQUITETURA DO CÓDIGO
Não coloque toda a lógica em um único script.

Crie sistemas separados, como:

GameManager
WaveManager
EnemyManager
SpawnManager
PlayerController
PlayerStats
AbilityManager
EquipmentManager
LootManager
ExperienceManager
SaveManager
AudioManager
UIManager

Utilize Autoloads quando fizer sentido.

Os dados de:

Classes.

Habilidades.

Equipamentos.

Inimigos.

Mapas.

devem ser facilmente editáveis.

Sempre que possível, utilizar Resources da Godot para esses dados.

SISTEMA DE DADOS
Crie Resources como:

CharacterData
ClassData
AbilityData
EquipmentData
EnemyData
WaveData
MapData

Por exemplo:

AbilityData:

Nome.

Descrição.

Ícone.

Dano.

Cooldown.

Área.

Alcance.

Nível máximo.

Raridade.

Tipo de ataque.

Efeitos.

Isso permitirá adicionar conteúdo sem precisar reescrever o sistema.

RIMEIRO PROTÓTIPO
Não tente começar criando 100 sistemas ao mesmo tempo.

Primeiro implemente um vertical slice jogável:

Menu principal.

Seleção do Guerreiro.

Entrada na primeira fase.

Movimento.

Inimigos perseguindo o jogador.

Ataque automático.

XP.

Level up.

Escolha de habilidade.

Waves.

Boss.

Game Over.

Vitória.

Retorno ao menu.

Depois disso, expandir:

Outras classes.

Equipamentos.

Mais mapas.

Mais inimigos.

Mais habilidades.

Sistema permanente de progressão.

IDENTIDADE VISUAL
Crie uma estética de RPG 2D.

Preferencialmente:

Pixel art ou arte 2D estilizada.

Cores fortes.

Efeitos de partículas.

Interface limpa.

Ícones claros.

Personagens facilmente reconhecíveis.

O menu deve transmitir a sensação de um RPG.

Durante a partida, a interface deve ser minimalista para não atrapalhar a jogabilidade.
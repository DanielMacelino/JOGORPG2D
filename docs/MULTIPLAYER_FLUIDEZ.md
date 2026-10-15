# Movimento e sincronizacao online

Protocolo atual: ashenwild-coop-14. Inclui os inimigos pixel art, o Demônio da Fenda, a Eclosão do Éter, loot individual do Baú Raivoso e sincronização do modelo de arma equipado por cada jogador. Todos os participantes precisam usar a mesma versão do jogo no próximo executável. Esta alteração não exporta o jogo.

## Pressão por tamanho do grupo

O dano de monstros e chefes recebe pressão adicional de +20% com dois jogadores, +30% com três e +40% com quatro. Um jogador usa multiplicador adicional 1,0. O cálculo acontece no anfitrião ao gerar inimigos, inclusive chefes e elites. O HP segue `1 + 0,80 × jogadores adicionais`; o dano final segue `(1 + 0,08 × jogadores adicionais) × pressão`. Para grupos de 2/3/4 jogadores, o dano final em relação ao solo é 1,296 / 1,508 / 1,736. Em relação à atualização anterior, o dano sobe aproximadamente 9% / 13% / 17%. Os formatos e frequências dos pacotes de movimento permanecem iguais.

`tests/coop_pressure_forge.gd` verifica os inimigos e chefes gerados com 1 a 4 participantes, o multiplicador offline e as ações/comparações da Forja.

## Causas corrigidas

O cliente ja previa movimentos, mas o anfitriao executava somente a ultima direcao recebida por frame e confirmava a sequencia mais recente. Isso nao correspondia ao historico inteiro previsto pelo cliente. Ao receber posicoes, o cliente reposicionava o personagem e repetia comandos usando um metodo de colisao diferente do servidor, provocando correcoes e trancos.

Agora cada comando representa um passo de 1/60 s. As posicoes iniciais da equipe chegam junto da mensagem confiavel de inicio, antes de liberar os controles, evitando a primeira correcao de spawn. Cliente, repeticao de comandos e anfitriao usam o mesmo deslocamento e deslizamento em colisao. O anfitriao confirma somente comandos efetivamente consumidos. Cada envio carrega os ultimos oito comandos ainda pendentes, protegendo contra perdas sem usar retransmissao confiavel para movimento. Pausa e morte descartam deslocamentos indevidos. Correcoes pequenas convergem suavemente; deslocamentos grandes e morte permanecem autoritativos.

## Fluxos separados

- Jogadores e confirmacoes: pacote prioritario independente, 60 atualizacoes por segundo no canal 2. No teste com dois jogadores, o maior pacote tinha 330 bytes. O cliente anda no proximo passo local, antes de qualquer resposta da rede.
- Entidades do mundo: ate 20 atualizacoes por segundo no canal 1, em pequenos lotes independentes, normalmente abaixo de 900 bytes. Perder um lote nao descarta a atualizacao de todo o mundo. Remocoes usam mensagens confiaveis pequenas e um registro de sequencias impede reaparecer entidades por pacotes atrasados.
- A compressao/envio dos lotes tem orcamento aproximado de 3 ms por frame; a captura seguinte espera o envio pendente para evitar fila crescente. O mundo pausado dispensa recapturar centenas de entidades.
- HUD: dez atualizacoes por segundo; movimento e interpolacao continuam independentes. Personagens e monstros remotos usam extrapolacao curta e limitada quando uma atualizacao atrasa.

snapshot_codec.gd codifica os campos em listas posicionais antes da compressao, preservando tipos e reduzindo nomes repetidos. O simulador de perdas/atraso e desabilitado em jogo normal e so pode ser configurado em projetos de teste isolados.

## Validacao

A reanimação conserva o progresso quando o ajudante se afasta ou toma dano. Receber dano suspende o avanço por 0,8 segundo; depois ele continua se houver um aliado vivo por perto. A escolha coletiva de habilidades mantém a reanimação congelada. As barras da equipe no canto inferior esquerdo mostram nome, retrato, vida e progresso de reanimação no anfitrião e nos clientes.

A pausa oferece Configurações com volumes e tamanho da interface. Esc volta das configurações à pausa e depois retoma a partida, inclusive no solo com a árvore de cena pausada. No online, abrir esse menu continua sendo uma pausa local. Os ícones de habilidades mostram o bônus acumulado (por exemplo, +48% de velocidade de ataque); valores fixos usam a unidade real e o tooltip detalha todos os efeitos.

network_motion.gd compara 120 passos do cliente e servidor, incluindo parede e movimento diagonal, perda intencional de um em cada tres envios, pacotes duplicados, pausa, morte, fidelidade do formato e rejeicao de entidades removidas.

run_online.ps1 aceita -Players, -DelayMs, -JitterMs, -Loss e -Stress. O atraso e injetado nos dados de movimento, jogadores e mundo sobre conexoes ENet reais locais. Mensagens confiaveis de lobby/escolhas/resultados nao recebem essa simulacao adicional. A carga cria aproximadamente 397 entidades, alem dos jogadores. O fixture ENet remove obstaculos na verificacao de entrada; o teste separado verifica equivalencia das colisoes em paredes. Os testes tambem verificam combate, XP coletivo, escolhas, reanimacao, musica, recompensas individuais, retorno a sala e derrota do grupo.

Testes locais nao medem renderizacao na GPU dos amigos, teclados/monitores ou a qualidade real do Radmin. A execucao imediata do movimento elimina a espera pela resposta do servidor, mas nao elimina fisicamente a latencia da rede nem garante FPS em qualquer computador.

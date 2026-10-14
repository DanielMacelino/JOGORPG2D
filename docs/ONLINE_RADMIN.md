# Cooperativo pelo Radmin VPN

O menu inicial tem **Jogar online**, com hospedagem e entrada por IP. Uma sala suporta de dois a quatro jogadores, incluindo o anfitrião.

## Como jogar

1. Todos devem usar a mesma versão do jogo e entrar na mesma rede do Radmin VPN. Veja a [ajuda oficial do Radmin](https://www.radmin-vpn.com/help/index.html).
2. O anfitrião abre Jogar online, preenche o nome e escolhe seu personagem e a porta. Na aba **Criar sala**, seleciona dificuldade, região e fase diretamente nessa página.
3. Clica em Hospedar sala. A porta padrão é **24567 UDP**. O jogo mostra os endereços locais que começam por `26.`; confira o IP correto no aplicativo Radmin VPN. O anfitrião também pode ajustar o destino enquanto aguarda os amigos na sala, respeitando o progresso de todos.
4. Os amigos abrem Jogar online, escolhem seus personagens, abrem a aba **Entrar na sala**, informam o IP do Radmin do anfitrião e a mesma porta, e clicam em Entrar na sala.
5. Quando todos aparecerem na lista, o anfitrião clica em Iniciar expedição em grupo.

A fase deve estar desbloqueada no save de todos. Cada jogador pode usar uma classe diferente, com seus próprios equipamentos, talentos e nível permanente.

Se a conexão falhar, confira o IP, a porta e se os computadores estão conectados na mesma rede do Radmin. Permita o executável do jogo no Firewall do Windows para a rede usada pelo Radmin; não é necessário desativar o firewall. O jogo usa ENet sobre UDP, conforme a [documentação do Godot](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html). A porta pode ser alterada no formulário se já estiver ocupada.

## Durante a expedição

- O anfitrião simula movimento, ataques automáticos, habilidades, invocações, monstros, ondas, chefes e objetivos.
- Os convidados recebem posições, vida, projéteis, áreas perigosas, invocações e estado dos objetivos. O cenário usa a mesma semente em todos os computadores. O movimento local responde imediatamente ao input e depois é corrigido pelo anfitrião; os estados chegam 30 vezes por segundo.
- Monstros consideram todos os jogadores vivos. A ameaça e a provocação do Sentinela podem proteger os aliados.
- Qualquer jogador vivo pode coletar orbes e selar fendas. Ouro e XP coletados são compartilhados. Existe uma única barra de XP e todos sobem de nível juntos; cada classe escolhe suas habilidades individualmente.
- Ao subir de nível, a partida pausa para todos. Quem escolheu vê **Esperando player(s)** e os nomes de quem ainda falta. O jogo continua quando todos terminam; desconectar alguém não bloqueia a escolha dos demais. O menu de Escape continua sendo local e não pausa a partida.
- A escolha mostra três cartões sem rolagem: lado a lado em janelas largas e empilhados nas estreitas, com texto ajustado ao espaço. As cartas mostram raridade e nível atual → próximo, e habilidades no nível máximo não são oferecidas.
- Ataques aliados não causam dano aos jogadores.
- Um jogador caído acompanha os aliados. A derrota ocorre quando todos caem ou quando o altar é destruído. Os caídos retornam com vida na próxima expedição.
- A vida dos inimigos aumenta 70% por aliado adicional, o dano aumenta 8% por aliado e as ondas recebem mais monstros.
- Na conclusão, cada jogador recebe um drop adequado à sua classe, sorteado contra sua própria coleção. Ouro, cristais, XP permanente, conquistas e progresso ficam no save de seu computador. Resultados repetidos não duplicam recompensas.
- O anfitrião pode retornar à sala com o grupo, repetir a expedição, selecionar a próxima fase ou escolher outro destino disponível para todos. Para mudar a classe, encerre a sala e configure uma nova. Antes de conectar, nome, personagem, IP e destino permanecem preenchidos ao navegar ou redimensionar a janela.

## Limites desta versão

A entrada acontece na sala de espera, antes da partida. O anfitrião precisa permanecer conectado; sua saída encerra a sessão. Não há migração de anfitrião nem reconexão no meio de uma expedição. Sair antes da tela de resultados não salva as recompensas daquela rodada. Não há servidor público, matchmaking ou conta compartilhada: a conexão usa o IP do anfitrião.

## Verificação

`tests/run_online.ps1` abre instâncias reais do Godot com ENet em `127.0.0.1` e saves isolados. Use `-Players 4` para testar uma sala cheia. O teste verifica movimento remoto, dano real e seu proprietário, XP compartilhado, escolhas individuais, monstros, projéteis, áreas de perigo, fendas e invocações nos convidados, sobrevivência após um aliado cair, vitória, recompensas, proteção contra resultado duplicado, retorno à sala, avanço coletivo da fase 5 para a 6 e uma segunda expedição com derrota de todo o grupo.

`tests/run_regression.ps1` verifica o modo solo, progressão e menus, incluindo a largura da página online em oito resoluções e dois tamanhos de texto. Nenhum desses testes altera o save do jogador ou captura telas.

O teste também verifica a pausa coletiva, congelamento do mundo durante escolhas, evolução conjunta e movimento local antes da resposta do servidor. O teste local verifica o protocolo e a partida; a conexão entre computadores pela rede Radmin depende da configuração de rede e firewall de cada participante.

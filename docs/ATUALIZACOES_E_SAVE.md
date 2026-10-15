# Atualizações e progresso

O projeto grava `user://ashenwild_save.json`, separado do executável e do PCK. No Windows, com a configuração atual, o arquivo fica em `%APPDATA%\Godot\app_userdata\Ashenwild- Riftbound Survivors\ashenwild_save.json`. Atualizar os arquivos do jogo preserva esse arquivo. Antes de atualizar manualmente, fechar o jogo e guardar uma cópia do save oferece uma recuperação adicional.

Para manter essa continuidade, preservar `application/config/name` e o diretório de dados. Se algum deles mudar, implementar a migração do diretório anterior. Mudanças no formato dos dados devem preservar campos antigos e migrar identificadores de equipamentos, talentos e progresso; evitar abrir um save migrado em versões antigas sem backup.

## Modelo proposto, ainda não implementado

1. Save local como fonte principal e backups automáticos rotativos, especialmente antes de migrações.
2. Distribuir executável e PCK em versões compiladas no GitHub Releases. Um launcher separado pode verificar a versão, baixar e substituir os arquivos do jogo quando ele estiver fechado, sem tocar no diretório do save. Um push no código sozinho não atualiza o executável dos amigos.
3. Backup remoto opcional. A máquina do anfitrião acessível por Radmin pode receber uma cópia, mas o progresso continua sendo salvo localmente quando ela não estiver disponível. Cada jogador precisa de um identificador persistente e revisões para evitar sobrescrever um save novo com um antigo.

Um banco local não é necessário para essa distribuição: o JSON existente já separa dados e instalação. Contas com sincronização entre computadores ou uma economia validada centralmente justificariam um serviço próprio; esse seria um projeto separado da atualização dos arquivos do jogo.

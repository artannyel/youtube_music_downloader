# Plano de Feature - Player de Mídia Integrado (Media Player)

Este documento detalha o plano de desenvolvimento e as subtarefas para a reprodução de mídias online (via streaming do YouTube) e offline (arquivos locais baixados), além da visualização de playlists.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *2. Tecnologias*, *4. Regras de Negócio: R7. Tela de Player & Detalhes Integrada*, *R8. Tela de Playlist e Lote*)

---

## 🎯 Objetivo
Implementar um player integrado de áudio e vídeo que atenda a duas situações:
1. **Online (Streaming)**: Reproduzir vídeos e áudio diretamente do YouTube na tela de detalhes antes de realizar o download.
2. **Offline**: Reproduzir arquivos salvos na pasta local do dispositivo na mesma tela de player ao clicar em itens do histórico de downloads.
Também deve fornecer uma tela de listagem de playlists/lotes de URLs para navegação individual e download massivo.

---

## 📈 Plano de Desenvolvimento

1. **Camada de Dados & Provedores de Streaming (Data/Domain)**:
   - Utilizar o `youtube_explode_dart` para obter URLs diretas de streaming de áudio/vídeo do YouTube.
   - Definir estado do player (`PlayerNotifier`) para monitorar o status do player (idle, loading, playing, paused, completed, progress).
2. **Implementação do Player Online**:
   - Para vídeos: Integrar o `youtube_player_flutter` que renderiza o iframe/vídeo do YouTube nativamente na UI.
   - Para áudio: Integrar o `just_audio` para fazer o buffer do stream de áudio em segundo plano com notificações nativas do sistema.
3. **Implementação do Player Offline**:
   - Para vídeos locais: Integrar `chewie` com `video_player` apontando para o arquivo local (`File(targetPath)`).
   - Para áudio local: Apontar `just_audio` para o path local correspondente.
4. **Tela de Detalhes da Playlist e Lote (Presentation)**:
   - Criar a visualização que exibe os itens carregados da playlist ou lote de links.
   - Fornecer botão para reproduzir individualmente cada item no player ou baixar o conjunto completo.
5. **Lógica de Fila e Transição Automática (Domain/Data)**:
   - Implementar fila concatenada (`ConcatenatingAudioSource` no `just_audio` e gerenciamento manual no Riverpod para vídeo) para avanço automático de faixas.
   - Construir controles de reprodução (Anterior/Próximo) e botão para abrir a gaveta (bottom sheet) de faixas da fila.
6. **Integração de Relacionados (Data/Presentation)**:
   - Obter lista de vídeos relacionados a partir do `youtube_explode_dart` e renderizar cards dinâmicos na interface abaixo das informações do vídeo.

---

## 📋 Lista de Tarefas (Subtasks)

- [ ] **T7.1. Implementar Gerenciamento de Estado do Player (`PlayerNotifier`)**
  - Criar `lib/features/media_player/presentation/providers/player_provider.dart`:
    - Estado contendo: `currentVideoId`, `isPlaying`, `isOnline`, `duration`, `position`, `playbackType` (video/audio).
    - Métodos para Play, Pause, Seek e carregamento de mídia.
- [ ] **T7.2. Criar Componente de Player Online (YouTube)**
  - Implementar em `lib/features/media_player/presentation/widgets/online_youtube_player.dart`:
    - Instanciar `YoutubePlayerController`.
    - Renderizar o widget `YoutubePlayer` com layout customizado (ocultar barras desnecessárias do YouTube, manter controles elegantes do app).
- [ ] **T7.3. Criar Componente de Player Offline (Local)**
  - Implementar em `lib/features/media_player/presentation/widgets/offline_media_player.dart`:
    - Para vídeo: Inicializar `VideoPlayerController.file` e vinculá-lo ao `ChewieController` para controles de tela cheia, velocidade e legenda (se houver).
    - Para áudio: Carregar arquivo local no `just_audio` e exibir uma bela tela de capa de álbum (utilizando a miniatura/thumbnail salva no banco).
- [ ] **T7.4. Desenhar Tela Principal `MediaPlayerPage`**
  - Implementar em `lib/features/media_player/presentation/pages/media_player_page.dart`:
    - Player no topo (Online ou Offline dependendo do contexto).
    - Seção inferior com título do vídeo, nome do canal, descrição sanfonada (collapse/expand).
    - Botão destacado "Configurar Download" (se online) que abre as opções de download (formato, qualidade, subpasta).
- [ ] **T7.5. Desenhar Tela `PlaylistDetailsPage`**
  - Implementar em `lib/features/media_player/presentation/pages/playlist_details_page.dart`:
    - Cabeçalho com informações da playlist (título, autor, miniatura).
    - Lista de faixas com thumbnail e duração.
    - Clicar em qualquer card de faixa abre a `MediaPlayerPage` correspondente para reproduzir online.
    - Botão flutuante ou fixo "Baixar Playlist" que passa a lista inteira de tarefas para o setup de download.
- [ ] **T7.6. Painel de Fila de Reprodução (Queue & Autoplay)**
  - Implementar transição automática para a próxima faixa no `PlayerNotifier`.
  - Integrar os botões visuais de "Anterior" e "Próximo" no painel de controle do player.
  - Criar um bottom sheet deslizante (`QueueBottomSheet`) exibindo a listagem das faixas da fila atual permitindo a seleção manual.
- [ ] **T7.7. Integração de Vídeos Relacionados (Infinite Navigation)**
  - Fazer chamada da API `youtubeExplode.videos.getRelated(video)` no `ExploreRepository`.
  - Desenhar seção de recomendados abaixo do player principal e atualizar dinamicamente o estado ao tocar em qualquer item da lista.

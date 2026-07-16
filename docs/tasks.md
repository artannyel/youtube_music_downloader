# Lista Mestra de Tarefas (Tasks) - YouTube Music & Video Downloader

Esta é a lista mestra com as tarefas divididas por funcionalidade. Cada tarefa aponta para a especificação correspondente e o plano detalhado de sua feature.

---

## 📋 Legenda de Referências
- **[Spec]**: Consulte [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md)
- **[Plan]**: Consulte [plan.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/plan.md)

---

## 🛠️ Grupo de Tarefas 0: Infraestrutura e Configuração Inicial
*Plano de Feature:* [feature_0_infra.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_0_infra.md)

- [x] **T0.1. Adição de Dependências** `[Spec: Seção 2]`
  - Adicionar pacotes no `pubspec.yaml` (Riverpod, GoRouter, youtube_explode_dart, extractor, isar, isar_flutter_libs, flutter_local_notifications, path_provider, permission_handler, shared_preferences, file_picker).
- [x] **T0.2. Configuração de Permissões Android** `[Spec: Seção 2]`
  - Adicionar permissões no `AndroidManifest.xml` (INTERNET, Armazenamento, Notificações, Foreground Service).
- [x] **T0.3. Design System & Tema Moderno** `[Spec: Seção 3 e 5]`
  - Criar o tema escuro moderno no Flutter com paleta de cores clean.
- [x] **T0.4. Roteamento Declarativo com GoRouter** `[Spec: Seção 3]`
  - Implementar o `GoRouter` e mapear as rotas iniciais das telas (/explore, /download-setup, /downloads, /settings).
- [x] **T0.5. Inicialização do Banco Isar** `[Spec: Seção 5]`
  - Criar o serviço `IsarService` e abrir a instância do banco local para tarefas de download.

---

## 🔍 Grupo de Tarefas 1: Exploração e Busca (Explore)
*Plano de Feature:* [feature_1_explore.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_1_explore.md)

- [x] **T1.1. Criar Entidade `YoutubeVideoResult`** `[Spec: Seção 4 - Feature 1]`
  - Implementar classe em `lib/features/explore/domain/entities/youtube_video_result.dart`.
- [x] **T1.2. Implementar `ExploreRepository` e Service** `[Spec: Seção 4 - Feature 1]`
  - Criar o repositório e o serviço de busca que utiliza `youtube_explode_dart`.
- [x] **T1.3. Configurar Gerenciamento de Estado (Riverpod)** `[Spec: Seção 4 - Feature 1]`
  - Criar o notifier para controlar buscas e resultados.
- [x] **T1.4. Desenhar Tela `ExploreScreen`** `[Spec: Seção 5]`
  - Implementar barra de pesquisa e grid/lista moderno de resultados.
- [x] **T1.5. Paginação de Resultados (Scroll Infinito)** `[Spec: Seção 4 - Feature 1]`
  - Implementar scroll infinito com `ScrollController` e método de carregamento da próxima página no repositório e notifier.

---

## ⚙️ Grupo de Tarefas 2: Tela de Configuração de Download (Download Setup)
*Plano de Feature:* [feature_2_download_setup.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_2_download_setup.md)

- [x] **T2.1. Conversor de URL de Música** `[Spec: Seção 4 - R2]`
  - Criar validador e reescritor de URLs do YouTube Music (`music.youtube.com` -> `youtube.com`).
- [x] **T2.2. Parser de Metadados e Streams** `[Spec: Seção 4 - Feature 2]`
  - Implementar o parser para obter dados do vídeo/playlist selecionada.
- [x] **T2.3. Validador de Diretório Existente** `[Spec: Seção 4 - R1]`
  - Criar lógica que verifica no armazenamento se a subpasta de salvamento já existe e retorna o alerta correspondente.
- [ ] **T2.4. Interface de Setup de Mídia/Playlist** `[Spec: Seção 4 - Feature 3]`
  - Tela para escolher o formato (Vídeo/Áudio), qualidade desejada e campo de subpasta (pré-preenchido para playlists).
  - Exibir toast/mensagem se a pasta inserida já existir.

---

## 🚀 Grupo de Tarefas 3: Motor de Downloads e Cookies (Downloader Engine)
*Plano de Feature:* [feature_3_downloader_engine.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_3_downloader_engine.md)

- [x] **T3.1. Inicialização do Extractor (yt-dlp)** `[Spec: Seção 2 e 4 - Feature 3]`
  - Configurar e instanciar o `YoutubeDLFlutter` na inicialização do app.
- [x] **T3.2. Integração com Persistência de Cookies** `[Spec: Seção 4 - R5]`
  - Implementar injeção automática do arquivo de cookies `--cookies` nos parâmetros do `extractor` se o arquivo estiver configurado.
- [x] **T3.3. Algoritmo de Fallback de Qualidade** `[Spec: Seção 4 - R3]`
  - Escrever o algoritmo que compara a qualidade selecionada com as qualidades disponíveis e escolhe o fallback mais próximo.
- [x] **T3.4. Processador de Downloads Concorrentes** `[Spec: Seção 4 - Feature 4]`
  - Criar o gerenciador da fila de downloads integrando progressos em tempo real com o motor.
- [x] **T3.5. Embutir Capa (Thumbnail) nas Músicas** `[Spec: Seção 4 - R6]`
  - Passar as flags correspondentes no `DownloadRequest` para embutir a miniatura como artwork do áudio.

---

## 🔔 Grupo de Tarefas 4: Sincronização de Notificações com Ações (Notifications)
*Plano de Feature:* [feature_4_notifications.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_4_notifications.md)

- [x] **T4.1. Configuração do Canal de Notificações do Android** `[Spec: Seção 4 - R4]`
  - Registrar canal no sistema com suporte a progresso e botões.
- [x] **T4.2. Notificação de Progresso Ativo** `[Spec: Seção 4 - R4]`
  - Integrar a atualização em tempo real do download com a barra de progresso da notificação.
- [x] **T4.3. Botões Interativos (Cancelar/Pausar)** `[Spec: Seção 4 - R4]`
  - Adicionar as ações interativas de controle na bandeja de notificação.

---

## 🗄️ Grupo de Tarefas 5: Banco de Dados & Histórico (Downloads History)
*Plano de Feature:* [feature_5_downloads_history.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_5_downloads_history.md)

- [ ] **T5.1. Repositório Isar para Downloads** `[Spec: Seção 5]`
  - Implementar operações de salvar, ler, deletar e atualizar `DownloadTask`.
- [ ] **T5.2. Tela de Lista de Downloads** `[Spec: Seção 4 - Feature 4]`
  - Construir interface com abas ("Em Progresso" / "Concluídos").
- [ ] **T5.3. Interação com Arquivos Locais** `[Spec: Seção 4 - Feature 4]`
  - Permitir que o usuário abra o arquivo baixado ou explore a pasta pelo aplicativo.

---

## ⚙️ Grupo de Tarefas 6: Tela de Ajustes (Settings)
*Plano de Feature:* [feature_6_settings.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_6_settings.md)

- [ ] **T6.1. Seletor de Arquivos para Cookies** `[Spec: Seção 4 - R5]`
  - Interface para importar o arquivo de cookies usando `file_picker` e salvar seu path.
- [ ] **T6.2. Configuração de Diretório Base** `[Spec: Seção 4 - R1]`
  - Interface para visualizar o diretório de downloads padrão ou alterá-lo.

---

## 🎵 Grupo de Tarefas 7: Player de Mídia Integrado (Media Player)
*Plano de Feature:* [feature_7_media_player.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_7_media_player.md)

- [ ] **T7.1. Controladores e Estado de Reprodução (Riverpod)** `[Spec: Seção 4 - R7]`
  - Desenvolver o gerenciador do player (`PlayerNotifier`) para monitorar URL atual, estado de carregamento, play/pause e progresso.
- [ ] **T7.2. Tela de Player Integrado (Vídeo & Áudio Online)** `[Spec: Seção 4 - R7]`
  - Implementar o visualizador usando `youtube_player_flutter` integrado na tela para carregar vídeos do YouTube online.
- [ ] **T7.3. Suporte a Reprodução de Arquivos Locais (Offline)** `[Spec: Seção 4 - R7]`
  - Configurar carregamento de arquivos salvos em disco usando `chewie` (vídeos) e `just_audio` (músicas).
- [ ] **T7.4. Tela de Playlist e Lote** `[Spec: Seção 4 - R8]`
  - Criar interface para renderizar listagens de playlists e lotes de links com opção de baixar todos de forma massiva e interagir com itens individuais.

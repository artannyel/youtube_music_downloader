# Plano de Feature - Tela de Configuração de Download (Download Setup)

Este documento detalha o plano de desenvolvimento e as subtarefas para a funcionalidade de Configuração do Download.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *4. Regras de Negócio: Feature 2 - Link Input & Playlist Parsing*, *Feature 3 - Download Configurations & Rules*, *R1. Local de Armazenamento*, *R2. Conversão de URLs*)

---

## 🎯 Objetivo
Permitir que o usuário insira um link direto de vídeo/áudio ou playlist, faça a conversão necessária (YouTube Music para YouTube normal), decodifique os metadados dos formatos e streams disponíveis, configure a qualidade desejada de vídeo ou áudio, e defina uma subpasta de salvamento com a verificação/alerta de diretório existente.

---

## 📈 Plano de Desenvolvimento

1. **Validador e Normalizador de URLs (Data/Domain)**:
   - Implementar a rotina utilitária que substitui `music.youtube.com` por `youtube.com` na string de URL.
2. **Parser de Metadados de Mídia (Data)**:
   - Utilizar `youtube_explode_dart` para identificar se a URL corresponde a um único vídeo ou a uma playlist completa.
   - Extrair a lista de streams e resoluções disponíveis para alimentar a seleção na UI.
3. **Gerenciador de Diretórios Nativos (Data/Domain)**:
   - Implementar método para verificar se o diretório de destino `<DownloadsRoot>/videos/subpasta` ou `<DownloadsRoot>/musicas/subpasta` já existe localmente no aparelho.
4. **Camada de Apresentação (Presentation)**:
   - Criar formulário de download moderno contendo:
     - Tipo de download: Vídeo (MP4) ou Música (MP3).
     - Qualidades disponíveis (dropdown populado com base no vídeo).
     - Campo de subpasta (caso seja playlist, preencher automaticamente com o nome da playlist).
     - Alerta visual no formulário caso a subpasta informada já exista no sistema ("*A pasta já existe. Novos arquivos serão adicionados a ela.*").
     - Botão para iniciar o download adicionando o item à fila.

---

## 📋 Lista de Tarefas (Subtasks)

- [ ] **T2.1. Criar Utilitário de Normalização de URLs**
  - Implementar em `lib/core/utils/url_parser.dart` uma função estática:
    - `String normalizeYoutubeUrl(String url)`: Substitui `music.youtube.com` por `youtube.com`.
- [ ] **T2.2. Implementar Serviço de Carregamento de Metadados**
  - Criar interface `DownloadSetupRepository` e sua implementação para:
    - `Future<MediaMetadata> fetchMetadata(String url)`: Obtém título, miniatura, duração e lista de qualidades de streams de vídeo/áudio.
    - Suportar detecção e parsing de playlists completas.
- [ ] **T2.3. Implementar Verificação de Existência de Diretórios**
  - Criar utilitário `StorageDirectoryHelper` para verificar a pasta padrão:
    - Se a pasta do subdiretório existir (usando `Directory(path).existsSync()`), retornar `true` para disparar o aviso visual na tela de configuração.
- [ ] **T2.4. Desenhar Tela `DownloadSetupScreen`**
  - Implementar em `lib/features/download_setup/presentation/pages/download_setup_page.dart`:
    - Card de metadados com thumbnail e título da mídia.
    - Seletores de Formato (Vídeo / Áudio) e Qualidade.
    - Campo de input para Subpasta com comportamento dinâmico (auto-preencher com nome da playlist).
    - Aviso de conflito de diretório (Snackbar ou texto em destaque amarelo/vermelho indicando que a pasta já existe).
    - Ação para despachar o comando de download adicionando no estado global do gerenciador.

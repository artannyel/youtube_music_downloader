# Plano de Feature - Motor de Downloads e Cookies (Downloader Engine)

Este documento detalha o plano de desenvolvimento e as subtarefas para o Motor de Downloads e suporte a cookies.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *4. Regras de Negócio: Feature 3 - Download Configurations & Rules (Algoritmo de Fallback)*, *R5. Cookies para Conteúdo Restrito*, *6. Data Models Spec*)

---

## 🎯 Objetivo
Integrar o pacote `extractor` para executar o download físico do YouTube de forma eficiente através do `yt-dlp`. O motor deve suportar caminhos de cookies personalizados e o algoritmo de fallback inteligente de qualidades (para playlists e vídeos).

---

## 📈 Plano de Desenvolvimento

1. **Inicialização do Core Downloader**:
   - Inicializar a instância do `YoutubeDLFlutter` durante a inicialização do app, ativando suporte a FFmpeg e Aria2c.
2. **Algoritmo de Fallback de Qualidades (Domain)**:
   - Implementar uma função que recebe a qualidade desejada pelo usuário e a lista de qualidades reais disponíveis do vídeo, retornando a maior qualidade disponível igual ou inferior à desejada.
3. **Mecanismo de Cookies (Data)**:
   - Recuperar o caminho do arquivo de cookies configurado no `SharedPreferences` e passá-lo como argumento `-cookies [caminho]` nas requisições do `extractor`.
4. **Fila e Processamento (Domain/Data)**:
   - Criar um gerenciador de fila de downloads (`DownloadQueueManager`) que gerencia a concorrência dos downloads ativos, reportando velocidade, porcentagem e tempo estimado (ETA) para a interface do usuário.
5. **Incorporação de Thumbnail em Músicas (Data)**:
   - Configurar o `DownloadRequest` do `extractor` com a flag de embutir thumbnail (`--embed-thumbnail` / `--write-thumbnail`) para downloads de áudio.

---

## 📋 Lista de Tarefas (Subtasks)

- [x] **T3.1. Inicializar o YoutubeDLFlutter**
  - Implementar chamada em `main.dart` para configurar o `extractor`:
    ```dart
    final youtubeDL = YoutubeDLFlutter.instance;
    await youtubeDL.initialize(enableFFmpeg: true, enableAria2c: true);
    ```
- [x] **T3.2. Implementar Algoritmo de Fallback de Qualidade**
  - Criar classe de utilitários `QualityMatcher`:
    - Filtrar resoluções de vídeos (ex: se pediu `1080p` mas o vídeo tem no máximo `720p`, selecionar `720p`).
    - Comparar taxas de áudio (ex: se pediu `320kbps` mas o máximo é `192kbps`, selecionar `192kbps`).
- [x] **T3.3. Injetar Cookies na Execução do Extractor**
  - No repositório de download, resgatar o caminho persistido do arquivo de cookies do `SharedPreferences`.
  - Se o caminho do arquivo for válido e o arquivo existir, anexar a flag correspondente na inicialização da classe `DownloadRequest` do `extractor`.
- [x] **T3.4. Criar Gerenciador de Downloads (`DownloadQueueManager`)**
  - Implementar Riverpod `StateNotifier` ou `Notifier` em `lib/features/downloader_engine/presentation/providers/download_queue_provider.dart`:
    - Monitorar eventos do Stream de progresso do `extractor` (velocidade, porcentagem, ETA).
    - Atualizar o estado da tarefa em tempo real no banco Isar e propagar as atualizações de interface.
- [x] **T3.5. Embutir Capa (Thumbnail) nas Músicas**
  - Configurar as opções de linha de comando no `DownloadRequest` para injetar a thumbnail como capa do arquivo (Artwork) quando o tipo de download for `audio`.
  - Garantir que a integração do `extractor` e `FFmpeg` trate a junção e remoção dos arquivos de imagem temporários criados no processo.

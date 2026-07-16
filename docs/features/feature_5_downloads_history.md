# Plano de Feature - Banco de Dados (Isar) e Histórico (Downloads History)

Este documento detalha o plano de desenvolvimento e as subtarefas para a persistência local com Isar e exibição do histórico de downloads.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *4. Regras de Negócio: Feature 4 - Download Management*, *5. UI/UX Concept*, *6. Data Models Spec*)

---

## 🎯 Objetivo
Persistir o estado de todas as tarefas de download (pendentes, em execução, concluídas e com erro) em um banco de dados local robusto (Isar) e exibi-las em uma interface limpa, moderna e responsiva. O usuário poderá acompanhar o progresso em tempo real, reiniciar falhas ou abrir arquivos baixados diretamente da tela.

---

## 📈 Plano de Desenvolvimento

1. **Camada de Dados (Data & Isar)**:
   - Configurar o modelo `DownloadTask` como uma Coleção do Isar.
   - Executar o `build_runner` para gerar o código correspondente (`download_task.g.dart`).
   - Criar o repositório `DownloadsHistoryRepository` para gerenciar inserções, atualizações de progresso e remoções de itens do banco de dados.
2. **Gerenciamento de Estado (Presentation Providers)**:
   - Implementar provedores Riverpod para listar downloads filtrando por status (ativos vs concluídos).
3. **Desenho da Interface (Presentation UI)**:
   - Construir a tela `DownloadsScreen` dividida em abas: "Downloads Ativos" e "Concluídos".
   - Cada card de download ativo deve exibir o título, thumbnail, barra de progresso, velocidade de download e botão de cancelar.
   - Cada card de download concluído deve exibir a miniatura, botão para abrir a pasta local ou reproduzir o áudio/vídeo.

---

## 📋 Lista de Tarefas (Subtasks)

- [x] **T5.1. Implementar Modelos Isar e Rodar Code Generator**
  - Criar `lib/features/downloads_history/data/models/download_task.dart` contendo a classe com anotação `@collection`.
  - Executar comando de compilação: `dart run build_runner build --delete-conflicting-outputs`.
- [x] **T5.2. Criar Repositório `DownloadsHistoryRepository`**
  - Definir métodos de acesso a dados:
    - `Future<void> saveTask(DownloadTask task)`
    - `Future<void> updateTaskProgress(String youtubeId, double progress, String speed, String eta)`
    - `Future<void> updateTaskStatus(String youtubeId, DownloadStatus status, {String? error})`
    - `Stream<List<DownloadTask>> watchAllTasks()`
- [x] **T5.3. Implementar Provedores de Visualização (Riverpod)**
  - Criar `lib/features/downloads_history/presentation/providers/history_providers.dart`:
    - Provedor para escutar e emitir a lista de downloads ativos.
    - Provedor para a lista de concluídos.
- [x] **T5.4. Desenhar Tela `DownloadsScreen`**
  - Implementar em `lib/features/downloads_history/presentation/pages/downloads_page.dart`:
    - Layout clean com TabBar ("Baixando" / "Concluídos").
    - Cards modernos com barra de progresso linear animada para downloads ativos.
    - Ações para abrir o arquivo local de mídia (`open_file` ou canal de plataforma) e botão para limpar histórico ou remover arquivo físico.

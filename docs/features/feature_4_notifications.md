# Plano de Feature - Sincronização de Notificações com Ações (Notifications)

Este documento detalha o plano de desenvolvimento e as subtarefas para a funcionalidade de Notificações Ativas com Progresso e Controle.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *4. Regras de Negócio: Feature 4 - Download Management & Notifications*, *R4. Notificações do Sistema Android*)

---

## 🎯 Objetivo
Exibir na barra de notificações do Android o progresso de cada download em execução com atualizações dinâmicas da porcentagem. A notificação deve permitir que o usuário pause ou cancele a tarefa diretamente pela bandeja de notificações através de botões de ação interativos.

---

## 📈 Plano de Desenvolvimento

1. **Configuração de Serviço de Notificação Nativo (Data)**:
   - Configurar o pacote `flutter_local_notifications` para o Android.
   - Criar um canal de notificação específico de downloads (`download_channel`) com alta prioridade para permitir o progresso em tempo real.
2. **Atualização Dinâmica de Progresso**:
   - Desenvolver o mecanismo que recebe a porcentagem e a velocidade da tarefa no `DownloadQueueManager` e atualiza a barra de progresso da notificação correspondente.
3. **Implementação de Ações Rápidas (Pausar/Cancelar)**:
   - Registrar ações interativas (`AndroidNotificationAction`) para a notificação.
   - Usar canais nativos ou receptor de transmissões (Broadcast / EventChannel) para capturar o clique do usuário na ação da notificação e despachar o comando para o `DownloadQueueManager` (paralisar a tarefa ou remover do motor).

---

## 📋 Lista de Tarefas (Subtasks)

- [x] **T4.1. Configurar Inicialização do Flutter Local Notifications**
  - Implementar classe de serviço `NotificationService` em `lib/core/notification/notification_service.dart`.
  - Inicializar configurações para Android e criar canal de notificação persistente com a flag `showProgress: true` ativada.
- [x] **T4.2. Implementar Sincronizador de Progresso**
  - Criar um método `updateDownloadProgressNotification(DownloadTask task)`:
    - Atualizar o progresso (`maxProgress: 100`, `progress: task.progress`).
    - Configurar título com o nome do vídeo e descrição com a velocidade (ex: `1.2 MB/s - ETA: 00:32`).
- [x] **T4.3. Implementar Ações de Clique em Notificações (Pausar/Cancelar)**
  - Configurar callback global em `NotificationService` para capturar os botões de ação:
    - `actionId == 'cancel_download'`: Disparar evento para cancelar a tarefa de download no motor e atualizar banco Isar.
    - `actionId == 'pause_download'`: Disparar evento para pausar a tarefa.
  - Vincular os botões de ação aos detalhes da notificação no Android (`AndroidNotificationDetails`).
- [x] **T4.4. Teste de Permissão e Exibição de Notificação**
  - Solicitar a permissão de notificações em tempo de execução no Android 13+ usando `permission_handler`.

import '../../data/models/download_task.dart';

abstract class DownloadsHistoryRepository {
  /// Obtém uma tarefa pelo seu ID do Isar.
  Future<DownloadTask?> getTaskById(int id);

  /// Obtém a próxima tarefa com status "pending", ordenada por data de criação.
  Future<DownloadTask?> getNextPendingTask();

  /// Salva ou atualiza uma tarefa no Isar.
  Future<void> saveTask(DownloadTask task);

  /// Atualiza o progresso parcial de uma tarefa no Isar.
  Future<void> updateTaskProgress(
    int id, {
    required double progress,
    required String speed,
    required String eta,
    required DownloadStatus status,
  });

  /// Atualiza o status de conclusão (sucesso ou falha) da tarefa.
  Future<void> updateTaskStatus(
    int id,
    DownloadStatus status, {
    String? errorMessage,
    String? actualQuality,
    String? targetPath,
  });

  /// Retorna a lista de todas as tarefas de download.
  Future<List<DownloadTask>> getAllTasks();

  /// Remove uma tarefa de download pelo ID.
  Future<void> deleteTask(int id);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/download_task.dart';
import '../../data/repositories/downloads_history_repository_impl.dart';

/// Provider que observa todas as tarefas de download persistidas no banco.
final downloadTasksStreamProvider = StreamProvider<List<DownloadTask>>((ref) {
  final repository = ref.watch(downloadsHistoryRepositoryProvider);
  return repository.watchAllTasks();
});

/// Filtra e emite a lista de downloads ativos (baixando, pendentes ou pausados).
final activeDownloadsProvider = Provider<AsyncValue<List<DownloadTask>>>((ref) {
  final allTasksAsync = ref.watch(downloadTasksStreamProvider);
  return allTasksAsync.whenData((tasks) {
    return tasks.where((task) =>
      task.status == DownloadStatus.pending ||
      task.status == DownloadStatus.downloading ||
      task.status == DownloadStatus.paused
    ).toList();
  });
});

/// Filtra e emite a lista de downloads concluídos.
final completedDownloadsProvider = Provider<AsyncValue<List<DownloadTask>>>((ref) {
  final allTasksAsync = ref.watch(downloadTasksStreamProvider);
  return allTasksAsync.whenData((tasks) {
    return tasks.where((task) => task.status == DownloadStatus.completed).toList();
  });
});

/// Filtra e emite a lista de downloads que falharam.
final failedDownloadsProvider = Provider<AsyncValue<List<DownloadTask>>>((ref) {
  final allTasksAsync = ref.watch(downloadTasksStreamProvider);
  return allTasksAsync.whenData((tasks) {
    return tasks.where((task) => task.status == DownloadStatus.failed).toList();
  });
});

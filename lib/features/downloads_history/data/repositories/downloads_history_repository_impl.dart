import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/database/isar_service.dart';
import '../../data/models/download_task.dart';
import '../../domain/repositories/downloads_history_repository.dart';

class DownloadsHistoryRepositoryImpl implements DownloadsHistoryRepository {
  final Isar _isar;

  DownloadsHistoryRepositoryImpl(this._isar);

  @override
  Future<DownloadTask?> getTaskById(int id) async {
    return _isar.downloadTasks.get(id);
  }

  @override
  Future<DownloadTask?> getNextPendingTask() async {
    return _isar.downloadTasks
        .filter()
        .statusEqualTo(DownloadStatus.pending)
        .sortByCreatedAt()
        .findFirst();
  }

  @override
  Future<void> saveTask(DownloadTask task) async {
    await _isar.writeTxn(() async {
      await _isar.downloadTasks.put(task);
    });
  }

  @override
  Future<void> updateTaskProgress(
    int id, {
    required double progress,
    required String speed,
    required String eta,
    required DownloadStatus status,
  }) async {
    await _isar.writeTxn(() async {
      final task = await _isar.downloadTasks.get(id);
      if (task != null) {
        task.progress = progress;
        task.downloadSpeed = speed;
        task.eta = eta;
        task.status = status;
        await _isar.downloadTasks.put(task);
      }
    });
  }

  @override
  Future<void> updateTaskStatus(
    int id,
    DownloadStatus status, {
    String? errorMessage,
    String? actualQuality,
    String? targetPath,
  }) async {
    await _isar.writeTxn(() async {
      final task = await _isar.downloadTasks.get(id);
      if (task != null) {
        task.status = status;
        if (errorMessage != null) task.errorMessage = errorMessage;
        if (actualQuality != null) task.actualQuality = actualQuality;
        if (targetPath != null) task.targetPath = targetPath;
        await _isar.downloadTasks.put(task);
      }
    });
  }

  @override
  Future<List<DownloadTask>> getAllTasks() async {
    return _isar.downloadTasks.where().findAll();
  }

  @override
  Stream<List<DownloadTask>> watchAllTasks() {
    return _isar.downloadTasks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  @override
  Future<void> deleteTask(int id) async {
    await _isar.writeTxn(() async {
      await _isar.downloadTasks.delete(id);
    });
  }
}

final downloadsHistoryRepositoryProvider = Provider<DownloadsHistoryRepository>((ref) {
  return DownloadsHistoryRepositoryImpl(IsarService.instance);
});

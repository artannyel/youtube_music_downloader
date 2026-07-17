import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:youtube_music_downloader/features/downloads_history/data/models/download_task.dart';
import 'package:youtube_music_downloader/features/downloads_history/domain/repositories/downloads_history_repository.dart';
import 'package:youtube_music_downloader/features/downloads_history/data/repositories/downloads_history_repository_impl.dart';
import 'package:youtube_music_downloader/features/downloads_history/presentation/providers/history_providers.dart';

import 'history_providers_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DownloadsHistoryRepository>(),
])
class HistoryProvidersMocks {}

void main() {
  late MockDownloadsHistoryRepository mockRepository;
  late StreamController<List<DownloadTask>> tasksStreamController;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockDownloadsHistoryRepository();
    tasksStreamController = StreamController<List<DownloadTask>>.broadcast();

    when(mockRepository.watchAllTasks()).thenAnswer((_) => tasksStreamController.stream);

    container = ProviderContainer(
      overrides: [
        downloadsHistoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    container.listen(downloadTasksStreamProvider, (previous, next) {});
  });

  tearDown(() {
    tasksStreamController.close();
    container.dispose();
  });

  group('History Providers Filtering Tests', () {
    final taskPending = DownloadTask()
      ..id = 1
      ..youtubeId = 'a'
      ..title = 'Pending Task'
      ..status = DownloadStatus.pending;

    final taskDownloading = DownloadTask()
      ..id = 2
      ..youtubeId = 'b'
      ..title = 'Downloading Task'
      ..status = DownloadStatus.downloading;

    final taskCompleted = DownloadTask()
      ..id = 3
      ..youtubeId = 'c'
      ..title = 'Completed Task'
      ..status = DownloadStatus.completed;

    final taskFailed = DownloadTask()
      ..id = 4
      ..youtubeId = 'd'
      ..title = 'Failed Task'
      ..status = DownloadStatus.failed;

    final taskPaused = DownloadTask()
      ..id = 5
      ..youtubeId = 'e'
      ..title = 'Paused Task'
      ..status = DownloadStatus.paused;

    test('should watch all tasks and correctly filter active downloads', () async {
      final allTasks = [taskPending, taskDownloading, taskCompleted, taskFailed, taskPaused];

      // Começa escutando activeDownloadsProvider
      final activeListAsync = container.read(activeDownloadsProvider);
      expect(activeListAsync, isA<AsyncLoading>());

      // Emite as tarefas no stream
      tasksStreamController.add(allTasks);

      // Aguarda o processamento do stream
      await Future.delayed(Duration.zero);

      final activeList = container.read(activeDownloadsProvider).value;
      expect(activeList, isNotNull);
      expect(activeList!.length, equals(3));
      expect(activeList.any((t) => t.id == 1), isTrue); // Pending
      expect(activeList.any((t) => t.id == 2), isTrue); // Downloading
      expect(activeList.any((t) => t.id == 5), isTrue); // Paused
    });

    test('should watch all tasks and correctly filter completed downloads', () async {
      final allTasks = [taskPending, taskDownloading, taskCompleted, taskFailed, taskPaused];

      // Emite as tarefas no stream
      tasksStreamController.add(allTasks);
      await Future.delayed(Duration.zero);

      final completedList = container.read(completedDownloadsProvider).value;
      expect(completedList, isNotNull);
      expect(completedList!.length, equals(1));
      expect(completedList.first.id, equals(3)); // Completed
    });

    test('should watch all tasks and correctly filter failed downloads', () async {
      final allTasks = [taskPending, taskDownloading, taskCompleted, taskFailed, taskPaused];

      // Emite as tarefas no stream
      tasksStreamController.add(allTasks);
      await Future.delayed(Duration.zero);

      final failedList = container.read(failedDownloadsProvider).value;
      expect(failedList, isNotNull);
      expect(failedList!.length, equals(1));
      expect(failedList.first.id, equals(4)); // Failed
    });
  });
}

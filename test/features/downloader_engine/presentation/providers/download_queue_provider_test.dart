import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:extractor/extractor.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:youtube_music_downloader/features/downloader_engine/presentation/providers/download_queue_provider.dart';
import 'package:youtube_music_downloader/features/downloads_history/data/models/download_task.dart';
import 'package:youtube_music_downloader/features/downloads_history/domain/repositories/downloads_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'download_queue_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DownloadsHistoryRepository>(),
  MockSpec<YoutubeDLFlutter>(),
  MockSpec<DownloadProgress>(),
  MockSpec<DownloadState>(),
  MockSpec<DownloadError>(),
  MockSpec<DownloadResult>(),
])
class DownloadQueueMocks {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDownloadsHistoryRepository mockRepository;
  late MockYoutubeDLFlutter mockYoutubeDL;
  
  late StreamController<DownloadProgress> progressController;
  late StreamController<DownloadState> stateController;
  late StreamController<DownloadError> errorController;
  
  late DownloadQueueNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    const MethodChannel channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'initialize') {
        return true;
      }
      return null;
    });

    const MethodChannel permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkPermissionStatus') {
        return 1; // PermissionStatus.granted
      }
      if (methodCall.method == 'requestPermission') {
        return {methodCall.arguments: 1};
      }
      return null;
    });

    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('download_queue_test_');
    mockRepository = MockDownloadsHistoryRepository();
    mockYoutubeDL = MockYoutubeDLFlutter();

    progressController = StreamController<DownloadProgress>.broadcast();
    stateController = StreamController<DownloadState>.broadcast();
    errorController = StreamController<DownloadError>.broadcast();

    when(mockYoutubeDL.onProgress).thenAnswer((_) => progressController.stream);
    when(mockYoutubeDL.onStateChanged).thenAnswer((_) => stateController.stream);
    when(mockYoutubeDL.onError).thenAnswer((_) => errorController.stream);

    notifier = DownloadQueueNotifier(mockRepository, mockYoutubeDL);
  });

  tearDown(() async {
    progressController.close();
    stateController.close();
    errorController.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DownloadQueueNotifier', () {
    DownloadTask getPendingTask() => DownloadTask()
      ..id = 1
      ..youtubeId = 'dQw4w9WgXcQ'
      ..title = 'Never Gonna Give You Up'
      ..url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
      ..type = DownloadType.video
      ..requestedQuality = '1080p'
      ..actualQuality = ''
      ..targetPath = '${tempDir.path}/Never Gonna Give You Up.mp4'
      ..progress = 0.0
      ..downloadSpeed = ''
      ..eta = ''
      ..status = DownloadStatus.pending
      ..createdAt = DateTime.now();

    test('should stop processing immediately if queue is empty', () async {
      when(mockRepository.getNextPendingTask()).thenAnswer((_) async => null);

      await notifier.startProcessing();

      expect(notifier.state.isProcessing, isFalse);
      expect(notifier.state.currentTaskId, isNull);
      verify(mockRepository.getNextPendingTask()).called(1);
    });

    test('should process a pending task, start download, and mark it completed on success', () async {
      final pendingTask = getPendingTask();
      final mockResult = MockDownloadResult();
      when(mockResult.status).thenReturn(OperationStatus.success);
      when(mockResult.outputPath).thenReturn('${tempDir.path}/Never Gonna Give You Up.mp4');

      int callCount = 0;
      when(mockRepository.getNextPendingTask()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? pendingTask : null;
      });

      when(mockYoutubeDL.download(any)).thenAnswer((_) async => mockResult);

      await notifier.startProcessing();

      verify(mockRepository.updateTaskStatus(1, DownloadStatus.downloading)).called(1);
      verify(mockYoutubeDL.download(any)).called(1);
      verify(mockRepository.updateTaskStatus(
        1,
        DownloadStatus.completed,
        actualQuality: '1080p',
        targetPath: '${tempDir.path}/Never Gonna Give You Up.mp4',
      )).called(1);
    });

    test('should process a pending task and mark it failed on download error', () async {
      final pendingTask = getPendingTask();
      final mockResult = MockDownloadResult();
      when(mockResult.status).thenReturn(OperationStatus.error);
      when(mockResult.errorMessage).thenReturn('Network error');

      int callCount = 0;
      when(mockRepository.getNextPendingTask()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? pendingTask : null;
      });

      when(mockYoutubeDL.download(any)).thenAnswer((_) async => mockResult);

      await notifier.startProcessing();

      verify(mockRepository.updateTaskStatus(1, DownloadStatus.downloading)).called(1);
      verify(mockYoutubeDL.download(any)).called(1);
      verify(mockRepository.updateTaskStatus(
        1,
        DownloadStatus.failed,
        errorMessage: 'Network error',
      )).called(1);
    });

    test('should handle download exception and mark task failed', () async {
      final pendingTask = getPendingTask();
      int callCount = 0;
      when(mockRepository.getNextPendingTask()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? pendingTask : null;
      });

      when(mockYoutubeDL.download(any)).thenThrow(Exception('Extraction crashed'));

      await notifier.startProcessing();

      verify(mockRepository.updateTaskStatus(
        1,
        DownloadStatus.failed,
        errorMessage: 'Exception: Extraction crashed',
      )).called(1);
    });
  });
}

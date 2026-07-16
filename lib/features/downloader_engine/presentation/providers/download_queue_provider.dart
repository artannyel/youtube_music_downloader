import 'dart:async';
import 'dart:io';

import 'package:extractor/extractor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notification/notification_service.dart';
import '../../../downloads_history/data/models/download_task.dart';
import '../../../downloads_history/domain/repositories/downloads_history_repository.dart';
import '../../../downloads_history/data/repositories/downloads_history_repository_impl.dart';
import '../../data/services/cookies_service.dart';
import '../../data/services/extractor_service.dart';
import '../../domain/utils/quality_format_builder.dart';

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

/// Snapshot em memória do progresso de uma tarefa de download.
/// Usado para atualizações de UI em tempo real sem acessar o Isar a cada frame.
class DownloadTaskSnapshot {
  final int taskId;
  final String youtubeId;
  final String title;
  final double progress;
  final String speed;
  final String eta;
  final DownloadStatus status;
  final String? errorMessage;
  final bool isAudio;

  const DownloadTaskSnapshot({
    required this.taskId,
    required this.youtubeId,
    required this.title,
    required this.progress,
    required this.speed,
    required this.eta,
    required this.status,
    this.errorMessage,
    required this.isAudio,
  });

  DownloadTaskSnapshot copyWith({
    double? progress,
    String? speed,
    String? eta,
    DownloadStatus? status,
    String? errorMessage,
    bool? isAudio,
  }) {
    return DownloadTaskSnapshot(
      taskId: taskId,
      youtubeId: youtubeId,
      title: title,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isAudio: isAudio ?? this.isAudio,
    );
  }
}

/// Estado global da fila de downloads.
class DownloadQueueState {
  /// Indica se a fila está processando alguma tarefa.
  final bool isProcessing;

  /// Snapshots em memória de cada tarefa ativa/recente (taskId → snapshot).
  final Map<int, DownloadTaskSnapshot> taskSnapshots;

  /// ID (Isar) da tarefa sendo baixada no momento.
  final int? currentTaskId;

  const DownloadQueueState({
    required this.isProcessing,
    required this.taskSnapshots,
    this.currentTaskId,
  });

  const DownloadQueueState.initial()
      : isProcessing = false,
        taskSnapshots = const {},
        currentTaskId = null;

  DownloadQueueState copyWith({
    bool? isProcessing,
    Map<int, DownloadTaskSnapshot>? taskSnapshots,
    int? currentTaskId,
    bool clearCurrentTask = false,
  }) {
    return DownloadQueueState(
      isProcessing: isProcessing ?? this.isProcessing,
      taskSnapshots: taskSnapshots ?? this.taskSnapshots,
      currentTaskId:
          clearCurrentTask ? null : (currentTaskId ?? this.currentTaskId),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Gerenciador de fila de downloads.
///
/// Processa **1 download por vez** (sequencial), reportando progresso,
/// velocidade e ETA em tempo real via [DownloadQueueState].
class DownloadQueueNotifier extends StateNotifier<DownloadQueueState> {
  final DownloadsHistoryRepository _repository;

  StreamSubscription<dynamic>? _progressSub;
  StreamSubscription<dynamic>? _stateSub;
  StreamSubscription<dynamic>? _errorSub;

  final YoutubeDLFlutter _ytdl;
  String? _currentProcessId;

  DownloadQueueNotifier(this._repository, [YoutubeDLFlutter? ytdl])
      : _ytdl = ytdl ?? ExtractorService.instance,
        super(const DownloadQueueState.initial()) {
    _setupStreamListeners();
  }

  // ---- Setup de Streams do Extractor ------------------------------------

  void _setupStreamListeners() {
    _progressSub = _ytdl.onProgress.listen(_onProgressUpdate);
    _stateSub = _ytdl.onStateChanged.listen(_onStateChanged);
    _errorSub = _ytdl.onError.listen(_onErrorReceived);
  }

  void _onProgressUpdate(dynamic progress) {
    if (progress.processId != _currentProcessId) return;
    if (state.currentTaskId == null) return;

    final taskId = state.currentTaskId!;
    final existing = state.taskSnapshots[taskId];
    if (existing == null) return;

    final etaStr = _formatDuration(progress.eta as Duration);
    final percent = (progress.progress as num).toDouble();

    final updated = existing.copyWith(
      progress: percent,
      eta: etaStr,
      status: DownloadStatus.downloading,
    );

    state = state.copyWith(
      taskSnapshots: {...state.taskSnapshots, taskId: updated},
    );

    // Mostra/Atualiza a notificação de progresso ativa no Android
    NotificationService.showProgressNotification(
      taskId: taskId,
      title: existing.title,
      progress: percent,
      speed: '',
      eta: etaStr,
      processId: _currentProcessId!,
      isAudio: existing.isAudio,
    );

    // Persiste no Isar a cada ~5% para não sobrecarregar o banco
    if (percent > 0 && (percent % 5).round() == 0) {
      _repository.updateTaskProgress(
        taskId,
        progress: updated.progress,
        speed: updated.speed,
        eta: updated.eta,
        status: updated.status,
      );
    }
  }

  void _onStateChanged(dynamic downloadState) {
    if (downloadState.processId != _currentProcessId) return;
    debugPrint(
      '[DownloadQueue] Estado do extractor: ${downloadState.state}',
    );
  }

  void _onErrorReceived(dynamic error) {
    if (error.processId != _currentProcessId) return;
    if (state.currentTaskId == null) return;

    final taskId = state.currentTaskId!;
    final existing = state.taskSnapshots[taskId];
    if (existing == null) return;

    final updated = existing.copyWith(
      status: DownloadStatus.failed,
      errorMessage: error.error?.toString() ?? 'Erro desconhecido',
    );

    state = state.copyWith(
      taskSnapshots: {...state.taskSnapshots, taskId: updated},
    );
  }

  // ---- Processamento da Fila --------------------------------------------

  /// Inicia o processamento da fila de downloads pendentes.
  ///
  /// Se a fila já está em processamento, a chamada é ignorada.
  Future<void> startProcessing() async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true);
    await _processNext();
  }

  /// Processa a próxima tarefa pendente (sequencial).
  Future<void> _processNext() async {
    if (!mounted) return;

    // Busca a próxima tarefa pendente no Isar, ordenada por data de criação
    final nextTask = await _repository.getNextPendingTask();

    if (nextTask == null) {
      // Nenhuma tarefa pendente — encerra o processamento
      state = state.copyWith(isProcessing: false, clearCurrentTask: true);
      debugPrint('[DownloadQueue] Fila de downloads vazia.');
      return;
    }

    // Cria o snapshot em memória para a tarefa atual
    final snapshot = DownloadTaskSnapshot(
      taskId: nextTask.id,
      youtubeId: nextTask.youtubeId,
      title: nextTask.title,
      progress: 0.0,
      speed: '',
      eta: '',
      status: DownloadStatus.downloading,
      isAudio: nextTask.type == DownloadType.audio,
    );

    state = state.copyWith(
      currentTaskId: nextTask.id,
      taskSnapshots: {...state.taskSnapshots, nextTask.id: snapshot},
    );

    // Marca como "downloading" no Isar
    await _repository.updateTaskStatus(nextTask.id, DownloadStatus.downloading);

    // Executa o download
    try {
      final request = await _buildDownloadRequest(nextTask);
      _currentProcessId = request.processId;

      debugPrint('[DownloadQueue] Iniciando: ${nextTask.title}');
      final result = await _ytdl.download(request);

      if (result.status == OperationStatus.success) {
        await _markTaskCompleted(nextTask, result.outputPath);
      } else {
        await _markTaskFailed(
          nextTask,
          result.errorMessage ?? 'Erro desconhecido no download',
        );
      }
    } catch (e) {
      await _markTaskFailed(nextTask, e.toString());
    }

    _currentProcessId = null;

    // Processa a próxima tarefa da fila
    if (mounted) {
      await _processNext();
    }
  }

  // ---- Construção do DownloadRequest ------------------------------------

  /// Constrói o [DownloadRequest] para uma tarefa do Isar.
  Future<DownloadRequest> _buildDownloadRequest(DownloadTask task) async {
    final isAudio = task.type == DownloadType.audio;
    final processId =
        'dl_${task.youtubeId}_${DateTime.now().millisecondsSinceEpoch}';

    // Resolve o diretório de saída a partir do targetPath salvo
    final lastSlash = task.targetPath.lastIndexOf('/');
    final outputDir =
        lastSlash > 0 ? task.targetPath.substring(0, lastSlash) : task.targetPath;

    // Garante que o diretório existe
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Opções customizadas do yt-dlp
    final customOptions = <String, String>{
      '--no-playlist': '',
      '--no-mtime': '',
      '--downloader': 'libaria2c.so', // Aria2c para downloads mais rápidos
    };

    // T3.3: Injeta cookies se configurado no SharedPreferences
    final cookiesPath = await CookiesService.getValidCookiesPath();
    if (cookiesPath != null) {
      customOptions['--cookies'] = cookiesPath;
      debugPrint('[DownloadQueue] Cookies injetados: $cookiesPath');
    }

    if (isAudio) {
      // Download de áudio com thumbnail embutida (T3.5)
      return DownloadRequest(
        url: task.url,
        outputPath: outputDir,
        outputTemplate: '%(title)s.%(ext)s',
        format: QualityFormatBuilder.buildAudioFormat(),
        extractAudio: true,
        audioFormat: 'mp3',
        audioQuality:
            QualityFormatBuilder.mapAudioQuality(task.requestedQuality),
        embedThumbnail: true, // T3.5: Embutir capa no arquivo de áudio
        embedMetadata: true,
        processId: processId,
        customOptions: customOptions,
      );
    } else {
      // Download de vídeo com format string de fallback (T3.2)
      return DownloadRequest(
        url: task.url,
        outputPath: outputDir,
        outputTemplate: '%(title)s.%(ext)s',
        format:
            QualityFormatBuilder.buildVideoFormat(task.requestedQuality),
        embedMetadata: true,
        processId: processId,
        customOptions: customOptions,
      );
    }
  }

  // ---- Atualização de Status --------------------------------------------

  /// Marca uma tarefa como concluída no Isar e no estado.
  Future<void> _markTaskCompleted(
    DownloadTask task,
    String? outputPath,
  ) async {
    await _repository.updateTaskStatus(
      task.id,
      DownloadStatus.completed,
      actualQuality: task.requestedQuality,
      targetPath: outputPath,
    );

    // Cancela a notificação ativa da bandeja de notificações
    NotificationService.cancelNotification(task.id);

    final updated = state.taskSnapshots[task.id]?.copyWith(
      progress: 100.0,
      status: DownloadStatus.completed,
    );

    if (updated != null) {
      state = state.copyWith(
        taskSnapshots: {...state.taskSnapshots, task.id: updated},
      );
    }

    debugPrint('[DownloadQueue] ✅ Concluído: ${task.title}');
  }

  /// Marca uma tarefa como falhada no Isar e no estado.
  Future<void> _markTaskFailed(
    DownloadTask task,
    String errorMessage,
  ) async {
    await _repository.updateTaskStatus(
      task.id,
      DownloadStatus.failed,
      errorMessage: errorMessage,
    );

    // Cancela a notificação ativa da bandeja de notificações
    NotificationService.cancelNotification(task.id);

    final updated = state.taskSnapshots[task.id]?.copyWith(
      status: DownloadStatus.failed,
      errorMessage: errorMessage,
    );

    if (updated != null) {
      state = state.copyWith(
        taskSnapshots: {...state.taskSnapshots, task.id: updated},
      );
    }

    debugPrint('[DownloadQueue] ❌ Falha: ${task.title} — $errorMessage');
  }

  /// Cancela o download ativo atual.
  Future<void> cancelCurrentDownload() async {
    if (_currentProcessId == null || state.currentTaskId == null) return;

    debugPrint('[DownloadQueue] Cancelando download ativo...');
    await _ytdl.cancelDownload(_currentProcessId!);

    final taskId = state.currentTaskId!;
    await _repository.updateTaskStatus(
      taskId,
      DownloadStatus.failed,
      errorMessage: 'Download cancelado pelo usuário',
    );

    // Cancela a notificação ativa da bandeja de notificações
    NotificationService.cancelNotification(taskId);

    final updated = state.taskSnapshots[taskId]?.copyWith(
      status: DownloadStatus.failed,
      errorMessage: 'Download cancelado pelo usuário',
    );

    if (updated != null) {
      state = state.copyWith(
        taskSnapshots: {...state.taskSnapshots, taskId: updated},
      );
    }
  }

  // ---- Utilidades -------------------------------------------------------

  /// Formata uma [Duration] para exibição amigável (ex: "2m 15s").
  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _stateSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provider global (não-autoDispose) para o gerenciador de fila de downloads.
///
/// Deve ser mantido vivo durante toda a sessão do app para processar
/// downloads em segundo plano.
final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, DownloadQueueState>((ref) {
  final repository = ref.watch(downloadsHistoryRepositoryProvider);
  return DownloadQueueNotifier(repository);
});

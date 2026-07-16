import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/download_setup_repository_impl.dart';
import '../../domain/repositories/download_setup_repository.dart';
import '../../domain/entities/media_metadata.dart';
import '../../domain/utils/storage_directory_helper.dart';
import '../../../downloads_history/data/models/download_task.dart';
import '../../../explore/presentation/providers/explore_provider.dart';
import '../../../../core/database/isar_service.dart';

// Provider para o repositório do Download Setup
final downloadSetupRepositoryProvider = Provider<DownloadSetupRepository>((ref) {
  final yt = ref.watch(youtubeExplodeProvider);
  return DownloadSetupRepositoryImpl(yt);
});

// Estado para gerenciar as configurações do formulário de download
class DownloadSetupState {
  final bool isLoading;
  final String? errorMessage;
  final MediaMetadata? metadata;
  final DownloadType selectedFormat;
  final String? selectedQuality;
  final String subfolder;
  final bool subfolderExists;

  const DownloadSetupState({
    required this.isLoading,
    this.errorMessage,
    this.metadata,
    required this.selectedFormat,
    this.selectedQuality,
    required this.subfolder,
    required this.subfolderExists,
  });

  const DownloadSetupState.initial()
      : isLoading = false,
        errorMessage = null,
        metadata = null,
        selectedFormat = DownloadType.video,
        selectedQuality = null,
        subfolder = '',
        subfolderExists = false;

  DownloadSetupState copyWith({
    bool? isLoading,
    String? errorMessage,
    MediaMetadata? metadata,
    DownloadType? selectedFormat,
    String? selectedQuality,
    String? subfolder,
    bool? subfolderExists,
  }) {
    return DownloadSetupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      metadata: metadata ?? this.metadata,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      subfolder: subfolder ?? this.subfolder,
      subfolderExists: subfolderExists ?? this.subfolderExists,
    );
  }
}

// Notifier para o gerenciamento de estado do Download Setup
class DownloadSetupNotifier extends StateNotifier<DownloadSetupState> {
  final DownloadSetupRepository _repository;

  DownloadSetupNotifier(this._repository) : super(const DownloadSetupState.initial());

  /// Carrega os metadados do link informado e define as qualidades padrão
  Future<void> loadMetadata(String url) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final metadata = await _repository.fetchMetadata(url);

      // Preenche a pasta padrão se for uma playlist
      String defaultSubfolder = '';
      if (metadata.isPlaylist) {
        defaultSubfolder = _sanitizeFolderName(metadata.title);
      }

      // Seleciona a qualidade padrão de vídeo
      final defaultQuality = metadata.videoQualities.isNotEmpty
          ? metadata.videoQualities.first
          : null;

      final exists = await StorageDirectoryHelper.doesSubfolderExist(
        subfolder: defaultSubfolder,
        isAudio: state.selectedFormat == DownloadType.audio,
      );

      state = state.copyWith(
        isLoading: false,
        metadata: metadata,
        selectedFormat: DownloadType.video,
        selectedQuality: defaultQuality,
        subfolder: defaultSubfolder,
        subfolderExists: exists,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Muda o formato desejado (Vídeo/Áudio) e ajusta as qualidades disponíveis
  Future<void> setFormat(DownloadType format) async {
    if (state.metadata == null) return;

    final qualities = format == DownloadType.video
        ? state.metadata!.videoQualities
        : state.metadata!.audioQualities;

    final defaultQuality = qualities.isNotEmpty ? qualities.first : null;

    final exists = await StorageDirectoryHelper.doesSubfolderExist(
      subfolder: state.subfolder,
      isAudio: format == DownloadType.audio,
    );

    state = state.copyWith(
      selectedFormat: format,
      selectedQuality: defaultQuality,
      subfolderExists: exists,
    );
  }

  /// Altera a qualidade selecionada
  void setQuality(String quality) {
    state = state.copyWith(selectedQuality: quality);
  }

  /// Altera o nome da subpasta e atualiza a verificação de existência no disco
  Future<void> setSubfolder(String subfolder) async {
    final exists = await StorageDirectoryHelper.doesSubfolderExist(
      subfolder: subfolder,
      isAudio: state.selectedFormat == DownloadType.audio,
    );

    state = state.copyWith(
      subfolder: subfolder,
      subfolderExists: exists,
    );
  }

  /// Enfileira as tarefas de download salvando-as no Isar com status pendente
  Future<void> queueDownload() async {
    final meta = state.metadata;
    if (meta == null) return;

    final targetDir = await StorageDirectoryHelper.getTargetDirectoryPath(
      subfolder: state.subfolder,
      isAudio: state.selectedFormat == DownloadType.audio,
    );

    final isar = IsarService.instance;

    if (meta.isPlaylist) {
      if (meta.playlistVideos == null || meta.playlistVideos!.isEmpty) return;

      await isar.writeTxn(() async {
        for (var video in meta.playlistVideos!) {
          final task = DownloadTask()
            ..youtubeId = video.id
            ..title = video.title
            ..url = 'https://youtube.com/watch?v=${video.id}'
            ..type = state.selectedFormat
            ..requestedQuality = state.selectedQuality ?? 'Default'
            ..actualQuality = ''
            ..targetPath = '$targetDir/${_sanitizeFileName(video.title)}.${state.selectedFormat == DownloadType.audio ? "mp3" : "mp4"}'
            ..progress = 0.0
            ..downloadSpeed = '0 KB/s'
            ..eta = ''
            ..status = DownloadStatus.pending
            ..createdAt = DateTime.now();

          await isar.downloadTasks.put(task);
        }
      });
    } else {
      await isar.writeTxn(() async {
        final task = DownloadTask()
          ..youtubeId = meta.id
          ..title = meta.title
          ..url = 'https://youtube.com/watch?v=${meta.id}'
          ..type = state.selectedFormat
          ..requestedQuality = state.selectedQuality ?? 'Default'
          ..actualQuality = ''
          ..targetPath = '$targetDir/${_sanitizeFileName(meta.title)}.${state.selectedFormat == DownloadType.audio ? "mp3" : "mp4"}'
          ..progress = 0.0
          ..downloadSpeed = '0 KB/s'
          ..eta = ''
          ..status = DownloadStatus.pending
          ..createdAt = DateTime.now();

        await isar.downloadTasks.put(task);
      });
    }
  }

  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim();
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
  }
}

// Provider global para acessar o gerenciamento de estado do Download Setup
final downloadSetupProvider = StateNotifierProvider.autoDispose<DownloadSetupNotifier, DownloadSetupState>((ref) {
  final repository = ref.watch(downloadSetupRepositoryProvider);
  return DownloadSetupNotifier(repository);
});

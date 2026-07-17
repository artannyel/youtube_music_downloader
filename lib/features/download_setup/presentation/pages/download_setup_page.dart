import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/download_setup_provider.dart';
import '../../../downloads_history/data/models/download_task.dart';

class DownloadSetupPage extends ConsumerStatefulWidget {
  final String initialUrl;

  const DownloadSetupPage({super.key, required this.initialUrl});

  @override
  ConsumerState<DownloadSetupPage> createState() => _DownloadSetupPageState();
}

class _DownloadSetupPageState extends ConsumerState<DownloadSetupPage> {
  final TextEditingController _subfolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadSetupProvider.notifier).loadMetadata(widget.initialUrl);
    });
  }

  @override
  void dispose() {
    _subfolderController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadSetupProvider);
    final theme = Theme.of(context);

    // Escuta mudanças de estado para pré-preencher o controller da subpasta
    ref.listen<DownloadSetupState>(downloadSetupProvider, (previous, next) {
      if (previous?.metadata == null && next.metadata != null) {
        _subfolderController.text = next.subfolder;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Download'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: state.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando metadados e streams...'),
                ],
              ),
            )
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(downloadSetupProvider.notifier)
                                .loadMetadata(widget.initialUrl);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : state.metadata == null
                  ? const Center(child: Text('Nenhuma mídia encontrada.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card de Metadados da Mídia
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      state.metadata!.thumbnailUrl,
                                      width: 120,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 120,
                                        height: 70,
                                        color: theme.colorScheme.surfaceContainer,
                                        child: const Icon(Icons.music_video),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.metadata!.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          state.metadata!.author,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.textTheme.bodyMedium?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.metadata!.isPlaylist
                                                ? theme.colorScheme.primaryContainer
                                                : theme.colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            state.metadata!.isPlaylist
                                                ? 'Playlist (${state.metadata!.playlistVideos?.length ?? 0} vídeos)'
                                                : 'Vídeo • ${_formatDuration(state.metadata!.duration)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: state.metadata!.isPlaylist
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Seção de Configuração do Formato
                          Text(
                            'Configurações de Download',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Seletor de Formato (Vídeo ou Áudio)
                                  const Text(
                                    'Tipo de Mídia',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<DownloadType>(
                                    segments: const [
                                      ButtonSegment(
                                        value: DownloadType.video,
                                        icon: Icon(Icons.video_library),
                                        label: Text('Vídeo (MP4)'),
                                      ),
                                      ButtonSegment(
                                        value: DownloadType.audio,
                                        icon: Icon(Icons.audiotrack),
                                        label: Text('Áudio (MP3/M4A)'),
                                      ),
                                    ],
                                    selected: {state.selectedFormat},
                                    onSelectionChanged: (selection) {
                                      ref
                                          .read(downloadSetupProvider.notifier)
                                          .setFormat(selection.first);
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Seletor de Qualidade
                                  const Text(
                                    'Qualidade',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: state.selectedQuality,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: (state.selectedFormat == DownloadType.video
                                            ? state.metadata!.videoQualities
                                            : state.metadata!.audioQualities)
                                        .map((q) => DropdownMenuItem(
                                              value: q,
                                              child: Text(q),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref
                                            .read(downloadSetupProvider.notifier)
                                            .setQuality(val);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Campo de Subpasta
                                  const Text(
                                    'Subpasta de Destino (Opcional)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _subfolderController,
                                    decoration: InputDecoration(
                                      hintText: 'Ex: variados, rock_anos_80',
                                      prefixIcon: const Icon(Icons.folder_open),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      ref
                                          .read(downloadSetupProvider.notifier)
                                          .setSubfolder(val);
                                    },
                                  ),

                                  // Alerta Visual de Pasta Existente (Se aplicável)
                                  if (state.subfolderExists &&
                                      state.subfolder.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.amber.shade700.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.amber.shade800,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "A pasta '${state.subfolder}' já existe. Novos arquivos de mídia serão adicionados a ela.",
                                              style: TextStyle(
                                                color: Colors.amber.shade900,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Botão Principal para Adicionar ao Motor de Downloads
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 2,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(downloadSetupProvider.notifier)
                                    .queueDownload();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        state.metadata!.isPlaylist
                                            ? 'Playlist adicionada à fila com sucesso!'
                                            : 'Vídeo adicionado à fila com sucesso!',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                  // Navega para a aba de downloads
                                  context.go('/downloads');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Falha ao enfileirar download: $e'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Confirmar Download',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

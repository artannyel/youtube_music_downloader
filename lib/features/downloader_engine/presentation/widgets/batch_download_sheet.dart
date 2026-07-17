import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../downloads_history/data/models/download_task.dart';
import '../../../download_setup/domain/utils/storage_directory_helper.dart';
import '../../../../core/database/isar_service.dart';
import '../../../download_setup/domain/utils/youtube_url_helper.dart';
import '../providers/download_queue_provider.dart';

class BatchDownloadSheet extends ConsumerStatefulWidget {
  final List<String> urls;

  const BatchDownloadSheet({super.key, required this.urls});

  static void show(BuildContext context, List<String> urls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BatchDownloadSheet(urls: urls),
    );
  }

  @override
  ConsumerState<BatchDownloadSheet> createState() => _BatchDownloadSheetState();
}

class _BatchDownloadSheetState extends ConsumerState<BatchDownloadSheet> {
  DownloadType _selectedFormat = DownloadType.audio;
  String _selectedQuality = 'Melhor';
  final TextEditingController _subfolderController = TextEditingController();

  @override
  void dispose() {
    _subfolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configurar Download em Lote',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Encontrados ${widget.urls.length} links válidos para download.',
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipo de Mídia',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  label: Text('Áudio (MP3)'),
                ),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedFormat = selection.first;
                  _selectedQuality = 'Melhor'; // Reseta qualidade para o novo formato
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Qualidade',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedQuality,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: (_selectedFormat == DownloadType.video
                      ? ['Melhor', '1080p', '720p', '480p', '360p']
                      : ['Melhor', '320kbps', '256kbps', '192kbps', '128kbps'])
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedQuality = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Subpasta de Destino (Opcional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subfolderController,
              decoration: InputDecoration(
                hintText: 'Ex: baixar_lote, sertanejo',
                prefixIcon: const Icon(Icons.folder_open),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                Navigator.pop(context); // Fecha Bottom Sheet

                try {
                  final targetDir = await StorageDirectoryHelper.getTargetDirectoryPath(
                    subfolder: _subfolderController.text.trim(),
                    isAudio: _selectedFormat == DownloadType.audio,
                  );

                  final isar = IsarService.instance;

                  await isar.writeTxn(() async {
                    for (var url in widget.urls) {
                      final videoId = YoutubeUrlHelper.extractVideoId(url) ?? 'Video';
                      final task = DownloadTask()
                        ..youtubeId = videoId
                        ..title = 'Fila em lote: $videoId'
                        ..url = url
                        ..type = _selectedFormat
                        ..requestedQuality = _selectedQuality
                        ..actualQuality = ''
                        ..targetPath = '$targetDir/${videoId}_batch.${_selectedFormat == DownloadType.audio ? "mp3" : "mp4"}'
                        ..progress = 0.0
                        ..downloadSpeed = '0 KB/s'
                        ..eta = ''
                        ..status = DownloadStatus.pending
                        ..createdAt = DateTime.now();

                      await isar.downloadTasks.put(task);
                    }
                  });

                  ref.read(downloadQueueProvider.notifier).startProcessing();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.urls.length} vídeos adicionados à fila de downloads!'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                    context.go('/downloads');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao enfileirar lote: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Iniciar Download em Lote',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

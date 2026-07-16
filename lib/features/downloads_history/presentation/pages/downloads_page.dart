import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../../downloader_engine/presentation/providers/download_queue_provider.dart';
import '../../data/models/download_task.dart';
import '../providers/history_providers.dart';
import '../../data/repositories/downloads_history_repository_impl.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text('Deseja remover todo o histórico de downloads? Isso não excluirá os arquivos físicos do seu dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final repository = ref.read(downloadsHistoryRepositoryProvider);
              final tasks = await repository.getAllTasks();
              for (final task in tasks) {
                // Não exclui tarefas que estão ativamente baixando
                if (task.status != DownloadStatus.downloading) {
                  await repository.deleteTask(task.id);
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeDownloadsProvider);
    final completedAsync = ref.watch(completedDownloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearAllHistory,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: theme.colorScheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.downloading, size: 20),
                  const SizedBox(width: 8),
                  const Text('Baixando'),
                  activeAsync.maybeWhen(
                    data: (tasks) => tasks.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music, size: 20),
                  SizedBox(width: 8),
                  Text('Concluídos'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveDownloadsTab(activeAsync: activeAsync),
          _CompletedDownloadsTab(completedAsync: completedAsync),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ABA 1: Downloads Ativos
// ---------------------------------------------------------------------------
class _ActiveDownloadsTab extends ConsumerWidget {
  final AsyncValue<List<DownloadTask>> activeAsync;

  const _ActiveDownloadsTab({required this.activeAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return activeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_done_rounded,
                  size: 80,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum download em andamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesquise e inicie downloads na aba Explorar',
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final percent = task.progress;
            final isDownloading = task.status == DownloadStatus.downloading;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            task.type == DownloadType.audio
                                ? Icons.music_note_rounded
                                : Icons.play_arrow_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDownloading
                                    ? 'Baixando • ${task.requestedQuality}'
                                    : 'Aguardando na fila...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDownloading)
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                            tooltip: 'Cancelar download',
                            onPressed: () {
                              ref.read(downloadQueueProvider.notifier).cancelCurrentDownload();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (isDownloading && task.eta.isNotEmpty)
                          Text(
                            'ETA: ${task.eta}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ABA 2: Downloads Concluídos
// ---------------------------------------------------------------------------
class _CompletedDownloadsTab extends ConsumerWidget {
  final AsyncValue<List<DownloadTask>> completedAsync;

  const _CompletedDownloadsTab({required this.completedAsync});

  Future<void> _openFile(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo não encontrado no dispositivo.')),
        );
      }
      return;
    }

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir o arquivo: ${result.message}')),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Download'),
        content: const Text('Deseja excluir esta tarefa do histórico? Você também pode optar por apagar o arquivo de mídia baixado permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              // Deleta apenas o registro do histórico
              await ref.read(downloadsHistoryRepositoryProvider).deleteTask(task.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Apenas Histórico'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Deleta o registro e o arquivo
              await ref.read(downloadsHistoryRepositoryProvider).deleteTask(task.id);
              try {
                final file = File(task.targetPath);
                if (await file.exists()) {
                  await file.delete();
                }
              } catch (_) {}
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Excluir Arquivo e Histórico'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return completedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music_outlined,
                  size: 80,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum download concluído',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suas músicas e vídeos salvos aparecerão aqui',
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.type == DownloadType.audio
                        ? Icons.music_note_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                title: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${task.actualQuality} • Concluído',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.play_circle_fill, color: theme.colorScheme.primary, size: 28),
                      tooltip: 'Reproduzir / Abrir arquivo',
                      onPressed: () => _openFile(context, task.targetPath),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      tooltip: 'Excluir registro',
                      onPressed: () => _showDeleteDialog(context, ref, task),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

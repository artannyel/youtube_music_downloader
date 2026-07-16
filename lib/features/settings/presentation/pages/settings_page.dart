import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_music_downloader/core/database/isar_service.dart';
import 'package:youtube_music_downloader/features/downloads_history/data/models/download_task.dart';
import 'package:extractor/extractor.dart';
import '../../../downloader_engine/data/services/extractor_service.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _pickCookiesFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);

        if (!await file.exists()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('O arquivo selecionado não existe.')),
            );
          }
          return;
        }

        await ref.read(settingsStateProvider.notifier).updateCookiesPath(path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo de cookies importado com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao selecionar arquivo: $e')),
        );
      }
    }
  }

  void _wipeAllData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Todos os Dados'),
        content: const Text(
          'Esta ação é irreversível e excluirá as configurações de cookies, caminhos de downloads e todo o histórico local de downloads. Os arquivos físicos baixados NÃO serão apagados.',
        ),
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
              // 1. Limpa cookies
              await ref.read(settingsStateProvider.notifier).removeCookies();

              // 2. Limpa o banco de dados Isar
              final isar = IsarService.instance;
              await isar.writeTxn(() async {
                await isar.downloadTasks.clear();
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todos os dados locais foram limpos com sucesso.')),
                );
              }
            },
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDownloaderEngine(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Buscando e aplicando atualizações no yt-dlp...')),
          ],
        ),
      ),
    );

    try {
      final result = await ExtractorService.update();
      if (context.mounted) {
        Navigator.pop(context); // Fecha loader
        
        if (result.status == OperationStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Motor atualizado com sucesso! Versão: ${result.version ?? "mais recente"}'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar: ${result.errorMessage ?? "Erro desconhecido"}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao atualizar o motor: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsStateProvider);
    final theme = Theme.of(context);
    final isCookiesConfigured = state.cookiesPath != null && state.cookiesPath!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // CARD 1: Configuração de Cookies
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.vpn_key_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Autenticação / Cookies',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Importe um arquivo cookies.txt no formato Netscape para burlar limites de idade e acessar conteúdos protegidos por login do YouTube.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              isCookiesConfigured ? Icons.check_circle : Icons.error_outline,
                              color: isCookiesConfigured ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCookiesConfigured ? 'Status: Configurado' : 'Status: Não Configurado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCookiesConfigured ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (isCookiesConfigured) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.folder_open, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.cookiesPath!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isCookiesConfigured) ...[
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                icon: const Icon(Icons.delete),
                                label: const Text('Remover'),
                                onPressed: () {
                                  ref.read(settingsStateProvider.notifier).removeCookies();
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            ElevatedButton.icon(
                              icon: const Icon(Icons.file_open),
                              label: const Text('Importar TXT'),
                              onPressed: () => _pickCookiesFile(context, ref),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 2: Diretórios de Armazenamento
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_shared_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Caminho de Armazenamento',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Localização padrão no armazenamento público do dispositivo onde suas mídias são organizadas:',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        _buildDirectoryRow(
                          icon: Icons.music_video_rounded,
                          label: 'Músicas / Áudio',
                          path: '${state.downloadDirectory}/musicas',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildDirectoryRow(
                          icon: Icons.movie_creation_rounded,
                          label: 'Vídeos / Filmes',
                          path: '${state.downloadDirectory}/videos',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 3: Motor de Downloads (yt-dlp)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.system_update_alt_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Motor de Downloads',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'O YouTube atualiza seus sistemas constantemente. Se os seus downloads começarem a falhar com erro 403 (Forbidden), atualize os componentes do yt-dlp para aplicar as correções mais recentes.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.update_rounded),
                            label: const Text('Atualizar yt-dlp'),
                            onPressed: () => _updateDownloaderEngine(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 4: Manutenção & Reset
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.cleaning_services_rounded,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Manutenção de Dados',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Use com cuidado. Esta ação remove todos os dados locais e reconfigura o aplicativo do zero.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.dangerous_outlined),
                            label: const Text('Limpar Configurações e Banco'),
                            onPressed: () => _wipeAllData(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDirectoryRow({
    required IconData icon,
    required String label,
    required String path,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  path,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

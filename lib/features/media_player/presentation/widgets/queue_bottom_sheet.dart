import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final theme = Theme.of(context);

    return Container(
      height: 450,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Fila de Reprodução (${state.queue.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: state.queue.length,
              itemBuilder: (context, index) {
                final item = state.queue[index];
                final isCurrent = index == state.currentQueueIndex;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.music_note),
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? theme.colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text(item.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: isCurrent
                      ? Icon(Icons.volume_up_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(playerProvider.notifier).loadMedia(
                      item,
                      source: state.source,
                      mediaType: state.mediaType,
                      newQueue: state.queue,
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

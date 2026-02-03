import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../export/providers/export_providers.dart';

/// Chips de filtres pour les documents
class DocumentFilterChips extends ConsumerWidget {
  const DocumentFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(documentFilterProvider);

    if (!filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (filter.exportType != null)
            _FilterChip(
              label: filter.exportType!.label,
              onDeleted: () {
                ref.read(documentFilterProvider.notifier).state = filter
                    .copyWith(exportType: null);
              },
            ),
          if (filter.startDate != null && filter.endDate != null)
            _FilterChip(
              label: 'Période personnalisée',
              onDeleted: () {
                ref.read(documentFilterProvider.notifier).state = filter
                    .copyWith(startDate: null, endDate: null);
              },
            ),
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty)
            _FilterChip(
              label: 'Recherche: "${filter.searchQuery}"',
              onDeleted: () {
                ref.read(documentFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: '');
              },
            ),

          // Bouton pour tout effacer
          TextButton.icon(
            onPressed: () {
              final currentFilter = ref.read(documentFilterProvider);
              ref.read(documentFilterProvider.notifier).state = currentFilter
                  .clearAll();
              // Réinitialiser aussi la recherche
              ref.read(searchQueryProvider.notifier).state = '';
            },
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Tout effacer'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 12,
      ),
    );
  }
}

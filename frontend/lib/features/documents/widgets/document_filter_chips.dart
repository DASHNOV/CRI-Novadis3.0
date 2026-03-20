import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

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
            icon: Icon(Icons.clear_all, size: 16, color: AppTheme.textSecondary),
            label: Text(
              'Tout effacer',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 16,
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

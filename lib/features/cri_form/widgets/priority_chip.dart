import 'package:flutter/material.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

/// Widget chip coloré pour afficher la priorité
class PriorityChip extends StatelessWidget {
  final ServicePriority priority;
  final bool showIcon;
  final bool isSelected;
  final VoidCallback? onTap;

  const PriorityChip({
    super.key,
    required this.priority,
    this.showIcon = true,
    this.isSelected = false,
    this.onTap,
  });

  IconData get _icon {
    switch (priority) {
      case ServicePriority.basse:
        return Icons.arrow_downward;
      case ServicePriority.normale:
        return Icons.remove;
      case ServicePriority.haute:
        return Icons.arrow_upward;
      case ServicePriority.critique:
        return Icons.priority_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = priority.color;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(_icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              priority.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour sélectionner une priorité parmi les options disponibles
class PrioritySelector extends StatelessWidget {
  final ServicePriority? selectedPriority;
  final ValueChanged<ServicePriority> onPriorityChanged;
  final bool enabled;

  const PrioritySelector({
    super.key,
    this.selectedPriority,
    required this.onPriorityChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ServicePriority.values.map((priority) {
        return PriorityChip(
          priority: priority,
          isSelected: selectedPriority == priority,
          onTap: enabled ? () => onPriorityChanged(priority) : null,
        );
      }).toList(),
    );
  }
}

/// Badge de priorité compact pour les listes
class PriorityBadge extends StatelessWidget {
  final ServicePriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priority.color;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Indicateur de priorité avec icône et label
class PriorityIndicator extends StatelessWidget {
  final ServicePriority priority;
  final bool compact;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.compact = false,
  });

  IconData get _icon {
    switch (priority) {
      case ServicePriority.basse:
        return Icons.keyboard_arrow_down;
      case ServicePriority.normale:
        return Icons.remove;
      case ServicePriority.haute:
        return Icons.keyboard_arrow_up;
      case ServicePriority.critique:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = priority.color;
    final theme = Theme.of(context);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 2),
          Text(
            priority.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(_icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Priorité',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                priority.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

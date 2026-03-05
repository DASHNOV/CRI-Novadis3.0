import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/data/models/site_summary_model.dart';

class SiteSummaryCard extends StatelessWidget {
  final SiteSummaryModel summary;
  final VoidCallback onDismiss;
  final VoidCallback onSeeHistory;

  const SiteSummaryCard({
    super.key,
    required this.summary,
    required this.onDismiss,
    required this.onSeeHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RÉSUMÉ DU SITE : ${summary.siteName.toUpperCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  color: colorScheme.onPrimaryContainer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Alert Logic
          if (summary.chronicityAlert)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALERTE : Problème chronique détecté',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary.chronicProblemDescription != null)
                          Text(
                            summary.chronicProblemDescription!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.deepOrange.shade900,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flash Info
                _buildFlashInfo(context),
                const Divider(height: 24),

                // Timeline
                if (summary.timeline.isNotEmpty) ...[
                  _buildSectionTitle(context, 'DERNIERS ÉVÉNEMENTS'),
                  const SizedBox(height: 8),
                  ...summary.timeline.map((e) => _buildTimelineItem(context, e)),
                  const Divider(height: 24),
                ],

                // Technical Heritage
                if (summary.recommendations.isNotEmpty) ...[
                  _buildSectionTitle(context, 'CONSEILS TECHNIQUES'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: summary.recommendations.map((rec) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSeeHistory,
                    child: const Text('HISTORIQUE COMPLET'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('OK, COMPRIS'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIndicator(
          context,
          'Dernière visite',
          summary.lastVisitStatus,
          _getStatusColor(summary.lastVisitStatus),
        ),
        _buildIndicator(
          context,
          'Interventions (6 mois)',
          summary.recurrenceLast6Months.toString(),
          summary.recurrenceLast6Months > 5 ? Colors.orange : Colors.green,
        ),
        if (summary.hasUrgentPendingTickets)
          _buildIndicator(
            context,
            'Urgence',
            'Tickets ouverts',
            Colors.red,
            icon: Icons.priority_high,
          ),
      ],
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: color, size: 24)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    SiteTimelineEventModel event,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dateFormat.format(event.date),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(event.status),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.identifiedCause.isNotEmpty 
                      ? event.identifiedCause 
                      : 'Intervention standard',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.replacedParts.isNotEmpty && event.replacedParts != '-')
                  Text(
                    'Pièces: ${event.replacedParts}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'résolu':
      case 'resolu':
        return Colors.green;
      case 'partiel':
      case 'partiellementresolu':
        return Colors.orange;
      case 'non résolu':
      case 'nonresolu':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}


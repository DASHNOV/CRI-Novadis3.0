import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

class MobileInterventionListItem extends StatefulWidget {
  final String type;
  final String client;
  final DateTime date;
  final String status;
  final VoidCallback? onTap;

  const MobileInterventionListItem({
    super.key,
    required this.type,
    required this.client,
    required this.date,
    required this.status,
    this.onTap,
  });

  @override
  State<MobileInterventionListItem> createState() =>
      _MobileInterventionListItemState();
}

class _MobileInterventionListItemState
    extends State<MobileInterventionListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceVariant : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.2)
                : AppTheme.border.withValues(alpha: 0.5),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForType(widget.type),
                        color: AppTheme.primaryContent,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.type,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.client,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(widget.date),
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  _buildStatusBadge(widget.status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'terminé':
        color = AppTheme.success;
        label = 'Terminé';
        break;
      case 'in_progress':
      case 'en cours':
        color = AppTheme.warning;
        label = 'En cours';
        break;
      default:
        color = AppTheme.textTertiary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.toLowerCase().contains('maintenance')) return Icons.build;
    if (type.toLowerCase().contains('install')) return Icons.settings;
    if (type.toLowerCase().contains('depannage')) return Icons.hardware;
    return Icons.assignment;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

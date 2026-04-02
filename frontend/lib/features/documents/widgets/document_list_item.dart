import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

import '../../export/models/exported_document_model.dart';

/// Widget pour afficher un document dans la liste
class DocumentListItem extends StatefulWidget {
  final ExportedDocumentModel document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final VoidCallback? onShare;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.onShare,
    this.onRename,
    this.onDelete,
  });

  @override
  State<DocumentListItem> createState() => _DocumentListItemState();
}

class _DocumentListItemState extends State<DocumentListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryLight.withValues(alpha: 0.1)
                : _isHovered
                    ? AppTheme.surfaceVariant
                    : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryContent.withValues(alpha: 0.5)
                  : AppTheme.border.withValues(alpha: 0.5),
            ),
            boxShadow: _isHovered ? AppTheme.shadowSm : null,
          ),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icône du type de fichier
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getFileTypeColor(),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      _getFileTypeIcon(),
                      color: AppTheme.textOnPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Informations du document
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom du fichier
                        Text(
                          widget.document.filename,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Date et taille
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(widget.document.createdAt),
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.storage,
                              size: 14,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.document.formattedSize,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        // Badge du type d'export
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            _buildBadge(
                              context,
                              widget.document.exportType.label,
                              _getExportTypeColor(),
                            ),
                            if (widget.document.sharedAt != null)
                              _buildBadge(
                                  context, 'Partagé', AppTheme.success),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Menu d'actions
                  if (!widget.isSelected)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppTheme.textSecondary,
                      ),
                      onSelected: (value) =>
                          _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new),
                              SizedBox(width: 12),
                              Text('Ouvrir'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 12),
                              Text('Partager'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 12),
                              Text('Renommer'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppTheme.error),
                              const SizedBox(width: 12),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.check_circle, color: AppTheme.success),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  IconData _getFileTypeIcon() {
    switch (widget.document.fileType) {
      case DocumentFileType.pdf:
        return Icons.picture_as_pdf;
      case DocumentFileType.csv:
        return Icons.table_chart;
    }
  }

  Color _getFileTypeColor() {
    switch (widget.document.fileType) {
      case DocumentFileType.pdf:
        return AppTheme.error;
      case DocumentFileType.csv:
        return AppTheme.success;
    }
  }

  Color _getExportTypeColor() {
    switch (widget.document.exportType) {
      case ExportType.cri:
        return AppTheme.primaryContent;
      case ExportType.dashboard:
        return AppTheme.warning;
      case ExportType.technician:
        return AppTheme.accent;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'open':
        widget.onTap(); // Utilise le callback onTap existant
        break;
      case 'share':
        if (widget.onShare != null) {
          widget.onShare!();
        }
        break;
      case 'rename':
        if (widget.onRename != null) {
          widget.onRename!();
        }
        break;
      case 'delete':
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
        break;
    }
  }
}

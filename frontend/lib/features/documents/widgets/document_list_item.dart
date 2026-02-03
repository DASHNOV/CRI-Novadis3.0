import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../export/models/exported_document_model.dart';

/// Widget pour afficher un document dans la liste
class DocumentListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône du type de fichier
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getFileTypeIcon(), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),

              // Informations du document
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du fichier
                    Text(
                      document.filename,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(document.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.formattedSize,
                          style: Theme.of(context).textTheme.bodySmall,
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
                          document.exportType.label,
                          _getExportTypeColor(context),
                        ),
                        if (document.sharedAt != null)
                          _buildBadge(context, 'Partagé', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu d'actions
              if (!isSelected)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleMenuAction(context, value),
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.check_circle, color: Colors.green),
            ],
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  IconData _getFileTypeIcon() {
    switch (document.fileType) {
      case DocumentFileType.pdf:
        return Icons.picture_as_pdf;
      case DocumentFileType.csv:
        return Icons.table_chart;
    }
  }

  Color _getFileTypeColor(BuildContext context) {
    switch (document.fileType) {
      case DocumentFileType.pdf:
        return Colors.red;
      case DocumentFileType.csv:
        return Colors.green;
    }
  }

  Color _getExportTypeColor(BuildContext context) {
    switch (document.exportType) {
      case ExportType.cri:
        return Colors.blue;
      case ExportType.dashboard:
        return Colors.orange;
      case ExportType.technician:
        return Colors.purple;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'open':
        onTap(); // Utilise le callback onTap existant
        break;
      case 'share':
        if (onShare != null) {
          onShare!();
        }
        break;
      case 'rename':
        if (onRename != null) {
          onRename!();
        }
        break;
      case 'delete':
        if (onDelete != null) {
          onDelete!();
        }
        break;
    }
  }
}

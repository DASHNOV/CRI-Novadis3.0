import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

import '../../export/models/exported_document_model.dart';

/// État vide quand il n'y a pas de documents
class EmptyDocumentsState extends StatelessWidget {
  final DocumentFileType fileType;
  final VoidCallback onCreatePressed;

  const EmptyDocumentsState({
    super.key,
    required this.fileType,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Aucun document ${_getTypeLabel()}',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Sous-titre
            Text(
              _getSubtitle(),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Bouton d'action
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Créer un export'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (fileType) {
      case DocumentFileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentFileType.csv:
        return Icons.table_chart_outlined;
    }
  }

  String _getTypeLabel() {
    switch (fileType) {
      case DocumentFileType.pdf:
        return 'PDF';
      case DocumentFileType.csv:
        return 'CSV';
    }
  }

  String _getSubtitle() {
    switch (fileType) {
      case DocumentFileType.pdf:
        return 'Exportez votre premier CRI en PDF pour le partager avec vos clients';
      case DocumentFileType.csv:
        return 'Exportez vos données en CSV pour les analyser dans Excel';
    }
  }
}

/// État vide pour les résultats de recherche
class EmptySearchState extends StatelessWidget {
  const EmptySearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun résultat',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

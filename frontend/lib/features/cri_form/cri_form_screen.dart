import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de sélection du type de CRI à créer
/// Permet de choisir entre CRI Projet et CRI Service
class CriFormScreen extends StatelessWidget {
  const CriFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau CRI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Quel type de CRI souhaitez-vous créer ?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez le formulaire adapté à votre intervention',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // CRI Projet Card
              _CriTypeCard(
                icon: Icons.folder_outlined,
                title: 'CRI Projet',
                description:
                    'Pour les interventions liées à des projets structurés : installations, migrations, déploiements...',
                features: const [
                  'Suivi par phase de projet',
                  'Numéro de projet (PRJ-YYYY-NNN)',
                  'Gestion du statut projet',
                ],
                color: theme.colorScheme.primary,
                onTap: () => context.push('/cri/new/projet'),
              ),
              const SizedBox(height: 24),

              // CRI Service Card
              _CriTypeCard(
                icon: Icons.build_outlined,
                title: 'CRI Service',
                description:
                    'Pour les interventions de maintenance, dépannage ou support technique avec ticket.',
                features: const [
                  'Numéro de ticket (TICK-YYYY-NNNNN)',
                  'Gestion des priorités',
                  'Satisfaction client',
                ],
                color: theme.colorScheme.tertiary,
                onTap: () => context.push('/cri/new/service'),
              ),

              const Spacer(),

              // Note
              Text(
                'Les deux formulaires incluent : photos, signatures, et sauvegarde hors-ligne',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de sélection de type CRI
class _CriTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color color;
  final VoidCallback onTap;

  const _CriTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: features.map((feature) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: color.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                feature,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


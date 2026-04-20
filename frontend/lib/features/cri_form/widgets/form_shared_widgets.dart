import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Stepper controls builder shared by both CRI Projet and CRI Service forms.
/// [currentStep] is the active step index, [lastStep] is the index of the final step.
Widget buildCriFormControls(
  BuildContext context,
  ControlsDetails details, {
  required int currentStep,
  required int lastStep,
  required bool isSaving,
  required VoidCallback onSubmit,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // Noir Novadis en light, accent bleu en dark pour un contraste suffisant
  // contre le fond sombre.
  final primaryBg = isDark ? AppTheme.accent : AppTheme.primary;
  final primaryFg = isDark ? const Color(0xFF0A0A0A) : AppTheme.textOnPrimary;

  return Padding(
    padding: const EdgeInsets.only(top: AppTheme.space16),
    child: Row(
      children: [
        if (currentStep < lastStep)
          FilledButton(
            onPressed: details.onStepContinue,
            style: FilledButton.styleFrom(
              backgroundColor: primaryBg,
              foregroundColor: primaryFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Suivant'),
          )
        else
          FilledButton(
            onPressed: isSaving ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: primaryBg,
              foregroundColor: primaryFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryFg,
                    ),
                  )
                : const Text('Soumettre'),
          ),
        const SizedBox(width: AppTheme.space12),
        if (currentStep > 0)
          OutlinedButton(
            onPressed: details.onStepCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Précédent'),
          ),
      ],
    ),
  );
}

/// Bottom bar showing the last auto-save timestamp.
class CriFormAutoSaveBar extends StatelessWidget {
  final DateTime? lastAutoSave;

  const CriFormAutoSaveBar({super.key, required this.lastAutoSave});

  @override
  Widget build(BuildContext context) {
    if (lastAutoSave == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Text(
        'Dernière sauvegarde: ${DateFormat('HH:mm').format(lastAutoSave!)}',
        style: TextStyle(
          color: AppTheme.textTertiary,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Common AppBar for CRI forms.
AppBar buildCriFormAppBar({
  required String title,
  required bool isDirty,
  required VoidCallback onSaveDraft,
  List<Widget>? extraActions,
}) {
  return AppBar(
    backgroundColor: AppTheme.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    title: Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    actions: [
      ...?extraActions,
      if (isDirty)
        IconButton(
          icon: Icon(Icons.save, color: AppTheme.textSecondary),
          onPressed: onSaveDraft,
          tooltip: 'Sauvegarder brouillon',
        ),
    ],
  );
}

/// Loading scaffold shown while form state is loading.
class CriFormLoadingScaffold extends StatelessWidget {
  final String title;

  const CriFormLoadingScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryContent),
      ),
    );
  }
}

/// Responsive row that switches between Row (wide) and Column (narrow) layout.
/// Used for form fields that should be side-by-side on wide screens.
class ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;

  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((child) => Expanded(child: child))
                .toList()
                .expand((widget) sync* {
              yield widget;
              yield const SizedBox(width: AppTheme.space16);
            }).toList()
              ..removeLast(),
          );
        }
        return Column(children: children);
      },
    );
  }
}

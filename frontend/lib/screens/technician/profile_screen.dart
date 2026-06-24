import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/features/auth/data/auth_service.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/services/user_api_service.dart';
import 'package:signature/signature.dart';

/// Ecran Profil du technicien
/// Affiche les infos utilisateur et bouton de deconnexion
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final isDesktop = Responsive.isDesktopOrLarger(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? AppTheme.space40 : AppTheme.space24,
              vertical: AppTheme.space32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Custom header ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profil',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 26 : 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Gap(32),

                // --- Avatar ---
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryContent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'T',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppTheme.animNormal)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: AppTheme.animNormal,
                    ),
                const Gap(20),

                Text(
                  'Technicien',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Gap(4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    'Novadis CRI v1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),

                const Gap(36),

                // --- Signature enregistrée ---
                _SavedSignatureSection()
                    .animate()
                    .fadeIn(
                        duration: AppTheme.animNormal,
                        delay: const Duration(milliseconds: 50))
                    .slideY(begin: 0.04, end: 0),

                const Gap(16),

                // --- A propos section ---
                _buildSectionCard(
                  context: context,
                  children: [
                    _buildMenuTile(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      iconColor: AppTheme.primaryContent,
                      iconBg: AppTheme.primary.withValues(alpha: 0.08),
                      title: 'A propos',
                      subtitle: 'Informations sur l\'application',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('A propos'),
                            content: const Text(
                              'Novadis CRI v1.0.0\n\n'
                              'Application de gestion des comptes rendus '
                              'd\'intervention.\n\n'
                              '(c) 2025 Novadis - Tous droits reserves',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      color: AppTheme.border.withValues(alpha: 0.5),
                      indent: 56,
                    ),
                    _buildMenuTile(
                      context: context,
                      icon: Icons.help_outline_rounded,
                      iconColor: AppTheme.success,
                      iconBg: AppTheme.success.withValues(alpha: 0.08),
                      title: 'Aide',
                      subtitle: 'Centre d\'aide et documentation',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fonctionnalite a venir')),
                        );
                      },
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(
                        duration: AppTheme.animNormal,
                        delay: const Duration(milliseconds: 100))
                    .slideY(begin: 0.04, end: 0),

                const Gap(40),

                // --- Logout ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          title: Text(
                            'Deconnexion',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          content: Text(
                            'Voulez-vous vraiment vous deconnecter ?',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.error,
                              ),
                              child: Text(
                                'Deconnexion',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        try {
                          await ref.read(authServiceProvider).logout();
                        } catch (_) {}
                        if (context.mounted) {
                          context.go(AppRouter.login);
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      'Se deconnecter',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                          color: AppTheme.error.withValues(alpha: 0.3), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      backgroundColor: AppTheme.errorLight.withValues(alpha: 0.3),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: AppTheme.animNormal,
                        delay: const Duration(milliseconds: 200))
                    .slideY(begin: 0.04, end: 0),

                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        boxShadow: AppTheme.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section "Ma signature" dans le profil du technicien
class _SavedSignatureSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sigAsync = ref.watch(savedSignatureProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        boxShadow: AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ma signature',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              sigAsync.when(
                data: (sig) => TextButton.icon(
                  onPressed: () => _showSignatureDialog(context, ref, sig),
                  icon: Icon(sig != null ? Icons.edit : Icons.add, size: 16),
                  label: Text(sig != null ? 'Modifier' : 'Ajouter'),
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => TextButton.icon(
                  onPressed: () => _showSignatureDialog(context, ref, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                ),
              ),
            ],
          ),
          const Gap(8),
          sigAsync.when(
            data: (sig) => sig != null
                ? _buildSignaturePreview(context, sig)
                : _buildEmptyState(context),
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => _buildEmptyState(context),
          ),
          if (sigAsync.valueOrNull != null) ...[
            const Gap(8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer la signature'),
                      content: const Text('Voulez-vous vraiment supprimer votre signature enregistrée ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(savedSignatureProvider.notifier).setSignature(null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signature supprimée')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignaturePreview(BuildContext context, String base64) {
    try {
      final bytes = base64Decode(base64);
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: kIsWeb
              ? Image.memory(bytes, fit: BoxFit.contain)
              : Image.memory(bytes, fit: BoxFit.contain),
        ),
      );
    } catch (_) {
      return _buildEmptyState(context);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          'Aucune signature enregistrée',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _showSignatureDialog(BuildContext context, WidgetRef ref, String? currentBase64) {
    final controller = SignatureController(
      penStrokeWidth: 3.0,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SaveSignatureDialog(
        controller: controller,
        onSave: (base64) async {
          try {
            await ref.read(savedSignatureProvider.notifier).setSignature(base64);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signature enregistrée avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur : $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    ).whenComplete(() => controller.dispose());
  }
}

enum _SignatureMode { draw, import }

class _SaveSignatureDialog extends StatefulWidget {
  final SignatureController controller;
  final Future<void> Function(String base64) onSave;

  const _SaveSignatureDialog({
    required this.controller,
    required this.onSave,
  });

  @override
  State<_SaveSignatureDialog> createState() => _SaveSignatureDialogState();
}

class _SaveSignatureDialogState extends State<_SaveSignatureDialog> {
  bool _isSaving = false;
  _SignatureMode _mode = _SignatureMode.draw;
  Uint8List? _importedBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _importedBytes = bytes);
  }

  Future<void> _save() async {
    Uint8List? bytes;

    if (_mode == _SignatureMode.draw) {
      if (widget.controller.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez dessiner votre signature'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      bytes = await widget.controller.toPngBytes();
    } else {
      if (_importedBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une image'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      bytes = _importedBytes;
    }

    if (bytes == null) return;
    setState(() => _isSaving = true);
    try {
      final base64 = base64Encode(bytes);
      if (!mounted) return;
      await widget.onSave(base64);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width - 32,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ma signature', style: theme.textTheme.titleLarge),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Gap(12),

            // Toggle Dessiner / Importer
            SegmentedButton<_SignatureMode>(
              segments: const [
                ButtonSegment(
                  value: _SignatureMode.draw,
                  icon: Icon(Icons.draw_outlined, size: 16),
                  label: Text('Dessiner'),
                ),
                ButtonSegment(
                  value: _SignatureMode.import,
                  icon: Icon(Icons.upload_file_outlined, size: 16),
                  label: Text('Importer'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _isSaving
                  ? null
                  : (s) => setState(() => _mode = s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Gap(16),

            // Contenu selon le mode
            if (_mode == _SignatureMode.draw) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Signature(
                    controller: widget.controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const Gap(8),
              Text(
                'Dessinez votre signature ci-dessus',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ] else ...[
              GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _importedBytes != null
                        ? Colors.white
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _importedBytes != null
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: _importedBytes != null ? 2 : 1,
                    ),
                  ),
                  child: _importedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(
                            _importedBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: 40,
                              color: theme.colorScheme.outline,
                            ),
                            const Gap(8),
                            Text(
                              'Appuyer pour choisir une image',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'PNG, JPG — fond blanc recommandé',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const Gap(8),
              if (_importedBytes != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _importedBytes = null),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Changer'),
                  ),
                ),
            ],

            const Gap(16),

            // Boutons bas
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_mode == _SignatureMode.draw)
                  TextButton.icon(
                    onPressed:
                        _isSaving ? null : () => widget.controller.clear(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Effacer'),
                  ),
                const Gap(8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

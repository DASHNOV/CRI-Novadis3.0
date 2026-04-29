import 'package:flutter/material.dart';
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

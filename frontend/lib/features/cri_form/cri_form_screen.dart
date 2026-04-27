import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Ecran de selection du type de CRI a creer
/// Permet de choisir entre CRI Projet et CRI Service
class CriFormScreen extends ConsumerWidget {
  const CriFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ContentContainer(
            maxWidth: 900,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space32,
              vertical: AppTheme.space24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inline header with back navigation
                _buildHeader(context),
                const Gap(AppTheme.space48),

                // Title + subtitle centered
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Quel type de CRI souhaitez-vous créer ?',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AppTheme.space8),
                      Text(
                        'Selectionnez le formulaire adapté a votre intervention',
                        style: GoogleFonts.inter(
                          color: AppTheme.textTertiary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: AppTheme.animNormal),
                const Gap(AppTheme.space40),

                // Type selection cards
                _buildCards(context),
                const Gap(AppTheme.space40),

                // Footer note
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                        const Gap(AppTheme.space8),
                        Flexible(
                          child: Text(
                            'Photos, signatures et sauvegarde hors-ligne inclus dans les deux formulaires',
                            style: GoogleFonts.inter(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppTheme.animNormal, delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Row(
      children: [
        if (!isMobile) ...[
          _HeaderBackButton(onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          }),
          const Gap(AppTheme.space12),
        ],
        Text(
          'Nouveau CRI',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppTheme.animFast);
  }

  Widget _buildCards(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    final projetCard = _CriTypeCard(
      icon: Icons.folder_outlined,
      title: 'CRI Projet',
      description:
          'Pour les interventions liées a des projets structures : installations, migrations, déploiements...',
      features: const [
        'Phase du projet',
        'Gestion du statut projet',
      ],
      color: AppTheme.primaryContent,
      colorLight: AppTheme.infoLight,
      onTap: () => context.push('/cri/new/projet'),
    );

    final serviceCard = _CriTypeCard(
      icon: Icons.build_outlined,
      title: 'CRI Service',
      description:
          'Pour les interventions de maintenance, dépannage ou support technique avec suivi de ticket.',
      features: const [
        'Type de demande',
        'Gestion des priorites',
      ],
      color: AppTheme.accent,
      colorLight: const Color(0xFFEDE9FE),
      onTap: () => context.push('/cri/new/service'),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: projetCard
                .animate()
                .fadeIn(duration: AppTheme.animNormal, delay: 100.ms)
                .slideX(begin: -0.05, end: 0),
          ),
          const Gap(AppTheme.space24),
          Expanded(
            child: serviceCard
                .animate()
                .fadeIn(duration: AppTheme.animNormal, delay: 200.ms)
                .slideX(begin: 0.05, end: 0),
          ),
        ],
      );
    }

    return Column(
      children: [
        projetCard
            .animate()
            .fadeIn(duration: AppTheme.animNormal, delay: 100.ms)
            .slideY(begin: 0.05, end: 0),
        const Gap(AppTheme.space20),
        serviceCard
            .animate()
            .fadeIn(duration: AppTheme.animNormal, delay: 200.ms)
            .slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

// ─── Header back button ───

class _HeaderBackButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _HeaderBackButton({required this.onPressed});

  @override
  State<_HeaderBackButton> createState() => _HeaderBackButtonState();
}

class _HeaderBackButtonState extends State<_HeaderBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.surfaceVariant : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── CRI Type Selection Card ───

class _CriTypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color color;
  final Color colorLight;
  final VoidCallback onTap;

  const _CriTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.color,
    required this.colorLight,
    required this.onTap,
  });

  @override
  State<_CriTypeCard> createState() => _CriTypeCardState();
}

class _CriTypeCardState extends State<_CriTypeCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: AppTheme.animFast,
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            padding: const EdgeInsets.all(AppTheme.space32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: _isHovered ? widget.color : AppTheme.border,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered ? AppTheme.shadowMd : AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in colored circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.colorLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: widget.color,
                  ),
                ),
                const Gap(AppTheme.space20),

                // Title
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Gap(AppTheme.space8),

                // Description
                Text(
                  widget.description,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const Gap(AppTheme.space20),

                // Feature list with checkmarks
                ...widget.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.successLight,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppTheme.success,
                          ),
                        ),
                        const Gap(AppTheme.space12),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(AppTheme.space12),

                // CTA arrow row
                Row(
                  children: [
                    Text(
                      'Commencer',
                      style: GoogleFonts.inter(
                        color: widget.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(AppTheme.space4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: widget.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/auth/data/auth_service.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Ecran de connexion
/// Authentification par email avec code de verification
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final emailController = useTextEditingController();
    final isLoading = useState(false);
    final authService = ref.watch(authServiceProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    void handleLogin() async {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer votre email'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      isLoading.value = true;
      try {
        await authService.login(email);
        if (context.mounted) {
          context.push('${AppRouter.verifyOtp}?email=$email');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                // Left branding panel (60%)
                Expanded(
                  flex: 6,
                  child: _BrandingPanel(),
                ),
                // Right form panel (40%)
                Expanded(
                  flex: 4,
                  child: _FormPanel(
                    emailController: emailController,
                    isLoading: isLoading,
                    onLogin: handleLogin,
                  ),
                ),
              ],
            )
          : _FormPanel(
              emailController: emailController,
              isLoading: isLoading,
              onLogin: handleLogin,
              showLogo: true,
            ),
    );
  }
}

// ─── Branding Panel (Desktop Left Side) ───

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.accent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Decorative grid dots
          Positioned(
            bottom: 80,
            left: 60,
            child: _GridDots(),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'N',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Gap(32),
                  Text(
                    'Novadis CRI',
                    style: GoogleFonts.inter(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 350.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Gap(12),
                  Text(
                    'Compte Rendu d\'Intervention',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Gap(32),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 650.ms),
                  const Gap(24),
                  Text(
                    'Gerez vos interventions, suivez vos comptes\nrendus et collaborez avec votre equipe.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.7,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(
          25,
          (i) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form Panel ───

class _FormPanel extends StatelessWidget {
  final TextEditingController emailController;
  final ValueNotifier<bool> isLoading;
  final VoidCallback onLogin;
  final bool showLogo;

  const _FormPanel({
    required this.emailController,
    required this.isLoading,
    required this.onLogin,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    // Mobile logo
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primary, AppTheme.accent],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'N',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const Gap(24),
                    Text(
                      'Novadis CRI',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                    const Gap(4),
                    Text(
                      'Compte Rendu d\'Intervention',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                    const Gap(48),
                  ],
                  // Title
                  Text(
                    'Connexion',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const Gap(8),
                  Text(
                    'Entrez votre email pour recevoir un code de verification.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 280.ms),
                  const Gap(32),
                  // Email label
                  Text(
                    'Adresse email',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                  const Gap(8),
                  // Email field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'exemple@novadis.fr',
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: AppTheme.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onLogin(),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  const Gap(24),
                  // Login button
                  ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, loading, _) {
                      return AnimatedContainer(
                        duration: AppTheme.animFast,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          gradient: loading
                              ? null
                              : const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.accent],
                                ),
                          color: loading
                              ? AppTheme.primary.withValues(alpha: 0.6)
                              : null,
                          boxShadow: loading
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: loading ? null : onLogin,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Recevoir un code par email',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 470.ms),
                  const Gap(24),
                  // Note
                  Text(
                    'Un code de verification vous sera envoye par email pour vous connecter en toute securite.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 550.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

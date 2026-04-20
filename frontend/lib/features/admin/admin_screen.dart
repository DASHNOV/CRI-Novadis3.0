import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';

const String _appVersion = '1.0.0';

class AdminScreen extends HookConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final storage = ref.watch(storageServiceProvider);
    final role = ref.watch(userRoleProvider);
    final nameFuture = useMemoized(() => storage.getUserName(), [storage]);
    final nameSnap = useFuture(nameFuture);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    Future<void> handleLogout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(storageServiceProvider).clearTokens();
        if (context.mounted) {
          context.go(AppRouter.login);
        }
      }
    }

    void showAbout() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text('À propos'),
          content: const Text(
            'Novadis CRI v$_appVersion\n\n'
            'Application de gestion des comptes rendus d\'intervention.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ContentContainer(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space20),
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Compte, apparence et préférences',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _AccountCard(
              name: nameSnap.data ?? 'Utilisateur',
              role: role ?? '',
            ),
            const SizedBox(height: AppTheme.space24),

            const _SectionLabel('Apparence'),
            const SizedBox(height: AppTheme.space12),
            _SettingsGroup(
              children: [
                _ThemeToggleTile(
                  isDark: isDark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space24),

            const _SectionLabel('Application'),
            const SizedBox(height: AppTheme.space12),
            _SettingsGroup(
              children: [
                _ActionListTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppTheme.primaryContent,
                  title: 'À propos',
                  subtitle: 'Version $_appVersion',
                  onTap: showAbout,
                ),
                _Divider(),
                _ActionListTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.error,
                  title: 'Se déconnecter',
                  subtitle: 'Fermer la session sur cet appareil',
                  destructive: true,
                  onTap: handleLogout,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space32),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final String role;

  const _AccountCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final displayRole = role.isEmpty ? '—' : role;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryContent,
                  AppTheme.primaryContent.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    displayRole,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryContent,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppTheme.space16,
      endIndent: AppTheme.space16,
      color: AppTheme.border.withValues(alpha: 0.5),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ThemeToggleTile({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final icon = isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded;
    final color = isDark ? AppTheme.accent : AppTheme.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode sombre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Activé' : 'Désactivé',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryContent,
          ),
        ],
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: destructive ? AppTheme.error : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
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
    );
  }
}

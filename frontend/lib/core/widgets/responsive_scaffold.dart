import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Données de navigation pour chaque destination
class NavDestination {
  final Icon icon;
  final Icon activeIcon;
  final String label;
  final String? group;
  final int? badgeCount;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.group,
    this.badgeCount,
  });
}

/// Scaffold responsive : Sidebar moderne sur desktop, BottomNav sur mobile
class ResponsiveScaffold extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<NavDestination> destinations;
  final List<Widget> screens;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.destinations,
    required this.screens,
  });

  @override
  ConsumerState<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold>
    with SingleTickerProviderStateMixin {
  bool _sidebarCollapsed = false;
  late AnimationController _collapseController;
  late Animation<double> _sidebarWidth;

  static const double _expandedWidth = 248;
  static const double _collapsedWidth = 68;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      duration: AppTheme.animNormal,
      vsync: this,
    );
    _sidebarWidth = Tween<double>(
      begin: _expandedWidth,
      end: _collapsedWidth,
    ).animate(CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
      if (_sidebarCollapsed) {
        _collapseController.forward();
      } else {
        _collapseController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: bottom nav
        if (constraints.maxWidth < 640) {
          return _buildMobileLayout(context);
        }
        // Tablet: sidebar collapsed by default
        if (constraints.maxWidth < 1024) {
          return _buildDesktopLayout(context, forceCollapsed: true);
        }
        // Desktop: sidebar expanded
        return _buildDesktopLayout(context, forceCollapsed: false);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, {required bool forceCollapsed}) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedBuilder(
            animation: _sidebarWidth,
            builder: (context, child) {
              final width = forceCollapsed
                  ? _collapsedWidth
                  : _sidebarWidth.value;
              final isCollapsed = forceCollapsed || _sidebarCollapsed;

              return Container(
                width: width,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // ─── Logo / Header ───
                    _SidebarHeader(
                      isCollapsed: isCollapsed,
                    ),

                    const SizedBox(height: 8),

                    // ─── Navigation Items ───
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 8 : 12,
                          vertical: 4,
                        ),
                        children: List.generate(
                          widget.destinations.length,
                          (index) => _SidebarItem(
                            destination: widget.destinations[index],
                            isActive: widget.currentIndex == index,
                            isCollapsed: isCollapsed,
                            onTap: () => widget.onIndexChanged(index),
                          ),
                        ),
                      ),
                    ),

                    // ─── Theme Toggle ───
                    _ThemeToggleButton(isCollapsed: isCollapsed),

                    // ─── Collapse Toggle ───
                    if (!forceCollapsed)
                      _CollapseButton(
                        isCollapsed: isCollapsed,
                        onTap: _toggleSidebar,
                      ),
                  ],
                ),
              );
            },
          ),

          // ─── Main Content ───
          Expanded(
            child: IndexedStack(
              index: widget.currentIndex,
              children: widget.screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final hasExtraDestination = widget.destinations.length > 4;
    final lastIndex = widget.destinations.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const _MobileTopBar(),
          Expanded(
            child: IndexedStack(
              index: widget.currentIndex,
              children: widget.screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ...List.generate(
                  // Show first 4 items; the last slot is reserved for the
                  // final destination (Admin / Profil) when present.
                  hasExtraDestination ? 4 : widget.destinations.length,
                  (index) => _BottomNavItem(
                    destination: widget.destinations[index],
                    isActive: widget.currentIndex == index,
                    onTap: () => widget.onIndexChanged(index),
                  ),
                ),
                if (hasExtraDestination)
                  _BottomNavItem(
                    destination: widget.destinations[lastIndex],
                    isActive: widget.currentIndex == lastIndex,
                    onTap: () => widget.onIndexChanged(lastIndex),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mobile Top Bar (commun à toutes les pages) ───
class _MobileTopBar extends ConsumerWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => ref.read(themeModeProvider.notifier).toggle(),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedSwitcher(
                  duration: AppTheme.animFast,
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    key: ValueKey(isDark),
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sidebar Header ───
class _SidebarHeader extends StatelessWidget {
  final bool isCollapsed;

  const _SidebarHeader({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 12 : 20,
        vertical: 20,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/logos/novadis_logo_black.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novadis CRI',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Gestion des interventions',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sidebar Item ───
class _SidebarItem extends StatefulWidget {
  final NavDestination destination;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive
        ? AppTheme.accent
        : _isHovered
            ? AppTheme.textPrimary
            : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Tooltip(
          message: widget.isCollapsed ? widget.destination.label : '',
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: AnimatedContainer(
                duration: AppTheme.animFast,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 12 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppTheme.accent.withValues(alpha: 0.08)
                      : _isHovered
                          ? AppTheme.surfaceVariant.withValues(alpha: 0.7)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: widget.isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    // Active indicator
                    if (widget.isActive && !widget.isCollapsed)
                      Container(
                        width: 3,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                    // Icon
                    IconTheme(
                      data: IconThemeData(
                        color: iconColor,
                        size: 20,
                      ),
                      child: widget.isActive
                          ? widget.destination.activeIcon
                          : widget.destination.icon,
                    ),

                    // Label
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.destination.label,
                          style: TextStyle(
                            color: widget.isActive
                                ? AppTheme.accent
                                : _isHovered
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    // Badge
                    if (widget.destination.badgeCount != null &&
                        widget.destination.badgeCount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${widget.destination.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Collapse Button ───
class _CollapseButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _CollapseButton({
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: isCollapsed ? 8 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  isCollapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 20,
                  color: AppTheme.textTertiary,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Réduire',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Theme Toggle Button ───
class _ThemeToggleButton extends ConsumerWidget {
  final bool isCollapsed;

  const _ThemeToggleButton({required this.isCollapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: AnimatedContainer(
            duration: AppTheme.animNormal,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.accent.withValues(alpha: 0.08)
                  : AppTheme.surfaceVariant.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: AppTheme.animNormal,
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    key: ValueKey(isDark),
                    size: 20,
                    color: isDark ? AppTheme.accent : AppTheme.warning,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDark ? 'Mode sombre' : 'Mode clair',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Nav Item (Mobile) ───
class _BottomNavItem extends StatelessWidget {
  final NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with active pill background
                AnimatedContainer(
                  duration: AppTheme.animFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: isActive
                          ? AppTheme.accent
                          : AppTheme.textTertiary,
                      size: 22,
                    ),
                    child: isActive
                        ? destination.activeIcon
                        : destination.icon,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.accent
                        : AppTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


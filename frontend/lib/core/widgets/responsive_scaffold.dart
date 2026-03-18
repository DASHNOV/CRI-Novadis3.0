import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Données de navigation pour chaque destination
class NavDestination {
  final Icon icon;
  final Icon activeIcon;
  final String label;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Scaffold responsive : BottomNavigationBar sur mobile, NavigationRail sur desktop
class ResponsiveScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return _buildDesktopLayout(context, constraints);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final extended = constraints.maxWidth >= 1200;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onIndexChanged,
            extended: extended,
            minExtendedWidth: 220,
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.lightGray,
            selectedIconTheme: IconThemeData(color: AppTheme.primaryBlue),
            unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
            selectedLabelTextStyle: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            leading: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: extended ? 16 : 8,
              ),
              child: extended
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          radius: 18,
                          child: const Text(
                            'N',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Novadis CRI',
                          style: TextStyle(
                            color: AppTheme.darkBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    )
                  : CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      radius: 18,
                      child: const Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.activeIcon,
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          Container(
            width: 1,
            color: AppTheme.lightGray,
          ),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onIndexChanged,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: destinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: d.icon,
                  activeIcon: d.activeIcon,
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

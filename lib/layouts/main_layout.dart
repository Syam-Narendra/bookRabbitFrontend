import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Permanent Shell Layout for Book Rabbit.
///
/// Houses the [StatefulNavigationShell] body alongside the fixed, persistent
/// navigation shell (BottomNavigationBar on mobile, NavigationRail on wide desktop/tablet screens).
///
/// Key properties:
/// 1. The navigation bar/rail never rebuilds when navigating between branches or child pages.
/// 2. Only the child view ([navigationShell]) rebuilds during tab transitions.
/// 3. Tab selection triggers [StatefulNavigationShell.goBranch].
class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  void _onTabSelected(int index) {
    // Switch to the target branch.
    // If tapping the already-active tab, initialLocation: true pops to the root of that branch.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final bgColor = context.bgColor;
    final currentIndex = navigationShell.currentIndex;

    final Widget scaffold = isWide
        ? Scaffold(
            backgroundColor: bgColor,
            body: Container(
              color: bgColor,
              child: Row(
                children: [
                  // Side navigation rail matching theme
                  NavigationRail(
                    backgroundColor: bgColor,
                    useIndicator: false,
                    indicatorColor: Colors.transparent,
                    selectedIndex: currentIndex,
                    onDestinationSelected: _onTabSelected,
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(
                      color: Color(0xFFE54F3F),
                      size: 26,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: context.subTextColor,
                      size: 24,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: Color(0xFFE54F3F),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: context.subTextColor,
                      fontSize: 12,
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.book_outlined),
                        selectedIcon: Icon(Icons.book),
                        label: Text('Discover'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history),
                        selectedIcon: Icon(Icons.history),
                        label: Text('History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Account'),
                      ),
                    ],
                  ),
                  VerticalDivider(width: 1, color: context.borderColor),
                  // Persistent Branch Body
                  Expanded(
                    child: SafeArea(
                      child: navigationShell,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            backgroundColor: bgColor,
            resizeToAvoidBottomInset: false,
            body: Container(
              color: bgColor,
              child: Stack(
                children: [
                  // Persistent Branch Body
                  navigationShell,
                  // Floating Glassmorphic Bottom Navigation Bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomOverlay(context, currentIndex),
                  ),
                ],
              ),
            ),
          );

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          _onTabSelected(0);
        }
      },
      child: scaffold,
    );
  }

  Widget _buildBottomOverlay(BuildContext context, int currentIndex) {
    final overlayColor = context.bgColor;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                overlayColor.withValues(alpha: 0.0),
                overlayColor.withValues(alpha: 0.65),
                overlayColor.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFFE54F3F),
                  unselectedItemColor: context.subTextColor,
                  currentIndex: currentIndex,
                  onTap: _onTabSelected,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.book_outlined),
                      ),
                      label: 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.history),
                      ),
                      label: 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person_outline),
                      ),
                      label: 'Account',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 6.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

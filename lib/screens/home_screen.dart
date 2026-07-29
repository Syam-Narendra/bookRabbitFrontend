import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tabs/discover_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/account_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget _buildTabContent() {
    Widget tabWidget;
    switch (_currentIndex) {
      case 0:
        tabWidget = DiscoverTab(
          key: const ValueKey('tab_discover'),
          onProfileTapped: () => setState(() => _currentIndex = 2),
        );
        break;
      case 1:
        tabWidget = HistoryTab(
          key: const ValueKey('tab_history'),
          onProfileTapped: () => setState(() => _currentIndex = 2),
        );
        break;
      default:
        tabWidget = const AccountTab(key: ValueKey('tab_account'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: tabWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final bgColor = context.bgColor;

    final Widget scaffold = isWide
        ? Scaffold(
            backgroundColor: bgColor,
            body: Container(
              color: bgColor,
              child: Row(
                children: [
                  // Side navigation rail matching current theme
                  NavigationRail(
                    backgroundColor: bgColor,
                    useIndicator: false,
                    indicatorColor: Colors.transparent,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (i) => setState(() => _currentIndex = i),
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(color: Color(0xFFE54F3F), size: 26),
                    unselectedIconTheme: IconThemeData(color: context.subTextColor, size: 24),
                    selectedLabelTextStyle: const TextStyle(color: Color(0xFFE54F3F), fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelTextStyle: TextStyle(color: context.subTextColor, fontSize: 12),
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
                  // Main content
                  Expanded(
                    child: SafeArea(
                      child: _buildTabContent(),
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
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    _buildTabContent(),
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: _buildBottomOverlay(),
                    ),
                  ],
                ),
              ),
            ),
          );

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: scaffold,
    );
  }

  Widget _buildBottomOverlay() {
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
                data: ThemeData(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFFE54F3F),
                  unselectedItemColor: context.subTextColor,
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.book_outlined)),
                      label: 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)),
                      label: 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
                      label: 'Account',
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 6.0),
            ],
          ),
        ),
      ),
    );
  }
}


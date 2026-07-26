import 'dart:ui';
import 'package:flutter/material.dart';

import 'tabs/discover_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/account_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background color from main.dart
      resizeToAvoidBottomInset: false, // Prevents app from shrinking when keyboard opens
      body: Center(
        child: Container(
          width: isDesktop ? 450 : double.infinity,
          height: double.infinity,
          color: const Color(0xFF161616), // Inner app background
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
            // Using IndexedStack preserves state of tabs (e.g. search query)
            IndexedStack(
              index: _currentIndex,
              children: [
                DiscoverTab(
                  onProfileTapped: () {
                    setState(() {
                      _currentIndex = 2; // Switch to AccountTab
                    });
                  },
                ),
                const HistoryTab(),
                const AccountTab(),
              ],
            ),
            

            
            // Bottom Gradient and Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomOverlay(),
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF161616).withValues(alpha: 0.0),
                const Color(0xFF161616).withValues(alpha: 0.65),
                const Color(0xFF161616).withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom Navigation Bar
              Theme(
                data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFFE54F3F), // Red color
                  unselectedItemColor: const Color(0xFF98989E),
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
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
              const SizedBox(height: 34), // Add some bottom padding for the home indicator
            ],
          ),
        ),
      ),
    );
  }

}

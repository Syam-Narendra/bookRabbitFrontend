import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../services/api_client.dart';
import '../../services/vendor_auth_service.dart';
import '../../theme/app_theme.dart';
import 'vendor_overview_tab.dart';
import 'vendor_bookings_tab.dart';
import 'vendor_calendar_tab.dart';
import 'vendor_grounds_tab.dart';
import 'vendor_revenue_tab.dart';
import 'vendor_settings_tab.dart';

/// Authenticated vendor shell: loads the dashboard payload once, then hosts the
/// six dashboard tabs (Overview, Bookings, Calendar, Grounds, Revenue, Settings)
/// behind a consistent navigation (rail on wide screens, bottom bar on narrow).
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _currentIndex = 0;
  VendorDashboard? _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dashboard = await VendorAuthService.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } on AuthException {
      await VendorAuthService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/vendor_login', (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await _confirmLogout();
    if (confirmed != true) return;
    await VendorAuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/vendor_login', (route) => false);
  }

  Future<bool?> _confirmLogout() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final dashboard = _dashboard;
    if (dashboard == null) return const SizedBox.shrink();
    final tab = switch (_currentIndex) {
      0 => VendorOverviewTab(
          key: const ValueKey('vendor_overview'),
          dashboard: dashboard,
          onRefresh: _load,
        ),
      1 => VendorBookingsTab(
          key: const ValueKey('vendor_bookings'),
          dashboard: dashboard,
        ),
      2 => VendorCalendarTab(
          key: const ValueKey('vendor_calendar'),
          dashboard: dashboard,
        ),
      3 => VendorGroundsTab(
          key: const ValueKey('vendor_grounds'),
          dashboard: dashboard,
          onRefresh: _load,
        ),
      4 => VendorRevenueTab(
          key: const ValueKey('vendor_revenue'),
          dashboard: dashboard,
        ),
      _ => VendorSettingsTab(
          key: const ValueKey('vendor_settings'),
          dashboard: dashboard,
          onRefresh: _load,
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.01, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: tab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final ownerName = _dashboard?.owner?['owner_name'] as String?;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: isWide
          ? _buildWideLayout(ownerName)
          : _buildNarrowLayout(ownerName),
    );
  }

  Widget _buildWideLayout(String? ownerName) {
    return Container(
      color: context.bgColor,
      child: Row(
        children: [
          // Side navigation rail matching the app's theme.
          NavigationRail(
            backgroundColor: context.bgColor,
            useIndicator: false,
            indicatorColor: Colors.transparent,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            minWidth: 72,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Color(0xFFE54F3F), size: 26),
            unselectedIconTheme: IconThemeData(color: context.subTextColor, size: 24),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFFE54F3F), fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelTextStyle: TextStyle(color: context.subTextColor, fontSize: 12),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7B42),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Bookings')),
              NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Calendar')),
              NavigationRailDestination(icon: Icon(Icons.stadium_outlined), selectedIcon: Icon(Icons.stadium), label: Text('Grounds')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Revenue')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          VerticalDivider(width: 1, color: context.borderColor),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(ownerName),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(String? ownerName) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(ownerName),
          Expanded(child: _buildBody()),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: NavigationBar(
              backgroundColor: context.cardBg,
              indicatorColor: const Color(0xFFFF7B42).withValues(alpha: 0.15),
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
                NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bookings'),
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
                NavigationDestination(icon: Icon(Icons.stadium_outlined), selectedIcon: Icon(Icons.stadium), label: 'Grounds'),
                NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Revenue'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String? ownerName) {
    final displayName = (ownerName?.isNotEmpty ?? false) ? ownerName! : 'Owner';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dashboard == null ? '' : 'Dashboard',
                style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (_dashboard != null)
                Text(
                  displayName,
                  style: TextStyle(color: context.subTextColor, fontSize: 13),
                ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.subCardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.logout, color: context.subTextColor, size: 18),
                  const SizedBox(width: 6),
                  Text('Logout', style: TextStyle(color: context.subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.textColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _buildTabContent(),
    );
  }
}

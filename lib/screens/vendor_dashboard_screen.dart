import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/vendor_auth_service.dart';
import '../theme/app_theme.dart';

/// MVP read-only vendor/owner dashboard: stats + grounds overview.
/// Ground management, bank details, settings and live session events are
/// deferred to a follow-up pass — see the sync plan for scope notes.
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

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
      final stats = await VendorAuthService.fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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
    await VendorAuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/vendor_login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Vendor Dashboard', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: context.textColor,
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(_error!)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildContent(),
                  ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.textColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stats = _stats!;
    final owner = stats['owner'] as Map<String, dynamic>?;
    final grounds = (stats['grounds'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0;
    final totalBookings = (stats['totalBookings'] as num?)?.toInt() ?? 0;
    final activeGrounds = grounds.where((g) => g['status'] == 'active').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          owner?['owner_name'] as String? ?? 'Owner',
          style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          owner?['phone'] as String? ?? '',
          style: TextStyle(color: context.subTextColor, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _statCard('Revenue', '₹${totalRevenue.toStringAsFixed(0)}')),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Bookings', '$totalBookings')),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Active grounds', '$activeGrounds')),
          ],
        ),
        const SizedBox(height: 28),
        Text('Your grounds', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (grounds.isEmpty)
          Text('No grounds yet.', style: TextStyle(color: context.subTextColor))
        else
          ...grounds.map(_groundCard),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.subTextColor, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _groundCard(Map<String, dynamic> ground) {
    final status = ground['status'] as String? ?? 'pending';
    final statusColor = switch (status) {
      'active' => Colors.green,
      'pending' => Colors.orange,
      _ => Colors.grey,
    };
    final bookingsCount = (ground['bookings'] as List<dynamic>? ?? []).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ground['name'] as String? ?? '', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(ground['address'] as String? ?? '', style: TextStyle(color: context.subTextColor, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$bookingsCount recent booking${bookingsCount == 1 ? '' : 's'}', style: TextStyle(color: context.subTextColor, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

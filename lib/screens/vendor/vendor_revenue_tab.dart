import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Revenue hub: today's + lifetime collections, with a daily/monthly breakdown
/// computed client-side from confirmed bookings.
class VendorRevenueTab extends StatefulWidget {
  final VendorDashboard dashboard;

  const VendorRevenueTab({super.key, required this.dashboard});

  @override
  State<VendorRevenueTab> createState() => _VendorRevenueTabState();
}

class _VendorRevenueTabState extends State<VendorRevenueTab> {
  bool _monthly = false;

  List<VendorBooking> get _confirmed => widget.dashboard.confirmedBookings;

  double get _todayRevenue {
    final key = _dateKey(DateTime.now());
    return _confirmed
        .where((b) => b.date == key)
        .fold<double>(0, (sum, b) => sum + b.amount);
  }

  double get _lifetimeRevenue =>
      _confirmed.fold<double>(0, (sum, b) => sum + b.amount);

  List<_DailyRevenueRow> get _dailyRows {
    final map = <String, List<VendorBooking>>{};
    for (final b in _confirmed) {
      if (b.date == null) continue;
      map.putIfAbsent(b.date!, () => []).add(b);
    }
    final rows = map.entries
        .map((e) => _DailyRevenueRow(
              key: e.key,
              label: _formatDailyLabel(e.key),
              count: e.value.length,
              revenue: e.value.fold<double>(0, (s, b) => s + b.amount),
              isPast: e.key != _dateKey(DateTime.now()),
            ))
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return rows;
  }

  List<_MonthlyRevenueRow> get _monthlyRows {
    final map = <String, List<VendorBooking>>{};
    for (final b in _confirmed) {
      if (b.date == null || b.date!.length < 7) continue;
      final monthKey = b.date!.substring(0, 7); // YYYY-MM
      map.putIfAbsent(monthKey, () => []).add(b);
    }
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final rows = map.entries
        .map((e) => _MonthlyRevenueRow(
              key: e.key,
              label: _formatMonthlyLabel(e.key),
              count: e.value.length,
              revenue: e.value.fold<double>(0, (s, b) => s + b.amount),
              isPast: e.key != currentKey,
            ))
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _monthly ? _monthlyRows : _dailyRows;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Revenue Hub', style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Track your daily collections', style: TextStyle(color: context.subTextColor, fontSize: 13)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: VendorStatCard(
                label: "Today's Collection",
                value: formatInr(_todayRevenue),
                icon: Icons.today_outlined,
                color: const Color(0xFF2E8443),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VendorStatCard(
                label: 'Total Lifetime Earned',
                value: formatInr(_lifetimeRevenue),
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revenue Breakdown',
                    style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.subCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _SegButton(
                          label: 'Daily',
                          active: !_monthly,
                          onTap: () => setState(() => _monthly = false),
                        ),
                        _SegButton(
                          label: 'Monthly',
                          active: _monthly,
                          onTap: () => setState(() => _monthly = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                VendorEmptyState(
                  icon: Icons.insert_chart_outlined,
                  title: 'No revenue data yet',
                  subtitle: 'Confirmed bookings will appear here.',
                )
              else
                ...rows.map((row) => _buildRow(row)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_RevenueRowLike row) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  '${row.count} booking${row.count == 1 ? '' : 's'}',
                  style: TextStyle(color: context.subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (row.isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.subCardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Completed',
                style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            formatInr(row.revenue),
            style: const TextStyle(color: Color(0xFF2E8443), fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDailyLabel(String key) {
    try {
      return DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(key));
    } catch (_) {
      return key;
    }
  }

  String _formatMonthlyLabel(String key) {
    try {
      return DateFormat('MMMM yyyy').format(DateTime.parse('$key-01'));
    } catch (_) {
      return key;
    }
  }
}

sealed class _RevenueRowLike {
  final String label;
  final int count;
  final double revenue;
  final bool isPast;
  const _RevenueRowLike(this.label, this.count, this.revenue, this.isPast);
}

class _DailyRevenueRow extends _RevenueRowLike {
  final String key;
  _DailyRevenueRow({
    required this.key,
    required String label,
    required int count,
    required double revenue,
    required bool isPast,
  }) : super(label, count, revenue, isPast);
}

class _MonthlyRevenueRow extends _RevenueRowLike {
  final String key;
  _MonthlyRevenueRow({
    required this.key,
    required String label,
    required int count,
    required double revenue,
    required bool isPast,
  }) : super(label, count, revenue, isPast);
}

class _SegButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SegButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF7B42) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : context.subTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

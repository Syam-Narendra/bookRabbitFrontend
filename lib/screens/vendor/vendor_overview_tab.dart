import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Dashboard home: sales summary, today's metrics, recent bookings and a
/// simple 7-day activity feed. Mirrors the Remix dashboard overview.
class VendorOverviewTab extends StatefulWidget {
  final VendorDashboard dashboard;
  final Future<void> Function() onRefresh;

  const VendorOverviewTab({
    super.key,
    required this.dashboard,
    required this.onRefresh,
  });

  @override
  State<VendorOverviewTab> createState() => _VendorOverviewTabState();
}

class _VendorOverviewTabState extends State<VendorOverviewTab> {
  DateTime _activityDate = DateTime.now();

  List<_DailyRevenue> _last7Days() {
    final days = <_DailyRevenue>[];
    final confirmed = widget.dashboard.confirmedBookings;
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final revenue = confirmed
          .where((b) => b.date == key)
          .fold<double>(0, (sum, b) => sum + b.amount);
      final count = confirmed.where((b) => b.date == key).length;
      days.add(_DailyRevenue(day: day, revenue: revenue, count: count));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final confirmed = dashboard.confirmedBookings;
    final todayKey = _dateKey(DateTime.now());

    final todayRevenue = confirmed
        .where((b) => b.date == todayKey)
        .fold<double>(0, (sum, b) => sum + b.amount);
    final todayCount = confirmed.where((b) => b.date == todayKey).length;

    final recentBookings = dashboard.allBookings
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    final recent = recentBookings.take(6).toList();

    final chartDays = _last7Days();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 700;
          final statCards = <Widget>[
            VendorStatCard(
              label: "Today's Bookings",
              value: '$todayCount',
              icon: Icons.calendar_today_outlined,
              color: const Color(0xFF2E8443),
            ),
            VendorStatCard(
              label: "Today's Revenue",
              value: formatInr(todayRevenue),
              icon: Icons.payments_outlined,
            ),
            VendorStatCard(
              label: 'Total Slots',
              value: '${confirmed.length}',
              icon: Icons.confirmation_number_outlined,
              color: const Color(0xFF2563EB),
            ),
            VendorStatCard(
              label: 'Total Revenue',
              value: formatInr(dashboard.totalRevenue),
              icon: Icons.trending_up,
              color: const Color(0xFF7C3AED),
            ),
          ];

          if (twoCol) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: statCards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: statCards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: statCards[2]),
                    const SizedBox(width: 12),
                    Expanded(child: statCards[3]),
                  ],
                ),
                const SizedBox(height: 20),
                _buildChartCard(chartDays),
              ],
            );
          }
          return Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: statCards,
              ),
              const SizedBox(height: 20),
              _buildChartCard(chartDays),
            ],
          );
        }),
        const SizedBox(height: 20),
        _buildActivityPanel(confirmed, todayKey),
        const SizedBox(height: 20),
        VendorSectionHeader(
          title: 'Recent Bookings',
          trailing: Text(
            'View all →',
            style: TextStyle(color: const Color(0xFFFF7B42), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          VendorEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No bookings found',
            subtitle: 'When customers book your grounds they will appear here.',
          )
        else
          ...recent.map((b) {
            final ground = dashboard.grounds
                .where((g) => g.id == b.groundId)
                .firstOrNull;
            return bookingRow(
              context,
              booking: b,
              groundName: ground?.name,
              groundIcon: ground?.icon,
            );
          }),
      ],
    );
  }

  Widget _buildChartCard(List<_DailyRevenue> days) {
    final total = days.fold<double>(0, (sum, d) => sum + d.revenue);
    final totalCount = days.fold<int>(0, (sum, d) => sum + d.count);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Performance',
            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Bookings over last 7 days',
            style: TextStyle(color: context.subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: _RevenueBars(days: days),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChartMetric(
                  icon: Icons.bar_chart,
                  label: 'Total Slots',
                  value: '$totalCount',
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _ChartMetric(
                  icon: Icons.payments,
                  label: 'Revenue (7d)',
                  value: formatInr(total),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPanel(List<VendorBooking> confirmed, String todayKey) {
    final activeDay = _activityDate;
    final days = [
      for (int i = -3; i <= 3; i++) activeDay.add(Duration(days: i)),
    ];
    final activity = confirmed
        .where((b) => b.date == _dateKey(activeDay))
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _longDate(activeDay),
            style: TextStyle(color: context.subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = days[i];
                final isSelected = _dateKey(day) == _dateKey(activeDay);
                final hasBooking = confirmed.any((b) => b.date == _dateKey(day));
                return GestureDetector(
                  onTap: () => setState(() => _activityDate = day),
                  child: Container(
                    width: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7B42).withValues(alpha: 0.12)
                          : context.subCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF7B42) : context.borderColor,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdayAbbr(day),
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFFF7B42) : context.subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasBooking)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E8443),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No activity for this date.',
                  style: TextStyle(color: context.subTextColor, fontSize: 13),
                ),
              ),
            )
          else
            ...activity.map((b) {
              final ground = widget.dashboard.grounds
                  .where((g) => g.id == b.groundId)
                  .firstOrNull;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E8443),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ground?.name ?? 'Ground',
                            style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Booked by ${b.userName ?? 'customer'}',
                            style: TextStyle(color: context.subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.subCardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        format12h(b.startTime),
                        style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _longDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _weekdayAbbr(DateTime d) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return weekdays[d.weekday - 1];
  }
}

class _DailyRevenue {
  final DateTime day;
  final double revenue;
  final int count;
  const _DailyRevenue({required this.day, required this.revenue, required this.count});
}

class _ChartMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ChartMetric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: context.subTextColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: context.subTextColor, fontSize: 11)),
      ],
    );
  }
}

class _RevenueBars extends StatelessWidget {
  final List<_DailyRevenue> days;
  const _RevenueBars({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = days.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);
    final todayKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    day.revenue >= 1000 ? '${(day.revenue / 1000).toStringAsFixed(1)}k' : '${day.revenue.toInt()}',
                    style: TextStyle(color: context.subTextColor, fontSize: 9),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: maxRevenue == 0 ? 3 : (day.revenue / maxRevenue) * 70,
                    decoration: BoxDecoration(
                      color: _dateKeyOf(day.day) == todayKey
                          ? const Color(0xFFFF7B42)
                          : const Color(0xFFFF7B42).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day.day}',
                    style: TextStyle(color: context.subTextColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _dateKeyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Calendar: pick a date to view that day's bookings for a selected ground.
class VendorCalendarTab extends StatefulWidget {
  final VendorDashboard dashboard;

  const VendorCalendarTab({super.key, required this.dashboard});

  @override
  State<VendorCalendarTab> createState() => _VendorCalendarTabState();
}

class _VendorCalendarTabState extends State<VendorCalendarTab> {
  late DateTime _selectedDate;
  late DateTime _month;
  String? _filterGroundId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    if (widget.dashboard.grounds.isNotEmpty) {
      _filterGroundId = widget.dashboard.grounds.first.id;
    }
  }

  VendorGround? get _ground {
    if (_filterGroundId == null) return null;
    for (final g in widget.dashboard.grounds) {
      if (g.id == _filterGroundId) return g;
    }
    return null;
  }

  List<VendorBooking> get _dayBookings {
    final ground = _ground;
    if (ground == null) return [];
    final key = _dateKey(_selectedDate);
    final list = ground.bookings.where((b) => b.date == key).toList()
      ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    return list;
  }

  bool _hasBookingOn(DateTime day) {
    final ground = _ground;
    if (ground == null) return false;
    final key = _dateKey(day);
    return ground.bookings.any((b) => b.date == key && b.isConfirmed);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _dayBookings;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Calendar',
          style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a date to view bookings',
          style: TextStyle(color: context.subTextColor, fontSize: 13),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 720;
          final calendar = _buildCalendar();
          final panel = _buildBookingsPanel(bookings);
          if (twoCol) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: calendar),
                const SizedBox(width: 20),
                Expanded(child: panel),
              ],
            );
          }
          return Column(
            children: [
              calendar,
              const SizedBox(height: 20),
              panel,
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              SizedBox(
                width: 220,
                child: GroundFilterDropdown(
                  grounds: widget.dashboard.grounds,
                  selectedId: _filterGroundId,
                  onChanged: (id) => setState(() => _filterGroundId = id),
                  allLabel: 'Select ground',
                ),
              ),
              if (_ground != null)
                Text(
                  '${_ground!.icon} ${_ground!.name}',
                  style: TextStyle(color: context.subTextColor, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: context.textColor),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
              ),
              Text(
                _monthLabel(_month),
                style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: context.textColor),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWeekdayHeader(),
          const SizedBox(height: 4),
          _buildMonthGrid(),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: const Color(0xFF2E8443), label: 'Booked'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFFF7B42), label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        for (final d in weekdays)
          Expanded(
            child: Center(
              child: Text(
                d[0],
                style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final mondayBased = (firstDay.weekday - 1) % 7; // Mon=0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    final cells = <Widget>[];
    for (int i = 0; i < mondayBased; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_month.year, _month.month, d);
      final isToday = _dateKey(day) == todayKey;
      final isSelected = _dateKey(day) == _dateKey(_selectedDate);
      final hasBooking = _hasBookingOn(day);

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = day),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF7B42)
                  : isToday
                      ? const Color(0xFFFF7B42).withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? const Color(0xFFFF7B42)
                            : context.textColor,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasBooking)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF2E8443),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: cells,
    );
  }

  Widget _buildBookingsPanel(List<VendorBooking> bookings) {
    final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings for ${weekdayNames[_selectedDate.weekday - 1]}, ${_monthLabel(_selectedDate)} ${_selectedDate.day}, ${_selectedDate.year}',
            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8443).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${bookings.length} slot${bookings.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Color(0xFF2E8443), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_outlined, size: 40, color: context.subTextColor),
                    const SizedBox(height: 10),
                    Text(
                      'No bookings on this date',
                      style: TextStyle(color: context.subTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...bookings.map((b) => bookingRow(context, booking: b)),
        ],
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime d) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.subTextColor, fontSize: 12)),
      ],
    );
  }
}

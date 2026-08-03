import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Booking history across all (or a selected) ground.
class VendorBookingsTab extends StatefulWidget {
  final VendorDashboard dashboard;

  const VendorBookingsTab({super.key, required this.dashboard});

  @override
  State<VendorBookingsTab> createState() => _VendorBookingsTabState();
}

class _VendorBookingsTabState extends State<VendorBookingsTab> {
  String? _filterGroundId;

  List<VendorBooking> get _bookings {
    final all = widget.dashboard.grounds
        .expand((g) => g.bookings.map((b) => (ground: g, booking: b)))
        .toList();
    final filtered = _filterGroundId == null
        ? all
        : all.where((e) => e.ground.id == _filterGroundId).toList();
    filtered.sort((a, b) => (b.booking.createdAt ?? '').compareTo(a.booking.createdAt ?? ''));
    return filtered.map((e) => e.booking).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _bookings;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Booking History',
          style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'View all past and upcoming bookings',
          style: TextStyle(color: context.subTextColor, fontSize: 13),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 260,
          child: GroundFilterDropdown(
            grounds: widget.dashboard.grounds,
            selectedId: _filterGroundId,
            onChanged: (id) => setState(() => _filterGroundId = id),
          ),
        ),
        const SizedBox(height: 20),
        if (bookings.isEmpty)
          VendorEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No bookings found',
            subtitle: _filterGroundId == null
                ? 'Bookings across all your grounds will appear here.'
                : 'No bookings for this ground yet.',
          )
        else
          ...bookings.map((b) {
            final ground = widget.dashboard.grounds
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
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';

/// Shared formatting + small widgets for the vendor dashboard screens.
/// Keeps the screens free of repeated formatting/date logic.

const List<String> kAllDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const Map<String, String> kDayFullNames = {
  'Mon': 'Monday', 'Tue': 'Tuesday', 'Wed': 'Wednesday',
  'Thu': 'Thursday', 'Fri': 'Friday', 'Sat': 'Saturday', 'Sun': 'Sunday',
};

String formatInr(num amount) {
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
      .format(amount);
}

String formatInrCompact(num amount) {
  final value = amount / 1000;
  return '₹${value.toStringAsFixed(1)}k';
}

/// "06:30" -> "6:30 AM".
String format12h(String? time) {
  if (time == null || time.isEmpty) return '—';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1].padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute $period';
}

/// "2026-09-04" -> "Sep 4".
String formatShortDate(String? date) {
  if (date == null || date.isEmpty) return '—';
  try {
    final dt = DateTime.parse(date);
    return DateFormat('MMM d').format(dt);
  } catch (_) {
    return date;
  }
}

/// "2026-09-04" -> "Sep 4, 2026".
String formatFullDate(String? date) {
  if (date == null || date.isEmpty) return '—';
  try {
    final dt = DateTime.parse(date);
    return DateFormat('MMM d, yyyy').format(dt);
  } catch (_) {
    return date;
  }
}

/// Booking status pill (green confirmed / amber pending / red otherwise).
Color bookingStatusColor(BuildContext context, String status) {
  if (status == 'confirmed') return const Color(0xFF2E8443);
  if (status == 'pending') return const Color(0xFFF59E0B);
  return const Color(0xFFE11D48);
}

Color groundStatusColor(BuildContext context, String status) {
  if (status == 'active') return const Color(0xFF2E8443);
  if (status == 'pending') return const Color(0xFFF59E0B);
  return context.subTextColor;
}

/// Pill chip used for booking/ground statuses.
Widget statusPill(BuildContext context, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

/// Generic stat card used across overview/revenue screens.
class VendorStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const VendorStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? const Color(0xFFFF7B42);
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: context.subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Empty state used across vendor tabs.
class VendorEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const VendorEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.subCardBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: context.subTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: context.subTextColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable section header with optional trailing widget.
class VendorSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const VendorSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ?trailing,
      ],
    );
  }
}

/// A ground selector dropdown (used by bookings/calendar/revenue filters).
class GroundFilterDropdown extends StatelessWidget {
  final List<VendorGround> grounds;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String allLabel;

  const GroundFilterDropdown({
    super.key,
    required this.grounds,
    required this.selectedId,
    required this.onChanged,
    this.allLabel = 'All Grounds',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: context.subTextColor),
          dropdownColor: context.cardBg,
          style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w500),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
            ...grounds.map((g) => DropdownMenuItem<String?>(
                  value: g.id,
                  child: Text('${g.icon} ${g.name}'),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Builds a booking row used in the bookings list / calendar / overview.
Widget bookingRow(
  BuildContext context, {
  required VendorBooking booking,
  String? groundName,
  String? groundIcon,
  Widget? trailing,
}) {
  final statusColor = bookingStatusColor(context, booking.status);
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.borderColor),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            (booking.userName?.isNotEmpty ?? false)
                ? booking.userName!.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.userName ?? 'Unknown customer',
                style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                [
                  ?groundName,
                  '${formatShortDate(booking.date)} · ${format12h(booking.startTime)} – ${format12h(booking.endTime)}',
                ].join(' · '),
                style: TextStyle(color: context.subTextColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatInr(booking.amount),
              style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            statusPill(context, booking.status, statusColor),
          ],
        ),
        ?trailing,
      ],
    ),
  );
}

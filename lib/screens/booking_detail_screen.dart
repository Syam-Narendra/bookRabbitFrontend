import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/touchable_opacity.dart';

// ─── Exact design system constants matching the reference ──────────────────
const _kOrange       = Color(0xFFE5500A);       // primary orange
const _kGreen        = Color(0xFF2AB04A);       // payment status green
const _kGrey         = Color(0xFF8A8A8E);       // sub-text grey
const _kBorder       = Color(0xFFE8E8E8);       // card border
const _kSoftOrange   = Color(0xFFFFF6F2);       // soft lightest orange card tint
const _kOrangeBorder = Color(0xFFFDE7DC);       // soft orange border
const _kGreenSoft    = Color(0xFFE8F8EE);       // confirmed status box bg
// ────────────────────────────────────────────────────────────────────────────

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onBackPressed;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardBg = context.cardBg;
    final textColor = context.textColor;
    final borderCol = isDark ? const Color(0xFF3A3A3C) : _kBorder;

    // Derived fields from booking data with robust fallbacks
    final title        = (booking['title'] as String?) ?? 'Sports Arena';
    final status       = (booking['status'] as String?) ?? 'Upcoming';
    final isUpcoming   = status == 'Upcoming';

    final address      = (booking['address'] as String?) ?? '';
    final city         = (booking['city'] as String?) ?? '';
    final location     = [if (address.isNotEmpty) address, if (city.isNotEmpty) city].join(', ');
    final finalLoc     = location.isNotEmpty ? location : 'Madhapur, Hyderabad';

    final sportType    = (booking['type'] as String?)?.isNotEmpty == true
        ? (booking['type'] as String)
        : 'Cricket';
    final distance     = (booking['distance'] as String?) ?? '2.3 km away';

    final bookedOn     = (booking['bookedOn'] as String?) ?? '25 Jul 2026, 10:30 AM';
    final refId        = (booking['referenceId'] as String?)?.isNotEmpty == true
        ? (booking['referenceId'] as String)
        : 'BR-31JUL6F7A2';

    final dateStr      = (booking['date'] as String?) ?? '31 Jul 2026, Friday';
    final timeStr      = (booking['time'] as String?) ?? '5:30 PM – 7:00 PM';
    final durH         = (booking['durationHours'] as num?)?.toDouble() ?? 1.5;
    final durLabel     = durH == durH.roundToDouble()
        ? '${durH.toInt()} hrs'
        : '${durH.toStringAsFixed(1)} hrs';

    final fare         = (booking['fare'] as num?)?.toDouble() ?? 750;
    final platformFee  = (booking['platformFee'] as num?)?.toDouble() ?? 49;
    final totalAmount  = (booking['totalAmount'] as num?)?.toDouble() ?? (fare + platformFee);

    final paymentMethod = (booking['paymentMethod'] as String?) ?? 'UPI – PhonePe';
    final txnId         = (booking['transactionId'] as String?) ?? 'T2407251030456789';

    // Image URL resolution
    final List<String> images = [];
    if (booking['images'] is List && (booking['images'] as List).isNotEmpty) {
      images.addAll((booking['images'] as List).map((e) => e.toString()));
    } else if (booking['imageUrl'] != null && booking['imageUrl'].toString().isNotEmpty) {
      images.add(booking['imageUrl'].toString());
    }
    final imageUrl = images.isNotEmpty ? images.first : '';

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final hPad = isWide ? 24.0 : 16.0;

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    // ── 1. Top Header ─────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
                      child: Row(
                        children: [
                          _circleBtn(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () {
                              if (onBackPressed != null) {
                                onBackPressed!();
                              } else {
                                Navigator.maybePop(context);
                              }
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Booking Details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 38), // Empty spacer to keep title perfectly centered
                        ],
                      ),
                    ).animate().fade(duration: 250.ms),

                    // ── 2. Scrollable Body Content ────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top Card: Venue info + Quick meta ─────────────
                            _buildVenueCard(
                              context: context,
                              title: title,
                              status: status,
                              isUpcoming: isUpcoming,
                              location: finalLoc,
                              distance: distance,
                              sportType: sportType,
                              imageUrl: imageUrl,
                              bookedOn: bookedOn,
                              refId: refId,
                              cardBg: cardBg,
                              borderCol: borderCol,
                              isDark: isDark,
                            ).animate().fade(duration: 300.ms).slideY(begin: 0.04),

                            const SizedBox(height: 18),

                            // ── Booking Details Card ──────────────────────────
                            _sectionHeader('Booking Details'),
                            const SizedBox(height: 8),
                            _buildBookingDetailsCard(
                              context: context,
                              dateStr: dateStr,
                              timeStr: timeStr,
                              durLabel: durLabel,
                              refId: refId,
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textColor: textColor,
                            ).animate().fade(delay: 60.ms, duration: 300.ms).slideY(begin: 0.04),

                            const SizedBox(height: 18),

                            // ── Fare Details Card ─────────────────────────────
                            _sectionHeader('Fare Details'),
                            const SizedBox(height: 8),
                            _buildFareDetailsCard(
                              context: context,
                              fare: fare,
                              platformFee: platformFee,
                              totalAmount: totalAmount,
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textColor: textColor,
                            ).animate().fade(delay: 120.ms, duration: 300.ms).slideY(begin: 0.04),

                            const SizedBox(height: 18),

                            // ── Payment Details Card ──────────────────────────
                            _sectionHeader('Payment Details'),
                            const SizedBox(height: 8),
                            _buildPaymentDetailsCard(
                              context: context,
                              paymentMethod: paymentMethod,
                              txnId: txnId,
                              refId: refId,
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textColor: textColor,
                              isDark: isDark,
                            ).animate().fade(delay: 180.ms, duration: 300.ms).slideY(begin: 0.04),

                            const SizedBox(height: 20),

                            // ── Bottom Action Buttons ─────────────────────────
                            Row(
                              children: [
                                // Share Booking
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _shareBooking(title, dateStr, timeStr, totalAmount),
                                      icon: const Icon(Icons.ios_share_rounded, size: 16),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('Share Booking'),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _kOrange,
                                        side: const BorderSide(color: _kOrange, width: 1.3),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Download Invoice
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _downloadInvoice(context, refId),
                                      icon: const Icon(Icons.file_download_outlined, size: 18),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('Download Invoice'),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _kOrange,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fade(delay: 240.ms, duration: 300.ms),

                            const SizedBox(height: 14),

                            // ── Support Banner ────────────────────────────────
                            _buildSupportBanner(context, isDark)
                                .animate()
                                .fade(delay: 280.ms, duration: 300.ms),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  // ─── CIRCLE HEADER BUTTON ──────────────────────────────────────────────────
  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return TouchableOpacity(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kOrange.withValues(alpha: 0.1),
        ),
        child: Icon(icon, color: _kOrange, size: 16),
      ),
    );
  }

  // ─── TOP VENUE CARD ────────────────────────────────────────────────────────
  Widget _buildVenueCard({
    required BuildContext context,
    required String title,
    required String status,
    required bool isUpcoming,
    required String location,
    required String distance,
    required String sportType,
    required String imageUrl,
    required String bookedOn,
    required String refId,
    required Color cardBg,
    required Color borderCol,
    required bool isDark,
  }) {
    final statusTxt = isUpcoming ? _kOrange : _kGreen;
    final statusBg  = isUpcoming ? const Color(0xFFFFF0E8) : const Color(0xFFE8F8EE);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Venue Thumbnail Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildVenueImage(imageUrl, sportType, size: 104),
              ),
              const SizedBox(width: 12),

              // Title & Meta Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUpcoming ? 'Upcoming' : 'Completed',
                        style: TextStyle(
                          color: statusTxt,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    _metaRow(Icons.location_on_rounded, location),
                    const SizedBox(height: 4),

                    // Distance
                    _metaRow(Icons.navigation_rounded, distance),
                    const SizedBox(height: 4),

                    // Sport Type
                    _metaRow(Icons.sports_baseball_rounded, sportType),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Bottom Dual Soft Orange Boxes ──────────────────────────────────
          Row(
            children: [
              // Left: Booked On Box
              Expanded(
                child: _softMetaBox(
                  context: context,
                  isDark: isDark,
                  icon: Icons.calendar_today_rounded,
                  label: 'Booked on',
                  value: bookedOn,
                ),
              ),
              const SizedBox(width: 10),

              // Right: Booking ID Box with Copy Action
              Expanded(
                child: _softMetaBox(
                  context: context,
                  isDark: isDark,
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booking ID',
                  value: refId,
                  onCopy: () => _copyToClipboard(context, refId, 'Booking ID copied!'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _kOrange, size: 13),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _kGrey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _softMetaBox({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    final boxBg = isDark ? const Color(0xFF2C2C2E) : _kSoftOrange;
    final boxBorder = isDark ? const Color(0xFF3A3A3C) : _kOrangeBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: boxBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kOrange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _kGrey, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            TouchableOpacity(
              onTap: onCopy,
              child: const Icon(Icons.copy_rounded, color: _kOrange, size: 15),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BOOKING DETAILS CARD ──────────────────────────────────────────────────
  Widget _buildBookingDetailsCard({
    required BuildContext context,
    required String dateStr,
    required String timeStr,
    required String durLabel,
    required String refId,
    required Color cardBg,
    required Color borderCol,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          _rowItem(context, Icons.calendar_today_rounded, 'Date', dateStr, borderCol),
          _rowItem(context, Icons.access_time_rounded, 'Time', timeStr, borderCol),
          _rowItem(context, Icons.timelapse_rounded, 'Duration', durLabel, borderCol),
        ],
      ),
    );
  }

  // ─── FARE DETAILS CARD ─────────────────────────────────────────────────────
  Widget _buildFareDetailsCard({
    required BuildContext context,
    required double fare,
    required double platformFee,
    required double totalAmount,
    required Color cardBg,
    required Color borderCol,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          _fareRow(context, 'Ground Fare', '₹${fare.round()}'),
          const SizedBox(height: 8),
          _fareRow(context, 'Platform Fee', '₹${platformFee.round()}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: borderCol),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '₹${totalAmount.round()}',
                style: const TextStyle(color: _kOrange, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PAYMENT DETAILS CARD ──────────────────────────────────────────────────
  Widget _buildPaymentDetailsCard({
    required BuildContext context,
    required String paymentMethod,
    required String txnId,
    required String refId,
    required Color cardBg,
    required Color borderCol,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          // Row 1: Payment Method
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.payment_rounded, color: _kOrange, size: 16),
                const SizedBox(width: 10),
                const Text('Payment Method', style: TextStyle(color: _kGrey, fontSize: 13)),
                const Spacer(),
                Text(paymentMethod, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                // PhonePe style icon pill
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5F259E), // PhonePe purple
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'पे',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderCol),

          // Row 2: Transaction ID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: _kOrange, size: 16),
                const SizedBox(width: 10),
                const Text('Transaction ID', style: TextStyle(color: _kGrey, fontSize: 13)),
                const Spacer(),
                Flexible(
                  child: Text(
                    txnId,
                    style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                TouchableOpacity(
                  onTap: () => _copyToClipboard(context, txnId, 'Transaction ID copied!'),
                  child: const Icon(Icons.copy_rounded, color: _kOrange, size: 15),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderCol),

          // Row 3: Payment Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: _kOrange, size: 16),
                const SizedBox(width: 10),
                const Text('Payment Status', style: TextStyle(color: _kGrey, fontSize: 13)),
                const Spacer(),
                const Text(
                  'Paid Successfully',
                  style: TextStyle(color: _kGreen, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Confirmed Banner inside Payment Details
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 2, 10, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3326) : _kGreenSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Your booking is confirmed.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Show this booking ID at the venue.',
                        style: TextStyle(color: _kGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // QR code representation
                Icon(Icons.qr_code_2_rounded, color: textColor, size: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  Widget _rowItem(BuildContext context, IconData icon, String label, String value, Color? borderCol) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: _kOrange, size: 16),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: _kGrey, fontSize: 13)),
              const Spacer(),
              Text(value, style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (borderCol != null) Divider(height: 1, thickness: 1, color: borderCol),
      ],
    );
  }

  Widget _fareRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _kGrey, fontSize: 13)),
        Text(value, style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── SUPPORT BANNER ────────────────────────────────────────────────────────
  Widget _buildSupportBanner(BuildContext context, bool isDark) {
    final bg = isDark ? const Color(0xFF2C2C2E) : _kSoftOrange;
    final border = isDark ? const Color(0xFF3A3A3C) : _kOrangeBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded, color: _kOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    color: _kOrange,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Contact our support team for assistance.',
                  style: TextStyle(
                    color: context.subTextColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TouchableOpacity(
            onTap: () => _callSupport(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.phone_rounded, color: _kOrange, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UTILS & ACTIONS ───────────────────────────────────────────────────────
  Widget _buildVenueImage(String url, String sportType, {required double size}) {
    final fallback = _fallbackAsset(sportType);
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: size, height: size, fit: BoxFit.cover);
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Image.asset(fallback, width: size, height: size, fit: BoxFit.cover);
  }

  String _fallbackAsset(String type) {
    final t = type.toLowerCase();
    if (t.contains('cricket')) return 'assets/images/cricket-rabbit.png';
    if (t.contains('football') || t.contains('soccer')) return 'assets/images/football-rabbit.png';
    if (t.contains('tennis') || t.contains('badminton') || t.contains('pickleball')) return 'assets/images/tennis-rabbit.png';
    return 'assets/images/sports_bunnies.png';
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: _kOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareBooking(String title, String dateStr, String timeStr, double total) {
    final text = '🏟️ $title\n📅 $dateStr\n⏰ $timeStr\n💰 Total: ₹${total.round()}\n\nBooked with Book Rabbit! 🐰';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _downloadInvoice(BuildContext context, String refId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading invoice for $refId...'),
        duration: const Duration(seconds: 2),
        backgroundColor: _kOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _callSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to Book Rabbit Customer Support...'),
        duration: Duration(seconds: 2),
        backgroundColor: _kOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, color: _kOrange),
              title: const Text('Share Booking Details'),
              onTap: () {
                Navigator.pop(context);
                _shareBooking(
                  booking['title']?.toString() ?? 'Ground',
                  booking['date']?.toString() ?? '',
                  booking['time']?.toString() ?? '',
                  (booking['totalAmount'] as num?)?.toDouble() ?? 0,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined, color: _kOrange),
              title: const Text('Download Receipt'),
              onTap: () {
                Navigator.pop(context);
                _downloadInvoice(context, booking['referenceId']?.toString() ?? '');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: _kOrange),
              title: const Text('Need Help with this Booking'),
              onTap: () {
                Navigator.pop(context);
                _callSupport(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

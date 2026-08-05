import 'package:flutter/material.dart';
import '../router/route_extensions.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/touchable_opacity.dart';
import '../theme/app_theme.dart';

import 'booking_detail_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String? referenceId;
  final Map<String, dynamic> ground;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int finalPrice;
  final int? platformFee;

  const BookingSuccessScreen({
    super.key,
    required this.referenceId,
    required this.ground,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.finalPrice,
    this.platformFee,
  });

  String _calculateDuration(String start, String end) {
    try {
      final format = DateFormat('hh:mm a');
      final d1 = format.parse(start);
      final d2 = format.parse(end);
      var mins = d2.difference(d1).inMinutes;
      if (mins <= 0) mins += 24 * 60; // Overnight slot (e.g. 11 PM → 1 AM)
      if (mins % 60 == 0) return '${mins ~/ 60} Hours';
      return '${(mins / 60).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} Hours';
    } catch (e) {
      return '';
    }
  }

  Widget _groundImage(double size) {
    const fallback = 'assets/images/sports_bunnies.png';
    final url = ground['imageUrl']?.toString() ?? '';
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: size, height: size, fit: BoxFit.cover);
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Image.asset(fallback, width: size, height: size, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final heroGradientColors = context.isDark
        ? [const Color(0xFF2C1C16), const Color(0xFF1E1410)]
        : [const Color(0xFFFFF7F2), const Color(0xFFFFEAE0)];

    return Scaffold(
      backgroundColor: context.bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          if (isWide) {
            final rabbitHeight = (constraints.maxHeight * 0.60).clamp(320.0, 640.0);
            return Row(
              children: [
                // Left Panel — Soft Warm Cream & Peach hero banner with Mascot & Checkmark
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: heroGradientColors,
                      ),
                    ),
                    child: SafeArea(
                      child: Stack(
                        children: [
                          // Dynamic Rabbit image starting EXACTLY at bottom edge
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/images/rabbit-confirm-full.png',
                              height: rabbitHeight,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/images/rabbit-confirm.png',
                                height: rabbitHeight,
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomCenter,
                              ),
                            ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
                          ),
                          // Text and checkmark badge on top
                          Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    context.goHome();
                                  },
                                  child: Icon(Icons.arrow_back, color: context.isDark ? Colors.white : const Color(0xFF1C1C1E), size: 28),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: context.cardBg,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF5200).withValues(alpha: 0.15),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.check, color: Color(0xFFFF5200), size: 54),
                                      ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Booking Confirmed!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: context.isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 36, fontWeight: FontWeight.bold, height: 1.2),
                                      ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Your booking has been confirmed successfully.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: context.subTextColor, fontSize: 16, height: 1.4),
                                      ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Panel — Receipt card details
                Expanded(
                  flex: 6,
                  child: Container(
                    color: context.bgColor,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _buildReceiptDetails(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile view: original Stack layout with Soft Warm Cream & Peach header
          return Stack(
            children: [
              Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: heroGradientColors,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.goHome();
                            },
                            child: Icon(Icons.arrow_back, color: context.isDark ? Colors.white : const Color(0xFF1C1C1E)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Image.asset(
                            'assets/images/rabbit-confirm.png',
                            width: 170,
                            height: 230,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                          ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.cardBg,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF5200).withValues(alpha: 0.15),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.check, color: Color(0xFFFF5200), size: 44),
                                  ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Booking\nConfirmed!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: context.isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your booking has been\nconfirmed successfully.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: context.subTextColor, fontSize: 13, height: 1.3),
                                  ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        decoration: BoxDecoration(
                          color: context.bgColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: _buildReceiptDetails(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReceiptDetails(BuildContext context) {
    return Column(
      children: [
        // Booking ID
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5200).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today_outlined, color: Color(0xFFFF5200), size: 20),
        ),
        const SizedBox(height: 8),
        Text('BOOKING ID', style: TextStyle(color: context.subTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          referenceId ?? 'BRB-PENDING',
          style: const TextStyle(color: Color(0xFFFF5200), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        // Dashed Divider
        LayoutBuilder(
          builder: (context, constraints) {
            final dashWidth = 5.0;
            final dashHeight = 1.0;
            final dashCount = (constraints.maxWidth / (2 * dashWidth)).floor();
            return Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(dashCount, (_) {
                return SizedBox(
                  width: dashWidth,
                  height: dashHeight,
                  child: DecoratedBox(decoration: BoxDecoration(color: context.borderColor)),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 24),
        // Ground Details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _groundImage(72),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ground['title'] ?? '', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFFFF5200), size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(ground['location'] ?? '', style: TextStyle(color: context.subTextColor, fontSize: 13))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Date & Time Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.subCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFFFF5200), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DATE', style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(DateFormat('EEEE').format(date), style: TextStyle(color: context.subTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFFFF5200), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TIME', style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$startTime – $endTime', style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 2),
                          const SizedBox(height: 2),
                          Text(_calculateDuration(startTime, endTime), style: TextStyle(color: context.subTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Payment Status Box
        GestureDetector(
          onTap: () {
            final fee = platformFee;
            final bookingMap = {
              'status': 'Upcoming',
              'images': [if (ground['imageUrl']?.toString().isNotEmpty == true) ground['imageUrl'].toString()],
              'title': ground['title'] ?? '',
              'type': 'Sports',
              'address': ground['location'] ?? '',
              'date': DateFormat('dd MMM yyyy').format(date),
              'time': '$startTime – $endTime',
              'referenceId': referenceId,
              'fare': fee == null ? null : finalPrice - fee,
              'platformFee': fee,
              'totalAmount': finalPrice,
            };
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(booking: bookingMap),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5200).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFFF5200), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Status', style: TextStyle(color: context.subTextColor, fontSize: 12)),
                      const Text('Paid Successfully', style: TextStyle(color: Color(0xFF00A859), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text('₹$finalPrice', style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: context.subTextColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // WhatsApp Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.subCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/whatsapp.png', width: 24, height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF5200), size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A confirmation has been sent to your WhatsApp with booking details.',
                  style: TextStyle(color: context.textColor, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Buttons
        TouchableOpacity(
          onTap: () {
            context.goHistory();
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('View My Bookings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TouchableOpacity(
          onTap: () {
            final String details = 'Booking Confirmed!\n\n'
                'Ground: ${ground['title'] ?? 'N/A'}\n'
                'Location: ${ground['location'] ?? 'N/A'}\n'
                'Date: ${DateFormat('dd MMM yyyy').format(date)}\n'
                'Time: $startTime – $endTime\n'
                'Booking ID: ${referenceId ?? 'BRB-PENDING'}\n'
                'Amount Paid: ₹$finalPrice';
            SharePlus.instance.share(ShareParams(text: details, subject: 'My Booking Details'));
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF5200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.share_outlined, color: Color(0xFFFF5200), size: 20),
                SizedBox(width: 8),
                Text('Share Booking Details', style: TextStyle(color: Color(0xFFFF5200), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Support text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFFFF5200), size: 16),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () async {
                final Uri supportUri = Uri.parse('https://bookrabbit.in/support');
                if (await canLaunchUrl(supportUri)) {
                  await launchUrl(supportUri);
                }
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: context.subTextColor, fontSize: 13),
                  children: const [
                    TextSpan(text: 'Need help? '),
                    TextSpan(text: 'Contact support', style: TextStyle(color: Color(0xFFFF5200), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fade(delay: 500.ms).slideY(begin: 0.1);
  }
}


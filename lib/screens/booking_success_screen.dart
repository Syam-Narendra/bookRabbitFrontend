import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/touchable_opacity.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String? referenceId;
  final Map<String, dynamic> ground;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int finalPrice;

  const BookingSuccessScreen({
    super.key,
    required this.referenceId,
    required this.ground,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.finalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE54F3F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFFE54F3F), size: 64),
              ).animate().fade(duration: 500.ms).scale(curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 8),
              if (referenceId != null)
                Text(
                  'Reference ID: $referenceId',
                  style: const TextStyle(color: Color(0xFF98989E), fontSize: 15, fontWeight: FontWeight.w600),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1)
              else
                const Text(
                  'Your payment was successful. Your booking will appear shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF98989E), fontSize: 14),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38383A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ground['title']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ground['location']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFF98989E), fontSize: 14),
                    ),
                    const Divider(color: Color(0xFF38383A), height: 24),
                    _buildIconDetail(Icons.calendar_today, DateFormat('EEEE, MMM d, yyyy').format(date)),
                    const SizedBox(height: 12),
                    _buildIconDetail(Icons.access_time, '$startTime - $endTime'),
                    const SizedBox(height: 12),
                    _buildIconDetail(Icons.payments, 'Paid ₹$finalPrice'),
                  ],
                ),
              ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
              const Spacer(),
              TouchableOpacity(
                onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE54F3F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Done', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE54F3F), size: 18),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

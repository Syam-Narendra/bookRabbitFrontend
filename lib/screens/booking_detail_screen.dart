import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({super.key, required this.booking});

  Color _statusColor() {
    switch (booking['status']) {
      case 'Upcoming':
        return const Color(0xFFE6883C);
      case 'Completed':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFFE54F3F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (booking['images'] as List<dynamic>? ?? []).cast<String>();
    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: const Color(0xFF161616),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Image.asset('assets/images/sports_bunnies.png', fit: BoxFit.cover)
                  : CarouselSlider(
                      options: CarouselOptions(
                        height: 220.0,
                        viewportFraction: 1.0,
                        autoPlay: images.length > 1,
                        autoPlayInterval: const Duration(seconds: 4),
                      ),
                      items: images.map((url) => Image.network(url, fit: BoxFit.cover, width: double.infinity)).toList(),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          booking['title']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking['status']?.toString() ?? '',
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 300.ms).slideY(begin: 0.1),
                  const SizedBox(height: 4),
                  Text(
                    booking['type']?.toString() ?? '',
                    style: const TextStyle(color: Color(0xFF98989E), fontSize: 14),
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  if ((booking['address'] as String?)?.isNotEmpty == true)
                    _buildDetailRow(Icons.location_on, booking['address'].toString()).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2C2C2E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BOOKING DETAILS', style: TextStyle(color: Color(0xFF98989E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.calendar_today, booking['date']?.toString() ?? ''),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.schedule, booking['time']?.toString() ?? ''),
                        if ((booking['referenceId'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow(Icons.confirmation_number_outlined, booking['referenceId'].toString()),
                        ],
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2C2C2E)),
                    ),
                    child: Column(
                      children: [
                        _buildPaymentRow('Ground Fare', booking['fare']),
                        const SizedBox(height: 12),
                        _buildPaymentRow('Platform Fee', booking['platformFee']),
                        const Divider(color: Color(0xFF2C2C2E), height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              '₹${(booking['totalAmount'] as num?)?.round() ?? 0}',
                              style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFE54F3F), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, dynamic amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text('₹${(amount as num?)?.round() ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

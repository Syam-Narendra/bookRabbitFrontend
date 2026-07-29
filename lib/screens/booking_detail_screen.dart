import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onBackPressed;

  const BookingDetailScreen({super.key, required this.booking, this.onBackPressed});

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

  Widget _buildImageCarousel(List<String> images, {required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: images.isEmpty
            ? Image.asset('assets/images/sports_bunnies.png', fit: BoxFit.cover, width: double.infinity)
            : CarouselSlider(
                options: CarouselOptions(
                  height: height,
                  viewportFraction: 1.0,
                  autoPlay: images.length > 1,
                  autoPlayInterval: const Duration(seconds: 4),
                ),
                items: images.map((url) {
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/sports_bunnies.png', fit: BoxFit.cover, width: double.infinity),
                  );
                }).toList(),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = [];
    if (booking['images'] is List && (booking['images'] as List).isNotEmpty) {
      images.addAll((booking['images'] as List).map((e) => e.toString()));
    } else if (booking['imageUrl'] != null && booking['imageUrl'].toString().isNotEmpty) {
      images.add(booking['imageUrl'].toString());
    }

    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            if (isWide) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 680),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.borderColor),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new, color: context.textColor, size: 20),
                              onPressed: () {
                                if (onBackPressed != null) {
                                  onBackPressed!();
                                } else {
                                  Navigator.maybePop(context);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking['title']?.toString() ?? '',
                                style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                booking['status']?.toString() ?? '',
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildImageCarousel(images, height: 240.0),
                        const SizedBox(height: 20),
                        Text(
                          booking['type']?.toString() ?? '',
                          style: TextStyle(color: context.subTextColor, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        if ((booking['address'] as String?)?.isNotEmpty == true)
                          _buildDetailRow(context, Icons.location_on, booking['address'].toString()),
                        const SizedBox(height: 20),
                        // Booking Details
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.subCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BOOKING DETAILS', style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 12),
                              _buildDetailRow(context, Icons.calendar_today, booking['date']?.toString() ?? ''),
                              const SizedBox(height: 10),
                              _buildDetailRow(context, Icons.schedule, booking['time']?.toString() ?? ''),
                              if ((booking['referenceId'] as String?)?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                _buildDetailRow(context, Icons.confirmation_number_outlined, booking['referenceId'].toString()),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Payment Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.subCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentRow(context, 'Ground Fare', booking['fare']),
                              const SizedBox(height: 12),
                              _buildPaymentRow(context, 'Platform Fee', booking['platformFee']),
                              Divider(color: context.borderColor, height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Amount', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(
                                    '₹${(booking['totalAmount'] as num?)?.round() ?? 0}',
                                    style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Mobile view layout
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220.0,
                  pinned: true,
                  backgroundColor: context.bgColor,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () {
                          if (onBackPressed != null) {
                            onBackPressed!();
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildImageCarousel(images, height: 220.0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                                style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
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
                        ).animate().fade(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 4),
                        Text(
                          booking['type']?.toString() ?? '',
                          style: TextStyle(color: context.subTextColor, fontSize: 14),
                        ).animate().fade(delay: 100.ms, duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 16),
                        if ((booking['address'] as String?)?.isNotEmpty == true)
                          _buildDetailRow(context, Icons.location_on, booking['address'].toString()).animate().fade(delay: 150.ms, duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BOOKING DETAILS', style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 12),
                              _buildDetailRow(context, Icons.calendar_today, booking['date']?.toString() ?? ''),
                              const SizedBox(height: 10),
                              _buildDetailRow(context, Icons.schedule, booking['time']?.toString() ?? ''),
                              if ((booking['referenceId'] as String?)?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                _buildDetailRow(context, Icons.confirmation_number_outlined, booking['referenceId'].toString()),
                              ],
                            ],
                          ),
                        ).animate().fade(delay: 200.ms, duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentRow(context, 'Ground Fare', booking['fare']),
                              const SizedBox(height: 12),
                              _buildPaymentRow(context, 'Platform Fee', booking['platformFee']),
                              Divider(color: context.borderColor, height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Amount', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(
                                    '₹${(booking['totalAmount'] as num?)?.round() ?? 0}',
                                    style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFE54F3F), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(BuildContext context, String label, dynamic amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.subTextColor, fontSize: 14)),
        Text('₹${(amount as num?)?.round() ?? 0}', style: TextStyle(color: context.textColor, fontSize: 14)),
      ],
    );
  }
}


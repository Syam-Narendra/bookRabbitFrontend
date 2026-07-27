import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/booking_service.dart';
import '../booking_detail_screen.dart';
import '../../widgets/touchable_opacity.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _selectedHistoryTab = 'All';
  static final List<String> historyTabs = ['All', 'Upcoming', 'Completed', 'Cancelled'];

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final bookings = await BookingService.fetchMyBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mockBookings = _bookings;
    List<Map<String, dynamic>> displayedBookings = mockBookings;
    if (_selectedHistoryTab != 'All') {
      displayedBookings = mockBookings.where((b) => b['status'] == _selectedHistoryTab).toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final bottomPad = isWide ? 40.0 : 140.0;

        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 860),
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — always visible
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: const Text(
                    'History',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ).animate().fade(duration: 350.ms).slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
                ),

                // Filter tabs — always visible
                Row(
                  children: historyTabs.map((tab) {
                    final isSelected = tab == _selectedHistoryTab;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedHistoryTab = tab),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        margin: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? const Color(0xFFE54F3F) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF98989E),
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fade(delay: 100.ms, duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),

                // Content area — loading / error / list
                Expanded(
                  child: _isLoading
                    ? _buildSkeletonList()
                    : _hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, color: Color(0xFF52525B), size: 48),
                              const SizedBox(height: 16),
                              const Text('Failed to load bookings',
                                  style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchBookings,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE54F3F)),
                                child: const Text('Retry',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : displayedBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: Color(0xFF52525B), size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedHistoryTab == 'All'
                                      ? 'No bookings found.'
                                      : 'No ${_selectedHistoryTab.toLowerCase()} bookings found.',
                                  style: const TextStyle(
                                      color: Color(0xFF98989E),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.only(bottom: bottomPad),
                            children: _selectedHistoryTab == 'All'
                              ? [
                                  if (mockBookings.any((b) => b['status'] == 'Upcoming')) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Text('Upcoming bookings',
                                          style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontWeight: FontWeight.bold)),
                                    ).animate().fade(delay: 150.ms),
                                    ...mockBookings.where((b) => b['status'] == 'Upcoming').toList().asMap().entries.map((entry) => _buildBookingCard(entry.value, entry.key)),
                                  ],
                                  if (mockBookings.any((b) => b['status'] == 'Completed')) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Text('Completed bookings',
                                          style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontWeight: FontWeight.bold)),
                                    ).animate().fade(delay: 150.ms),
                                    ...mockBookings.where((b) => b['status'] == 'Completed').toList().asMap().entries.map((entry) => _buildBookingCard(entry.value, entry.key)),
                                  ],
                                  if (mockBookings.any((b) => b['status'] == 'Cancelled')) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Text('Cancelled bookings',
                                          style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontWeight: FontWeight.bold)),
                                    ).animate().fade(delay: 150.ms),
                                    ...mockBookings.where((b) => b['status'] == 'Cancelled').toList().asMap().entries.map((entry) => _buildBookingCard(entry.value, entry.key)),
                                  ],
                                ]
                              : displayedBookings.asMap().entries
                                  .map((entry) => _buildBookingCard(entry.value, entry.key))
                                  .toList(),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shimmer skeleton list shown while bookings are loading.
  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, i) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF2C2C2E),
          highlightColor: const Color(0xFF3A3A3C),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF222224),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // image placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 140, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 100, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(height: 22, width: 70, color: Colors.white),
                    const SizedBox(height: 16),
                    Container(height: 12, width: 50, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 20, width: 60, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, int index) {
    Color statusColor;
    Color statusBgColor;
    if (booking['status'] == 'Upcoming') {
      statusColor = const Color(0xFFE6883C); // Orange
      statusBgColor = const Color(0xFFE6883C).withValues(alpha: 0.15);
    } else if (booking['status'] == 'Completed') {
      statusColor = const Color(0xFF34C759); // Green
      statusBgColor = const Color(0xFF34C759).withValues(alpha: 0.15);
    } else {
      statusColor = const Color(0xFFE54F3F); // Red
      statusBgColor = const Color(0xFFE54F3F).withValues(alpha: 0.15);
    }

    return TouchableOpacity(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(booking: booking),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildGroundImage(booking),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  booking['type'],
                  style: const TextStyle(color: Color(0xFF98989E), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFF98989E), size: 12),
                    const SizedBox(width: 6),
                    Text(booking['date'], style: const TextStyle(color: Color(0xFF98989E), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Color(0xFF98989E), size: 12),
                    const SizedBox(width: 6),
                    Text(booking['time'], style: const TextStyle(color: Color(0xFF98989E), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Right Side: Status and Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking['status'],
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Total Amount', style: TextStyle(color: Color(0xFF98989E), fontSize: 10)),
              Row(
                children: [
                  Text(
                    booking['price'],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Color(0xFF98989E), size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    ).animate().fade(duration: 300.ms, delay: Duration(milliseconds: 100 + (index * 50))).slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic);
  }
  /// Returns a sport-appropriate bunny fallback asset path based on the ground type.
  String _fallbackAsset(String type) {
    final t = type.toLowerCase();
    if (t.contains('cricket')) return 'assets/images/cricket-rabbit.png';
    if (t.contains('football') || t.contains('soccer')) return 'assets/images/football-rabbit.png';
    if (t.contains('tennis') || t.contains('badminton') || t.contains('pickleball')) return 'assets/images/tennis-rabbit.png';
    return 'assets/images/sports_bunnies.png';
  }

  /// Displays the ground image: asset path → Image.asset,
  /// network URL → Image.network with error/loading builders.
  Widget _buildGroundImage(Map<String, dynamic> booking) {
    const double size = 80;
    final imageUrl = booking['imageUrl'] as String? ?? '';
    final type = booking['type'] as String? ?? '';
    final fallback = _fallbackAsset(type);

    // When the booking service put an asset path as the URL (no images from backend)
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, e, s) => Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
      );
    }

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Show a shimmer-style placeholder while loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE54F3F)),
            ),
          ),
        );
      },
      // Fall back to the bunny on any network/decode error
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(fallback, width: size, height: size, fit: BoxFit.cover);
      },
    );
  }
}

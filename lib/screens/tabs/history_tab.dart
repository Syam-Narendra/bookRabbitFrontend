import 'package:flutter/material.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _selectedHistoryTab = 'All';
  
  static final List<String> historyTabs = ['All', 'Upcoming', 'Completed', 'Cancelled'];
  
  static final List<Map<String, dynamic>> mockBookings = [
    {
      'title': 'Green Turf Arena',
      'type': 'Football Turf',
      'date': '24 May 2025, Sat',
      'time': '06:00 PM – 07:00 PM',
      'price': '₹600',
      'status': 'Upcoming',
      'imageUrl': 'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?q=80&w=1974&auto=format&fit=crop'
    },
    {
      'title': 'Smash Badminton Club',
      'type': 'Badminton Court',
      'date': '26 May 2025, Mon',
      'time': '08:00 AM – 09:00 AM',
      'price': '₹450',
      'status': 'Upcoming',
      'imageUrl': 'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?q=80&w=1974&auto=format&fit=crop',
    },
    {
      'title': 'PowerPlay Box Cricket',
      'type': 'Box Cricket',
      'date': '18 May 2025, Sun',
      'time': '07:00 PM – 08:30 PM',
      'price': '₹900',
      'status': 'Completed',
      'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop',
    },
    {
      'title': 'Kickoff Turf',
      'type': 'Football Turf',
      'date': '12 May 2025, Mon',
      'time': '06:00 PM – 07:00 PM',
      'price': '₹600',
      'status': 'Completed',
      'imageUrl': 'https://images.unsplash.com/photo-1624314138470-5a2f24623f10?q=80&w=1974&auto=format&fit=crop',
    },
    {
      'title': 'Hoop Central',
      'type': 'Basketball Court',
      'date': '10 May 2025, Sat',
      'time': '06:00 PM – 07:00 PM',
      'price': '₹500',
      'status': 'Cancelled',
      'imageUrl': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2067&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedBookings = mockBookings;
    if (_selectedHistoryTab != 'All') {
      displayedBookings = mockBookings.where((b) => b['status'] == _selectedHistoryTab).toList();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'History',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              
            ],
          ),
        ),
        
        // Custom Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: historyTabs.map((tab) {
              final isSelected = tab == _selectedHistoryTab;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedHistoryTab = tab;
                  });
                },
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
          ),
        ),
        const SizedBox(height: 16),
        
        // Content List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
            children: _selectedHistoryTab == 'All' 
              ? [
                  if (mockBookings.any((b) => b['status'] == 'Upcoming')) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Upcoming bookings', style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ...mockBookings.where((b) => b['status'] == 'Upcoming').map((b) => _buildBookingCard(b)),
                  ],
                  if (mockBookings.any((b) => b['status'] == 'Completed')) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Completed bookings', style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ...mockBookings.where((b) => b['status'] == 'Completed').map((b) => _buildBookingCard(b)),
                  ],
                  if (mockBookings.any((b) => b['status'] == 'Cancelled')) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Cancelled bookings', style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ...mockBookings.where((b) => b['status'] == 'Cancelled').map((b) => _buildBookingCard(b)),
                  ],
                ]
              : displayedBookings.map((b) => _buildBookingCard(b)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    Color statusColor;
    Color statusBgColor;
    if (booking['status'] == 'Upcoming') {
      statusColor = const Color(0xFFE6883C); // Orange
      statusBgColor = const Color(0xFFE6883C).withOpacity(0.15);
    } else if (booking['status'] == 'Completed') {
      statusColor = const Color(0xFF34C759); // Green
      statusBgColor = const Color(0xFF34C759).withOpacity(0.15);
    } else {
      statusColor = const Color(0xFFE54F3F); // Red
      statusBgColor = const Color(0xFFE54F3F).withOpacity(0.15);
    }

    return Container(
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
            child: Image.network(
              booking['imageUrl'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
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
    );
  }
}

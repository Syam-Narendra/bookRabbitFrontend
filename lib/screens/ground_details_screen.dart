import 'dart:ui';
import 'package:flutter/material.dart';

class GroundDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ground;

  const GroundDetailsScreen({super.key, required this.ground});

  @override
  State<GroundDetailsScreen> createState() => _GroundDetailsScreenState();
}

class _GroundDetailsScreenState extends State<GroundDetailsScreen> {
  final List<String> _timeSlots = [];
  String? _selectedStartTime;
  int _durationMins = 60;
  int _basePrice = 0;

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    _parsePrice();
  }

  void _parsePrice() {
    // Expected format: "₹600/hr"
    final priceStr = widget.ground['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (priceStr.isNotEmpty) {
      _basePrice = int.parse(priceStr);
    }
  }

  void _generateTimeSlots() {
    // Generate slots from 10:00 AM to 8:00 PM in 30 min intervals
    int startHour = 10;
    int endHour = 20;

    for (int h = startHour; h <= endHour; h++) {
      for (int m = 0; m < 60; m += 30) {
        if (h == endHour && m > 0) break; // End exactly at 8:00 PM
        
        String ampm = h >= 12 ? 'PM' : 'AM';
        int displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        String minStr = m == 0 ? '00' : '30';
        
        _timeSlots.add('$displayHour:$minStr $ampm');
      }
    }
  }

  int get _totalPrice {
    if (_selectedStartTime == null) return 0;
    double slotPrice = _basePrice / 2;
    int slots = _durationMins ~/ 30;
    return (slotPrice * slots).round();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          width: isDesktop ? 450 : double.infinity,
          height: double.infinity,
          color: const Color(0xFF161616),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleAndDetails(),
                            const SizedBox(height: 32),
                            _buildTimeSlotsSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280.0,
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: 3, // Simulate carousel
              itemBuilder: (context, index) {
                return Image.network(
                  widget.ground['imageUrl'],
                  fit: BoxFit.cover,
                );
              },
            ),
            // Gradient overlay for readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF161616),
                      const Color(0xFF161616).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.ground['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE54F3F).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.ground['price'],
                style: const TextStyle(
                  color: Color(0xFFE54F3F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF98989E), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.ground['location']} • ${widget.ground['type']}',
                style: const TextStyle(color: Color(0xFF98989E), fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.ground['category'],
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Open 10:00 AM - 08:00 PM',
              style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _showDurationBottomSheet(String slot) {
    int localDuration = 60; // Default

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start Time: $slot',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How much time to play?',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: localDuration <= 30
                              ? null
                              : () {
                                  setModalState(() {
                                    localDuration -= 30;
                                  });
                                },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFFE54F3F),
                          disabledColor: Colors.white24,
                          iconSize: 32,
                        ),
                        Column(
                          children: [
                            Text(
                              '$localDuration',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'mins',
                              style: TextStyle(color: Color(0xFF98989E), fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            setModalState(() {
                              localDuration += 30;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFFE54F3F),
                          iconSize: 32,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStartTime = slot;
                          _durationMins = localDuration;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE54F3F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Duration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Start Time',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedStartTime != null)
              Text(
                '$_durationMins mins',
                style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 14, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _timeSlots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedStartTime == slot;

            return GestureDetector(
              onTap: () {
                _showDurationBottomSheet(slot);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE54F3F) : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  slot,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF98989E),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF161616).withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$_totalPrice',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedStartTime == null
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking Confirmed!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE54F3F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF2C2C2E),
                        disabledForegroundColor: Colors.white38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

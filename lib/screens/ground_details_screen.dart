import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'review_booking_screen.dart';
import '../services/ground_service.dart';

class GroundDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ground;

  const GroundDetailsScreen({super.key, required this.ground});

  @override
  State<GroundDetailsScreen> createState() => _GroundDetailsScreenState();
}

class _GroundDetailsScreenState extends State<GroundDetailsScreen> {
  final List<String> _timeSlots = [];
  final List<String> _timeSlots24 = [];
  String? _selectedStartTime;
  DateTime? _selectedDate;
  int _durationMins = 60;
  int _basePrice = 0;

  Set<String> _bookedSegs = {};
  Set<String> _heldSegs = {};
  bool _isLoadingAvailability = false;
  Timer? _heldPollTimer;

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    _parsePrice();
  }

  @override
  void dispose() {
    _heldPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAvailability() async {
    if (_selectedDate == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    setState(() => _isLoadingAvailability = true);
    try {
      final availability = await GroundService.fetchSlotAvailability(
        groundId: widget.ground['id'] as String,
        date: dateStr,
      );
      if (!mounted) return;
      setState(() {
        _bookedSegs = availability['bookedSegs'] ?? {};
        _heldSegs = availability['heldSegs'] ?? {};
        _isLoadingAvailability = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAvailability = false);
    }
  }

  void _startHeldPolling() {
    _heldPollTimer?.cancel();
    _heldPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_selectedDate == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      try {
        final availability = await GroundService.fetchSlotAvailability(
          groundId: widget.ground['id'] as String,
          date: dateStr,
        );
        if (!mounted) return;
        setState(() => _heldSegs = availability['heldSegs'] ?? {});
      } catch (_) {
        // Ignore — keep showing the last known held slots.
      }
    });
  }

  void _parsePrice() {
    // Expected format: "₹600/hr"
    final priceStr = widget.ground['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (priceStr.isNotEmpty) {
      _basePrice = int.parse(priceStr);
    }
  }

  void _generateTimeSlots() {
    _timeSlots.clear();
    _timeSlots24.clear();

    String openTimeStr = widget.ground['open_time']?.toString() ?? '10:00';
    String closeTimeStr = widget.ground['close_time']?.toString() ?? '20:00';
    
    int startHour = 10;
    int startMin = 0;
    int endHour = 20;
    int endMin = 0;
    
    try {
      final openParts = openTimeStr.split(':');
      if (openParts.length >= 2) {
        startHour = int.parse(openParts[0]);
        startMin = int.parse(openParts[1]);
      }
      
      final closeParts = closeTimeStr.split(':');
      if (closeParts.length >= 2) {
        endHour = int.parse(closeParts[0]);
        endMin = int.parse(closeParts[1]);
      }
    } catch (e) {
      // Fallback to default times on parse error
    }
    
    int startTotalMins = startHour * 60 + startMin;
    int endTotalMins = endHour * 60 + endMin;
    
    // Handle overnight slots (e.g. open 22:00, close 06:00)
    if (endTotalMins <= startTotalMins) {
      endTotalMins += 24 * 60;
    }
    
    // Generate slots in 30 min intervals
    // We only generate a start time if there is at least 30 mins before closing
    for (int currentMins = startTotalMins; currentMins <= endTotalMins - 30; currentMins += 30) {
      int h = (currentMins ~/ 60) % 24;
      int m = currentMins % 60;
      
      String ampm = h >= 12 ? 'PM' : 'AM';
      int displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      String minStr = m.toString().padLeft(2, '0');

      _timeSlots.add('$displayHour:$minStr $ampm');
      _timeSlots24.add('${h.toString().padLeft(2, '0')}:$minStr');
    }
  }

  int _timeToMins(String timeStr) {
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    int mins = int.parse(timeParts[1]);
    bool isPM = parts[1] == 'PM';
    if (isPM && hours != 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;
    return hours * 60 + mins;
  }

  String _calculateEndTime(String startTime, int durationMins) {
    int totalMins = _timeToMins(startTime) + durationMins;
    int endHours = (totalMins ~/ 60) % 24;
    int endMins = totalMins % 60;
    String endAmPm = endHours >= 12 ? 'PM' : 'AM';
    int displayEndHours = endHours > 12 ? endHours - 12 : (endHours == 0 ? 12 : endHours);
    String displayEndMins = endMins.toString().padLeft(2, '0');
    return '$displayEndHours:$displayEndMins $endAmPm';
  }

  String _formatApiTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        String ampm = h >= 12 ? 'PM' : 'AM';
        int displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        String minStr = m.toString().padLeft(2, '0');
        return '$displayHour:$minStr $ampm';
      }
    } catch (e) {
      // Fallback
    }
    return timeStr;
  }

  String _getOpenCloseText() {
    String openStr = widget.ground['open_time']?.toString() ?? '10:00';
    String closeStr = widget.ground['close_time']?.toString() ?? '20:00';
    return 'Open ${_formatApiTime(openStr)} - ${_formatApiTime(closeStr)}';
  }

  String _formatDuration(int mins) {
    if (mins % 60 == 0) {
      int hrs = mins ~/ 60;
      return '$hrs hr${hrs > 1 ? 's' : ''}';
    } else {
      double hrs = mins / 60;
      return '${hrs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} hrs';
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
                      _buildDateSelector(),
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
            Builder(
              builder: (context) {
                final images = widget.ground['images'] as List<dynamic>? ?? [];
                if (images.isEmpty) {
                  final fallbackUrl = widget.ground['imageUrl'] ?? 'assets/images/sports_bunnies.png';
                  if (fallbackUrl.toString().startsWith('http')) {
                    return Image.network(
                      fallbackUrl,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Image.asset(
                      fallbackUrl,
                      fit: BoxFit.cover,
                    );
                  }
                }
                return CarouselSlider(
                  options: CarouselOptions(
                    height: 280.0,
                    viewportFraction: 1.0,
                    autoPlay: images.length > 1,
                    autoPlayInterval: const Duration(seconds: 4),
                  ),
                  items: images.map((url) {
                    return Image.network(
                      url as String,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                    );
                  }).toList(),
                );
              }
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
                      const Color(0xFF161616).withValues(alpha: 0.0),
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
                color: const Color(0xFFE54F3F).withValues(alpha: 0.15),
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
            Text(
              _getOpenCloseText(),
              style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _showDurationBottomSheet(String slot) {
    int startMins = _timeToMins(slot);
    String closeTimeStr = widget.ground['close_time']?.toString() ?? '20:00';
    int closeMins = 20 * 60;
    try {
      final parts = closeTimeStr.split(':');
      if (parts.length >= 2) {
        closeMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}
    
    if (closeMins <= startMins) {
      closeMins += 24 * 60;
    }
    
    int maxAllowedMins = closeMins - startMins;
    if (maxAllowedMins > 11 * 60) {
      maxAllowedMins = 11 * 60; // Cap at 11 hours
    }
    
    int localDuration = 60; // Default
    if (localDuration > maxAllowedMins) {
      localDuration = maxAllowedMins;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 24.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          
                          const SizedBox(width: 8),
                          const Text(
                            'How long do you want to play?',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4, bottom: 24),
                    child: Text(
                      '${_formatDuration(localDuration)} — ends at ${_calculateEndTime(slot, localDuration)}',
                      style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: localDuration <= 30
                                ? null
                                : () {
                                    setModalState(() {
                                      localDuration -= 30;
                                    });
                                  },
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                            child: const Center(
                              child: Icon(Icons.remove, color: Colors.black, size: 28),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(localDuration),
                                style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'until ${_calculateEndTime(slot, localDuration)}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCECEB),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
                              border: Border.all(color: const Color(0xFFE54F3F), width: 2),
                            ),
                            child: InkWell(
                              onTap: (localDuration + 30) > maxAllowedMins
                                  ? null
                                  : () {
                                      setModalState(() {
                                        localDuration += 30;
                                      });
                                    },
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
                              child: Center(
                                child: Icon(Icons.add, color: (localDuration + 30) > maxAllowedMins ? Colors.grey : const Color(0xFFE54F3F), size: 28),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Tap + / - to adjust in 30-min steps · max ${_formatDuration(maxAllowedMins)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL TO PAY', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            int fare = (_basePrice / 2 * (localDuration ~/ 30)).round();
                            int platformFee = (fare * 0.03).round();
                            if (platformFee < 10 && fare > 0) platformFee = 10;
                            int finalPrice = fare + platformFee;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₹$finalPrice', style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 32, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('₹$fare fare + ₹$platformFee platform fee', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCardPill('FROM', slot),
                                    _buildCardPill('TO', _calculateEndTime(slot, localDuration)),
                                    _buildCardPill('DURATION', _formatDuration(localDuration)),
                                    _buildCardPill('RATE', '₹$_basePrice/hr'),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStartTime = slot;
                          _durationMins = localDuration;
                        });
                        Navigator.pop(context); // Close BottomSheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewBookingScreen(
                              ground: widget.ground,
                              date: _selectedDate!,
                              startTime: slot,
                              endTime: _calculateEndTime(slot, localDuration),
                              durationStr: _formatDuration(localDuration),
                              fare: (_basePrice / 2 * (localDuration ~/ 30)).round(),
                              platformFee: ((_basePrice / 2 * (localDuration ~/ 30)).round() * 0.03).round() < 10 && (_basePrice / 2 * (localDuration ~/ 30)).round() > 0 ? 10 : ((_basePrice / 2 * (localDuration ~/ 30)).round() * 0.03).round(),
                              finalPrice: (_basePrice / 2 * (localDuration ~/ 30)).round() + (((_basePrice / 2 * (localDuration ~/ 30)).round() * 0.03).round() < 10 && (_basePrice / 2 * (localDuration ~/ 30)).round() > 0 ? 10 : ((_basePrice / 2 * (localDuration ~/ 30)).round() * 0.03).round()),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE54F3F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
           ),
          );
        });
      },
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Text(
              '* Bookings Open for Next 15 days only',
              style: TextStyle(color: Color(0xFF98989E), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 15,
            itemBuilder: (context, index) {
              final date = now.add(Duration(days: index));
              final isSelected = _selectedDate != null && 
                                 _selectedDate!.year == date.year && 
                                 _selectedDate!.month == date.month && 
                                 _selectedDate!.day == date.day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedStartTime = null; // reset time selection when date changes
                    _bookedSegs = {};
                    _heldSegs = {};
                  });
                  _fetchAvailability();
                  _startHeldPolling();
                },
                child: Container(
                  width: 65,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE54F3F) : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE54F3F) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF98989E),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : const Color(0xFF98989E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    if (_selectedDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF98989E), size: 40),
            SizedBox(height: 16),
            Text(
              'Please select a date\nto view available time slots.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF98989E), fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
    }

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
              )
            else if (_isLoadingAvailability)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE54F3F)),
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
            final slot24 = _timeSlots24[index];
            final isSelected = _selectedStartTime == slot;
            final isPast = _isSlotPast(slot24);
            final isBooked = _bookedSegs.contains(slot24);
            final isHeld = !isBooked && _heldSegs.contains(slot24);
            final isDisabled = isPast || isBooked || isHeld;

            Color bgColor;
            Color textColor;
            String? badge;
            if (isSelected) {
              bgColor = const Color(0xFFE54F3F);
              textColor = Colors.white;
            } else if (isPast) {
              bgColor = const Color(0xFF232323);
              textColor = const Color(0xFF6B6B6B);
              badge = 'Past';
            } else if (isBooked) {
              bgColor = const Color(0xFF3A1F1F);
              textColor = const Color(0xFFE57373);
              badge = 'Booked';
            } else if (isHeld) {
              bgColor = const Color(0xFF3A2F17);
              textColor = const Color(0xFFE6A23C);
              badge = '⏳ Held';
            } else {
              bgColor = const Color(0xFF2C2C2E);
              textColor = const Color(0xFF98989E);
            }

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      _showDurationBottomSheet(slot);
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (badge != null)
                      Text(
                        badge,
                        style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 9),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSlotLegend(),
      ],
    );
  }

  bool _isSlotPast(String slot24) {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return false;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    if (!isToday) return false;

    final parts = slot24.split(':');
    final slotMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final nowMins = now.hour * 60 + now.minute;
    return slotMins + 30 <= nowMins;
  }

  Widget _buildSlotLegend() {
    final items = [
      (const Color(0xFF2C2C2E), 'Available'),
      (const Color(0xFFE54F3F), 'Selected'),
      (const Color(0xFF3A1F1F), 'Booked'),
      (const Color(0xFF3A2F17), 'Held'),
      (const Color(0xFF232323), 'Past'),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: item.$1,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(item.$2, style: const TextStyle(color: Color(0xFF98989E), fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCardPill(String title, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highlight ? const Color(0xFFE54F3F) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

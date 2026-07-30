import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import '../services/ground_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'review_booking_screen.dart';
import 'login_screen.dart';

class GroundDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ground;
  final VoidCallback? onBackPressed;

  const GroundDetailsScreen({super.key, required this.ground, this.onBackPressed});

  @override
  State<GroundDetailsScreen> createState() => _GroundDetailsScreenState();
}

class _GroundDetailsScreenState extends State<GroundDetailsScreen> {
  final List<String> _timeSlots = [];
  final List<String> _timeSlots24 = [];
  String? _selectedStartTime;
  DateTime? _selectedDate;
  int _durationMins = 60;
  int _basePrice = 600;

  Set<String> _bookedSegs = {};
  Set<String> _heldSegs = {};
  bool _isLoadingAvailability = false;
  Timer? _heldPollTimer;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _slotAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateTimeSlots();
    _parsePrice();
    _fetchAvailability();
    _startHeldPolling();
  }

  @override
  void dispose() {
    _heldPollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _parsePrice() {
    final priceStr = widget.ground['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '600';
    if (priceStr.isNotEmpty) {
      _basePrice = int.tryParse(priceStr) ?? 600;
    }
  }

  Future<void> _fetchAvailability() async {
    if (_selectedDate == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    setState(() => _isLoadingAvailability = true);
    try {
      final availability = await GroundService.fetchSlotAvailability(
        groundId: widget.ground['id']?.toString() ?? '',
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
          groundId: widget.ground['id']?.toString() ?? '',
          date: dateStr,
        );
        if (!mounted) return;
        setState(() => _heldSegs = availability['heldSegs'] ?? {});
      } catch (_) {}
    });
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
    } catch (_) {}
    
    int startTotalMins = startHour * 60 + startMin;
    int endTotalMins = endHour * 60 + endMin;
    
    if (endTotalMins <= startTotalMins) {
      endTotalMins += 24 * 60;
    }
    
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
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hours = int.parse(timeParts[0]);
      int mins = int.parse(timeParts[1]);
      bool isPM = parts[1] == 'PM';
      if (isPM && hours != 12) hours += 12;
      if (!isPM && hours == 12) hours = 0;
      return hours * 60 + mins;
    } catch (_) {
      return 600;
    }
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

  int _calculateMaxAvailableDuration(String startSlot) {
    final index = _timeSlots.indexOf(startSlot);
    if (index == -1) return 60;

    int consecutiveMins = 30;
    for (int i = index + 1; i < _timeSlots24.length; i++) {
      final slot24 = _timeSlots24[i];
      if (_bookedSegs.contains(slot24) || _heldSegs.contains(slot24) || _isSlotPast(slot24)) {
        break;
      }
      consecutiveMins += 30;
    }
    return consecutiveMins;
  }

  bool _isSlotPast(String slot24) {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return false;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    if (!isToday) return false;

    try {
      final parts = slot24.split(':');
      final slotMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final nowMins = now.hour * 60 + now.minute;
      return slotMins + 30 <= nowMins;
    } catch (_) {
      return false;
    }
  }

  String _formatDuration(int mins) {
    if (mins < 60) return '$mins Mins';
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    if (remMins == 0) return '$hrs ${hrs == 1 ? 'Hour' : 'Hours'}';
    return '$hrs hr $remMins mins';
  }

  int _calculatePrice() {
    return ((_basePrice / 60) * _durationMins).round();
  }

  void _handleBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _proceedToReview() {
    if (_selectedStartTime == null || _selectedDate == null) return;
    if (AuthService.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final fare = ((_basePrice / 60) * _durationMins).round();
    int platformFee = (fare * 0.03).round();
    if (platformFee < 10 && fare > 0) platformFee = 10;
    final finalPrice = fare + platformFee;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewBookingScreen(
          ground: widget.ground,
          date: _selectedDate!,
          startTime: _selectedStartTime!,
          endTime: _calculateEndTime(_selectedStartTime!, _durationMins),
          durationStr: _formatDuration(_durationMins),
          fare: fare,
          platformFee: platformFee,
          finalPrice: finalPrice,
        ),
      ),
    );
  }

  void _showDurationBottomSheet(String slot) {
    int maxAllowedMins = _calculateMaxAvailableDuration(slot);
    if (maxAllowedMins > 11 * 60) {
      maxAllowedMins = 11 * 60;
    }
    
    int localDuration = 60;
    if (localDuration > maxAllowedMins) {
      localDuration = maxAllowedMins;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'How long do you want to play?',
                        style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: context.subTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected start time: $slot on ${DateFormat('EEE, d MMM').format(_selectedDate!)}',
                    style: TextStyle(color: context.subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: localDuration <= 30
                            ? null
                            : () {
                                setModalState(() {
                                  localDuration -= 30;
                                });
                              },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: localDuration <= 30 ? context.borderColor : const Color(0xFFE54F3F)),
                          ),
                          child: Icon(Icons.remove, color: localDuration <= 30 ? Colors.grey : const Color(0xFFE54F3F), size: 28),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5200).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE54F3F), width: 2),
                        ),
                        child: Text(
                          _formatDuration(localDuration),
                          style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: (localDuration + 30) > maxAllowedMins
                            ? null
                            : () {
                                setModalState(() {
                                  localDuration += 30;
                                });
                              },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: (localDuration + 30) > maxAllowedMins ? context.borderColor : const Color(0xFFE54F3F)),
                          ),
                          child: Icon(Icons.add, color: (localDuration + 30) > maxAllowedMins ? Colors.grey : const Color(0xFFE54F3F), size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calculated Price', style: TextStyle(color: context.subTextColor, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${((_basePrice / 60) * localDuration).round()}',
                            style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedStartTime = slot;
                            _durationMins = localDuration;
                          });
                          Navigator.pop(context);
                          _proceedToReview();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE54F3F),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Confirm & Proceed',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new, color: context.textColor, size: 20),
                                onPressed: _handleBack,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.ground['title'] ?? 'Ground Details',
                                  style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(16), child: _buildImageWidget(height: 320)),
                                const SizedBox(height: 24),
                                _buildTitleAndDetails(),
                                const SizedBox(height: 32),
                                _buildDateSelector(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(width: 1, color: context.borderColor),
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                      builder: (context, rightConstraints) {
                        final minH = rightConstraints.maxHeight.isFinite
                            ? (rightConstraints.maxHeight - 48).clamp(0.0, double.infinity)
                            : 0.0;
                        return SingleChildScrollView(
                          child: Container(
                            constraints: BoxConstraints(minHeight: minH),
                            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSlotGridSection(),
                                const SizedBox(height: 32),
                                _buildBottomBarContent(),
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMobileHeroHeader(),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitleAndDetails(),
                              const SizedBox(height: 32),
                              _buildDateSelector(),
                              const SizedBox(height: 32),
                              Container(
                                key: _slotAreaKey,
                                child: _buildSlotGridSection(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildStickyBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileHeroHeader() {
    return Stack(
      children: [
        _buildImageWidget(height: 280),
        Positioned(
          top: 16,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: _handleBack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget({required double height}) {
    final images = widget.ground['images'] as List<dynamic>? ?? [];
    if (images.isNotEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          height: height,
          viewportFraction: 1.0,
          autoPlay: images.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
        ),
        items: images.map((url) {
          return Image.network(
            url as String,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Image.asset('assets/images/sports_bunnies.png', height: height, width: double.infinity, fit: BoxFit.cover),
          );
        }).toList(),
      );
    }

    final imageUrl = widget.ground['imageUrl'] as String? ?? '';
    final fallback = 'assets/images/sports_bunnies.png';

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, height: height, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, e, s) => Image.asset(fallback, height: height, width: double.infinity, fit: BoxFit.cover),
      );
    }

    return Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: double.infinity,
          color: context.subCardBg,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE54F3F)),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(fallback, height: height, width: double.infinity, fit: BoxFit.cover);
      },
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
                widget.ground['title'] ?? 'Sports Ground',
                style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE54F3F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer, color: Color(0xFFE54F3F), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.ground['type'] ?? 'Sports',
                    style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, color: context.subTextColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.ground['location'] ?? 'Hyderabad, Telangana',
                style: TextStyle(color: context.subTextColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Date', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            if (_selectedDate != null)
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate!),
                style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 14, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              'Bookings are open for next 15 days only',
              style: TextStyle(
                color: context.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                    _selectedStartTime = null;
                  });
                  _fetchAvailability();
                  _startHeldPolling();
                },
                child: Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE54F3F) : context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE54F3F) : context.borderColor,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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

  Widget _buildSlotGridSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Available Slots', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isLoadingAvailability)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE54F3F)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Tap a slot to choose your duration', style: TextStyle(color: context.subTextColor, fontSize: 12, fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),

        if (_isLoadingAvailability)
          _buildSlotSkeletonGrid()
        else if (_timeSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.calendar_today, color: context.subTextColor, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No slots available',
                    style: TextStyle(color: context.subTextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.9,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  final slot24 = _timeSlots24[index];
                  final isSelected = _selectedStartTime == slot;
                  final isPast = _isSlotPast(slot24);
                  final isBooked = _bookedSegs.contains(slot24);
                  final isHeld = !isBooked && _heldSegs.contains(slot24);

                  return _buildSlotChip(slot, slot24, isSelected: isSelected, isPast: isPast, isBooked: isBooked, isHeld: isHeld);
                },
              ),
              const SizedBox(height: 16),
              _buildSlotLegend(),
            ],
          ),
      ],
    );
  }

  Widget _buildSlotSkeletonGrid() {
    return Shimmer.fromColors(
      baseColor: context.subCardBg,
      highlightColor: context.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.9,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: context.subCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String timeStr, String slot24, {required bool isSelected, required bool isPast, required bool isBooked, required bool isHeld}) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    double opacity = 1.0;

    String? statusText;

    if (isSelected) {
      bgColor = const Color(0xFFE54F3F);
      textColor = const Color(0xFFFFFFFF);
      borderColor = const Color(0xFFE54F3F);
      opacity = 1.0;
      statusText = null;
    } else if (isPast) {
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFFB923C);
      borderColor = const Color(0xFFFED7AA);
      opacity = 1.0;
      statusText = 'Past';
    } else if (isBooked) {
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFF87171);
      borderColor = const Color(0xFFFECACA);
      opacity = 1.0;
      statusText = 'Booked';
    } else if (isHeld) {
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFD97706);
      borderColor = const Color(0xFFFCD34D);
      opacity = 1.0;
      statusText = 'Held';
    } else {
      bgColor = const Color(0xFFFFFFFF);
      textColor = const Color(0xFF0A0A0F);
      borderColor = const Color(0xFFD8D4CA);
      opacity = 1.0;
      statusText = null;
    }

    final isDisabled = isPast || isBooked || isHeld;

    return GestureDetector(
      onTap: isDisabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This time slot is unavailable.')),
              );
            }
          : () {
              setState(() {
                _selectedStartTime = timeStr;
              });
              _showDurationBottomSheet(timeStr);
            },
      child: Opacity(
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: statusText != null ? 5 : 0),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (statusText != null)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isHeld) ...[
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 9.5,
                          color: textColor.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
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

  Widget _buildSlotLegend() {
    final legends = [
      (const Color(0xFFFFFFFF), const Color(0xFF0A0A0F), const Color(0xFFD8D4CA), 1.0, 'Available'),
      (const Color(0xFFE54F3F), const Color(0xFFFFFFFF), const Color(0xFFE54F3F), 1.0, 'Selected'),
      (const Color(0xFFFEF2F2), const Color(0xFFF87171), const Color(0xFFFECACA), 1.0, 'Booked'),
      (const Color(0xFFFFFBEB), const Color(0xFFD97706), const Color(0xFFFCD34D), 1.0, 'Held'),
      (const Color(0xFFFFF7ED), const Color(0xFFFB923C), const Color(0xFFFED7AA), 1.0, 'Past'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: legends.map((l) {
        final isHeldLegend = l.$5 == 'Held';
        return Opacity(
          opacity: l.$4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: l.$1,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: l.$3),
                ),
              ),
              const SizedBox(width: 6),
              if (isHeldLegend) ...[
                Icon(Icons.hourglass_top_rounded, size: 11, color: l.$2),
                const SizedBox(width: 2),
              ],
              Text(l.$5, style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildBottomBarContent(),
      ),
    );
  }

  Widget _buildBottomBarContent() {
    final price = _calculatePrice();

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TOTAL PRICE', style: TextStyle(color: context.subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹$price',
                  style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text('/ ${_formatDuration(_durationMins)}', style: TextStyle(color: context.subTextColor, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedStartTime == null) {
                  final ctx = _slotAreaKey.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an available time slot first.')),
                  );
                } else {
                  _proceedToReview();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE54F3F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _selectedStartTime == null ? 'Select Slot' : 'Book Now',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

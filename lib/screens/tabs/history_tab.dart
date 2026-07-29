import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import '../booking_detail_screen.dart';
import '../../widgets/touchable_opacity.dart';

// ─── Exact colours from the reference design ────────────────────────────────
const _kOrange = Color(0xFFE5500A);       // status badge, icons, buttons
const _kGreen  = Color(0xFF2AB04A);       // "Completed" status
const _kGrey   = Color(0xFF8A8A8E);       // sub-text, labels
const _kBorder = Color(0xFFE8E8E8);       // card border (light mode)
const _kPanelBg = Color(0xFFFFF6F2);     // lightest orange tint for details box
const _kPanelBorder = Color(0xFFFDE7DC); // subtle orange border for details box
const _kPanelBgDark = Color(0xFF1C1C1E); // details panel bg (dark mode)
// ────────────────────────────────────────────────────────────────────────────

class HistoryTab extends StatefulWidget {
  final VoidCallback? onProfileTapped;
  const HistoryTab({super.key, this.onProfileTapped});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final bookings = await BookingService.fetchMyBookings();
      setState(() { _bookings = bookings; _isLoading = false; });
    } catch (_) {
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _upcoming =>
      _bookings.where((b) => b['status'] == 'Upcoming').toList();
  List<Map<String, dynamic>> get _completed =>
      _bookings.where((b) => b['status'] != 'Upcoming').toList();

  // ─── ROOT BUILD ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 720;
      final hPad = isWide ? 20.0 : 16.0;

      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: back button + "My Bookings" + avatar ───────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                child: Row(
                  children: [
                    _backButton(),
                    Expanded(
                      child: Text(
                        'My Bookings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _profileAvatar(),
                  ],
                ),
              ).animate().fade(duration: 280.ms),

              const SizedBox(height: 14),

              // ── Tab bar ─────────────────────────────────────────────────────
              // Matches image: full-width, evenly spread tabs, orange
              // underline indicator sized to the label.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: _kOrange,
                  unselectedLabelColor: _kGrey,
                  indicatorColor: _kOrange,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming', height: 36),
                    Tab(text: 'Completed', height: 36),
                  ],
                ),
              ).animate().fade(delay: 60.ms, duration: 280.ms),

              // Full-width hairline separator (matches image)
              Divider(
                height: 1, thickness: 1,
                color: isDark ? const Color(0xFF3A3A3C) : _kBorder,
              ),

              // ── Content ─────────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _buildSkeleton(hPad)
                    : _hasError
                        ? _buildError()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildList(_upcoming, hPad,
                                  emptyMsg: 'No upcoming bookings'),
                              _buildList(_completed, hPad,
                                  emptyMsg: 'No completed bookings'),
                            ],
                          ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── LIST ──────────────────────────────────────────────────────────────────
  Widget _buildList(List<Map<String, dynamic>> list, double hPad,
      {required String emptyMsg}) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_today_outlined,
              color: _kGrey.withValues(alpha: 0.6), size: 52),
          const SizedBox(height: 14),
          Text(emptyMsg,
              style: const TextStyle(
                  color: _kGrey, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _card(list[i], i),
    );
  }

  // ─── CARD ──────────────────────────────────────────────────────────────────
  Widget _card(Map<String, dynamic> b, int index) {
    final isDark = context.isDark;
    final isUpcoming = b['status'] == 'Upcoming';

    // Status colours — match reference exactly
    final statusTxt   = isUpcoming ? _kOrange   : _kGreen;
    final statusBg    = isUpcoming
        ? const Color(0xFFFFF0E8)   // light orange tint
        : const Color(0xFFE8F8EE);  // light green tint

    // Fare fields
    final fare        = (b['fare']        as num?)?.toDouble() ?? 0;
    final platformFee = (b['platformFee'] as num?)?.toDouble() ?? 0;
    final total       = (b['totalAmount'] as num?)?.toDouble() ?? 0;
    final durH        = (b['durationHours'] as num?)?.toDouble() ?? 1.5;
    final refId       = (b['referenceId'] as String?) ?? '';
    final city        = (b['city']  as String?) ?? '';
    final addr        = (b['address'] as String?) ?? '';
    final location    = [if (addr.isNotEmpty) addr, if (city.isNotEmpty) city]
        .join(', ');

    final durLabel = durH == durH.roundToDouble()
        ? '${durH.toInt()} hrs'
        : '${durH.toStringAsFixed(1)} hrs';

    // "Booked on" — use date field as fallback
    final bookedOn = (b['bookedOn'] as String?) ?? (b['date'] as String?) ?? '';

    // Border colour
    final borderCol   = isDark ? const Color(0xFF3A3A3C) : _kBorder;
    final panelBg     = isDark ? _kPanelBgDark : _kPanelBg;
    final panelBorder = isDark ? const Color(0xFF3A3A3C) : _kPanelBorder;

    return TouchableOpacity(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: b))),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderCol),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── TOP: image + meta + status badge ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Ground thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _groundImage(b, size: 74),
              ),
              const SizedBox(width: 10),

              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row + status badge (right-aligned)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (b['title'] as String?) ?? '',
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isUpcoming ? 'Upcoming' : 'Completed',
                            style: TextStyle(
                              color: statusTxt,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Location row
                    if (location.isNotEmpty) ...[
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: _kOrange, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                                color: _kGrey, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 2),
                    ],

                    // Booked-on row
                    Row(children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: _kOrange, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Booked on $bookedOn',
                          style: const TextStyle(
                              color: _kGrey, fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),

          // ── DETAIL PANEL ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: panelBorder),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Booking Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _panelLabel('BOOKING DETAILS'),
                          const SizedBox(height: 6),
                          _iconRow(Icons.calendar_today_rounded,
                              (b['date'] as String?) ?? ''),
                          const SizedBox(height: 4),
                          _iconRow(Icons.access_time_rounded,
                              (b['time'] as String?) ?? ''),
                          const SizedBox(height: 4),
                          _iconRow(Icons.timelapse_rounded, durLabel),
                          if (refId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _iconRow(Icons.qr_code_2_rounded, refId),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Vertical divider
                  VerticalDivider(
                      width: 1, thickness: 1, color: panelBorder),

                  // Right: Fare Details
                  SizedBox(
                    width: 135,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _panelLabel('FARE DETAILS'),
                          const SizedBox(height: 6),
                          _fareRow('Ground Fare',
                              '₹${fare.round()}'),
                          const SizedBox(height: 3),
                          _fareRow('Platform Fee',
                              '₹${platformFee.round()}'),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Divider(
                                height: 1, thickness: 1, color: panelBorder),
                          ),
                          _fareRow(
                            'Total Amount',
                            '₹${total.round()}',
                            labelBold: true,
                            valueBold: true,
                            valueColor: _kOrange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ACTION BUTTONS ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(children: [
              // Share — outlined, orange border
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _share(b),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kOrange,
                      side: const BorderSide(color: _kOrange, width: 1.2),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.ios_share_rounded, size: 14),
                          SizedBox(width: 5),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // View Details — solid orange
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(booking: b)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('View Details'),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ).animate().fade(
      duration: 280.ms,
      delay: Duration(milliseconds: 60 + index * 55),
    ).slideY(
      begin: 0.05,
      duration: 280.ms,
      curve: Curves.easeOutCubic,
      delay: Duration(milliseconds: 60 + index * 55),
    );
  }

  // ─── HEADER WIDGETS ────────────────────────────────────────────────────────
  Widget _backButton() => TouchableOpacity(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kOrange.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kOrange, size: 16),
        ),
      );

  Widget _profileAvatar() {
    final photoUrl = AuthService.currentUser?.profileImageUrl;
    final name = AuthService.currentUser?.fullName ?? '';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase()
        : '';

    return TouchableOpacity(
      onTap: () {
        if (widget.onProfileTapped != null) {
          widget.onProfileTapped!();
        }
      },
      child: CircleAvatar(
        radius: 19,
        backgroundColor: _kOrange.withValues(alpha: 0.12),
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(
                initials.isNotEmpty ? initials : '?',
                style: const TextStyle(
                    color: _kOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              )
            : null,
      ),
    );
  }

  // ─── SMALL HELPERS ─────────────────────────────────────────────────────────

  Widget _panelLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: _kGrey,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      );

  Widget _iconRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _kOrange, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _fareRow(
    String label,
    String value, {
    bool labelBold = false,
    bool valueBold = false,
    Color? valueColor,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelBold ? context.textColor : _kGrey,
                fontSize: 11.5,
                fontWeight: labelBold ? FontWeight.bold : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? context.textColor,
              fontSize: 11.5,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ],
      );

  void _share(Map<String, dynamic> b) {
    final text =
        '🏟️ ${b['title']}\n📅 ${b['date']}\n⏰ ${b['time']}\n💰 ${b['price']}\n\nBooked via Book Rabbit';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ─── SKELETON ──────────────────────────────────────────────────────────────
  Widget _buildSkeleton(double hPad) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 80),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, _) => Shimmer.fromColors(
        baseColor: context.isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF0F0F0),
        highlightColor: context.isDark
            ? const Color(0xFF3A3A3C)
            : const Color(0xFFE5E5EA),
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
        ),
      ),
    );
  }

  // ─── ERROR ─────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, color: _kGrey, size: 48),
          const SizedBox(height: 16),
          const Text('Failed to load bookings',
              style: TextStyle(color: _kGrey, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchBookings,
            style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ]),
      );

  // ─── GROUND IMAGE ──────────────────────────────────────────────────────────
  String _fallback(String type) {
    final t = type.toLowerCase();
    if (t.contains('cricket')) return 'assets/images/cricket-rabbit.png';
    if (t.contains('football') || t.contains('soccer'))
      return 'assets/images/football-rabbit.png';
    if (t.contains('tennis') || t.contains('badminton') ||
        t.contains('pickleball')) return 'assets/images/tennis-rabbit.png';
    return 'assets/images/sports_bunnies.png';
  }

  Widget _groundImage(Map<String, dynamic> b, {double size = 92}) {
    final url      = (b['imageUrl'] as String?) ?? '';
    final fallback = _fallback((b['type'] as String?) ?? '');

    if (url.startsWith('assets/')) {
      return Image.asset(url,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(fallback, width: size, height: size, fit: BoxFit.cover));
    }

    return Image.network(
      url,
      width: size, height: size, fit: BoxFit.cover,
      loadingBuilder: (ctx, child, prog) {
        if (prog == null) return child;
        return Container(
          width: size, height: size,
          color: context.isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF0F0F0),
          child: const Center(
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kOrange),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) =>
          Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
    );
  }
}

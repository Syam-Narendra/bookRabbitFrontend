import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants.dart';
import '../router/route_extensions.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/razorpay_web/razorpay_web_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/touchable_opacity.dart';
import 'booking_success_screen.dart';

class ReviewBookingScreen extends StatefulWidget {
  final Map<String, dynamic> ground;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String durationStr;
  final int fare;
  final int platformFee;
  final int finalPrice;

  const ReviewBookingScreen({
    super.key,
    required this.ground,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationStr,
    required this.fare,
    required this.platformFee,
    required this.finalPrice,
  });

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  late Razorpay _razorpay;
  bool _isCreatingOrder = false;
  bool _isVerifyingPayment = false;
  BookingOrder? _order;

  int get _displayFare => _order?.baseAmount.round() ?? widget.fare;
  int get _displayFee => _order?.platformFee.round() ?? widget.platformFee;
  int get _displayTotal => _order?.totalAmount.round() ?? widget.finalPrice;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  static String _to24Hour(String time12) {
    try {
      final dateTime = DateFormat('hh:mm a').parse(time12);
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return time12;
    }
  }

  Future<void> _startPayment() async {
    setState(() => _isCreatingOrder = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      final startTime24 = _to24Hour(widget.startTime);
      final endTime24 = _to24Hour(widget.endTime);

      final order = await BookingService.createOrder(
        groundId: widget.ground['id'] as String,
        date: dateStr,
        startTime: startTime24,
        endTime: endTime24,
      );

      if (!mounted) return;
      _order = order;
      setState(() => _isCreatingOrder = false);

      final options = {
        'key': AppConstants.razorpayKey,
        'order_id': order.orderId,
        'amount': (order.totalAmount * 100).round(),
        'name': 'Book Rabbit',
        'description': '${widget.ground['title']} Booking',
        'prefill': {'contact': AuthService.currentUser?.phoneNumber ?? ''},
        'theme': {'color': '#FF7A2F'},
      };

      if (kIsWeb) {
        launchRazorpayWebCheckout(
          options: options,
          onSuccess: (paymentId, orderId, signature) =>
              _handleWebPaymentSuccess(paymentId, orderId, signature),
          onError: (code, message) => _onWebPaymentError(message),
        );
      } else {
        _razorpay.open(options);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initiate payment. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _handleWebPaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    setState(() => _isVerifyingPayment = true);
    try {
      final referenceId = await BookingService.verifyPayment(
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            referenceId: referenceId,
            ground: widget.ground,
            date: widget.date,
            startTime: widget.startTime,
            endTime: widget.endTime,
            finalPrice: _order?.totalAmount.round() ?? widget.finalPrice,
            platformFee: _order?.platformFee.round() ?? widget.platformFee,
          ),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  void _onWebPaymentError(String message) {
    final order = _order;
    if (order != null) {
      BookingService.releaseSlot(
        groundId: widget.ground['id'] as String,
        date: DateFormat('yyyy-MM-dd').format(widget.date),
        startTime: _to24Hour(widget.startTime),
        endTime: _to24Hour(widget.endTime),
        holdId: order.holdId,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Failed: $message',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isVerifyingPayment = true);
    try {
      final referenceId = await BookingService.verifyPayment(
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            referenceId: referenceId,
            ground: widget.ground,
            date: widget.date,
            startTime: widget.startTime,
            endTime: widget.endTime,
            finalPrice: _order?.totalAmount.round() ?? widget.finalPrice,
            platformFee: _order?.platformFee.round() ?? widget.platformFee,
          ),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final order = _order;
    if (order != null) {
      BookingService.releaseSlot(
        groundId: widget.ground['id'] as String,
        date: DateFormat('yyyy-MM-dd').format(widget.date),
        startTime: _to24Hour(widget.startTime),
        endTime: _to24Hour(widget.endTime),
        holdId: order.holdId,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Failed: ${response.message}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet Selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;

          if (isWide) {
            // ── Wide Desktop / Laptop Layout matching the mockup ──────────────
            return Stack(
              children: [
                if (!_isVerifyingPayment)
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top Web Navbar
                        _buildWebNavbar(context),

                        // Hero Header Section
                        _buildWebHeroHeader(context),

                        const SizedBox(height: 24),

                        // Main Content Container
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1140),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // ── Left Column (60%): Main Arena Card ──
                                      Expanded(
                                        flex: 6,
                                        child: _buildWebGroundCard()
                                            .animate()
                                            .fade(delay: 100.ms)
                                            .slideY(begin: 0.05),
                                      ),

                                      const SizedBox(width: 24),

                                      // ── Right Column (40%): Payment Card ──
                                      Expanded(
                                        flex: 4,
                                        child: _buildWebPaymentCard(isWide: true)
                                            .animate()
                                            .fade(delay: 200.ms)
                                            .slideY(begin: 0.05),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Bottom Trust Banner
                                _buildTrustBanner().animate().fade(
                                  delay: 300.ms,
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isVerifyingPayment)
                  Positioned.fill(child: _buildProcessingOverlay()),
              ],
            );
          }

          // ── Mobile / Narrow Layout ─────────────────────────────────────────
          return Stack(
            children: [
              if (!_isVerifyingPayment)
                SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          _buildMobileHeaderBanner(context, topInset),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMobileSummaryCard()
                                .animate()
                                .fade(delay: 100.ms)
                                .slideY(begin: 0.1),
                          ),

                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildWebPaymentCard(isWide: false)
                                .animate()
                                .fade(delay: 200.ms)
                                .slideY(begin: 0.1),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_isVerifyingPayment)
                Positioned.fill(child: _buildProcessingOverlay()),
            ],
          );
        },
      ),
      bottomNavigationBar: null,
    );
  }

  // ── Web Navigation Header Bar ──────────────────────────────────────────────
  Widget _buildWebNavbar(BuildContext context) {
    final userName = AuthService.currentUser?.fullName ?? 'User Account';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Row(
            children: [
              // Logo
              InkWell(
                onTap: () => context.goHome(),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/footer_logo.png',
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports_soccer,
                        color: Color(0xFFFF5200),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Book',
                            style: TextStyle(color: Color(0xFF1E1E1E)),
                          ),
                          TextSpan(
                            text: 'Rabbit',
                            style: TextStyle(color: Color(0xFFFF5200)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 48),

              const Spacer(),

              // Location Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.subCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFFFF5200),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hyderabad',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: context.subTextColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // User Profile Chip
              InkWell(
                onTap: () => context.goAccount(),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.subCardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(
                          0xFFFF5200,
                        ).withValues(alpha: 0.15),
                        backgroundImage:
                            AuthService.currentUser?.profileImageUrl != null
                            ? NetworkImage(
                                AuthService.currentUser!.profileImageUrl!,
                              )
                            : null,
                        child: AuthService.currentUser?.profileImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 16,
                                color: Color(0xFFFF5200),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: context.subTextColor,
                      ),
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

  // ── Web Hero Banner Header Section ─────────────────────────────────────────
  Widget _buildWebHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDark
              ? [const Color(0xFF2C1C16), const Color(0xFF1E1410)]
              : [const Color(0xFFFFF7F2), const Color(0xFFFFEAE0)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1140),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Back Button
              InkWell(
                onTap: _navigateBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: context.textColor,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5200).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Review Booking',
                        style: TextStyle(
                          color: Color(0xFFFF5200),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: context.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review your booking details before you proceed to pay.',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Rabbit Mascot Artwork Right Side
              Image.asset(
                'assets/images/vendor-login-rabbit.png',
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Web Main Ground Arena Card ─────────────────────────────────────────────
  Widget _buildWebGroundCard() {
    final title = widget.ground['title'] as String? ?? 'Sports Ground';
    final location =
        (widget.ground['address'] ??
                widget.ground['location'] ??
                'Madhapur, Hyderabad')
            .toString();
    final sportTag =
        (widget.ground['category'] ??
                widget.ground['type'] ??
                widget.ground['tag'] ??
                'Cricket')
            .toString();
    final imageUrl =
        (widget.ground['imageUrl'] ??
                (widget.ground['images'] as List?)?.first ??
                'assets/images/sports_bunnies.png')
            .toString();

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with "Upcoming" Badge Overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            width: 200,
                            height: 125,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 200,
                                  height: 125,
                                  color: context.subCardBg,
                                  child: const Icon(
                                    Icons.sports_cricket,
                                    size: 40,
                                  ),
                                ),
                          )
                        : Image.asset(
                            imageUrl,
                            width: 200,
                            height: 125,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 200,
                                  height: 125,
                                  color: context.subCardBg,
                                  child: const Icon(
                                    Icons.sports_cricket,
                                    size: 40,
                                  ),
                                ),
                          ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Upcoming',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Title & Location Meta Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFFFF5200),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.navigation_outlined,
                          size: 16,
                          color: Color(0xFFFF5200),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '2.3 km away',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.subTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_cricket_outlined,
                          size: 16,
                          color: Color(0xFFFF5200),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sportTag,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.subTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Info Strip (Date, Time, Duration)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.subCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFFFF5200),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.subTextColor,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'EEE, MMM d, yyyy',
                              ).format(widget.date),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 28, width: 1, color: context.borderColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFFFF5200),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.subTextColor,
                                ),
                              ),
                              Text(
                                '${widget.startTime} – ${widget.endTime}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 28, width: 1, color: context.borderColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFFFF5200),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.subTextColor,
                                ),
                              ),
                              Text(
                                widget.durationStr,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Web Payment Details Card ───────────────────────────────────────────────
  Widget _buildWebPaymentCard({bool isWide = true}) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: isWide
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ground Fare',
                style: TextStyle(color: context.subTextColor, fontSize: 14),
              ),
              Text(
                '₹$_displayFare',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Platform Fee ',
                    style: TextStyle(color: context.subTextColor, fontSize: 14),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.subTextColor,
                  ),
                ],
              ),
              Text(
                '₹$_displayFee',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Divider(color: context.borderColor, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total to Pay',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              Text(
                '₹$_displayTotal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF5200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSecuredBadge(),
          const SizedBox(height: 14),
          _buildPayButton(),
          const SizedBox(height: 12),
          _buildEncryptedFooter(),
        ],
      ),
    );
  }

  // ── Bottom Trust Features Strip Banner ────────────────────────────────────
  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          _buildTrustItem(
            icon: Icons.shield_outlined,
            title: 'Safe & Secure',
            subtitle: 'Your payment and data are protected',
          ),
          _buildTrustItem(
            icon: Icons.workspace_premium_outlined,
            title: 'Instant Confirmation',
            subtitle: 'Get booking confirmation immediately',
          ),
          _buildTrustItem(
            icon: Icons.calendar_month_outlined,
            title: '24/7 Support',
            subtitle: 'We\'re here to help you anytime',
          ),
          _buildTrustItem(
            icon: Icons.verified_outlined,
            title: 'Trusted by 10,000+ Players',
            subtitle: 'Join thousands of happy customers',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5200).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFFFF5200)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: context.subTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Header Banner ───────────────────────────────────────────────────
  Widget _buildMobileHeaderBanner(BuildContext context, double topInset) {
    return Container(
      height: 190 + topInset,
      padding: EdgeInsets.only(top: topInset),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A2F), Color(0xFFF2693F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 20,
            bottom: 0,
            child: Image.asset(
              'assets/images/vendor-login-rabbit.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
          Positioned(
            top: 0,
            left: 4,
            right: 4,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _navigateBack,
                ),
                const Expanded(
                  child: Text(
                    'Review Booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            left: 20,
            top: 42,
            right: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking\nSummary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review your booking details before you proceed to pay.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryCard() {
    final title = widget.ground['title'] as String? ?? 'Sports Ground';
    final location =
        (widget.ground['address'] ??
                widget.ground['location'] ??
                'Madhapur, Hyderabad')
            .toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: context.borderColor, height: 28),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFFFF5200),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMM d, yyyy').format(widget.date),
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFFFF5200),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.startTime} → ${widget.endTime}',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF2C1A14)
                      : const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFFFF5200),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.durationStr,
                      style: const TextStyle(
                        color: Color(0xFFFF5200),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child:
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5200).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: Color(0xFFFF5200),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Payment Processing...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We are confirming your payment with Razorpay. Please do not close or refresh this page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: 250.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  Widget _buildSecuredBadge() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 13, color: Color(0xFFFF5200)),
          const SizedBox(width: 4),
          Text(
            'Secured by ',
            style: TextStyle(color: context.subTextColor, fontSize: 12),
          ),
          const Text(
            'Razorpay',
            style: TextStyle(
              color: Color(0xFFFF5200),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return TouchableOpacity(
      onTap: _isCreatingOrder ? null : _startPayment,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5200),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5200).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            if (_isCreatingOrder)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              Text(
                'Pay ₹$_displayTotal',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            const Spacer(),
            if (!_isCreatingOrder)
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptedFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 14,
            color: Color(0xFFFF5200),
          ),
          const SizedBox(width: 6),
          Text(
            'Your payment is secure and encrypted',
            style: TextStyle(color: context.subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

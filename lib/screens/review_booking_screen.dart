import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
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
        'prefill': {
          'contact': AuthService.currentUser?.phoneNumber ?? '',
        },
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
          content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      String paymentId, String orderId, String signature) async {
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
            finalPrice: widget.finalPrice,
          ),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        content: Text('Payment Failed: $message', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            finalPrice: widget.finalPrice,
          ),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        content: Text('Payment Failed: ${response.message}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // 1. Top Header Banner
                    _buildHeaderBanner(context, topInset),

                    const SizedBox(height: 16),

                    // 2. Summary Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSummaryCard().animate().fade(delay: 100.ms).slideY(begin: 0.1),
                    ),

                    const SizedBox(height: 16),

                    // 3. Payment Details Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPaymentCard().animate().fade(delay: 200.ms).slideY(begin: 0.1),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Full-screen Payment Processing Overlay
          if (_isVerifyingPayment)
            Positioned.fill(
              child: _buildProcessingOverlay(),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: context.bgColor,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Your payment is secure and encrypted text
              _buildEncryptedFooter().animate().fade(delay: 300.ms),
              const SizedBox(height: 10),

              // 2. Pay button
              _buildPayButton().animate().fade(delay: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 10),

              // 3. Secured by Razorpay text
              _buildSecuredBadge().animate().fade(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Container(
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
                color: const Color(0xFFF2693F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3.5,
                color: Color(0xFFF2693F),
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
      ).animate().fade(duration: 250.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, double topInset) {
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
          // Mascot Rabbit Image anchored strictly inside top right of banner
          Positioned(
            right: 0,
            top: 20,
            bottom: 0,
            child: Image.asset(
              'assets/images/rabbit_support_half.png',
              fit: BoxFit.contain,
            ),
          ),

          // App Bar Back Button & Title
          Positioned(
            top: 0,
            left: 4,
            right: 4,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
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

          // Booking Summary Heading & Subtitle (constrained to left side so NO overlap with rabbit)
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

  Widget _buildSummaryCard() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2693F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ground['title'],
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.ground['address']?.toString().isNotEmpty == true ? widget.ground['address'] : widget.ground['location']}',
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: context.borderColor, height: 28),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFFF2693F), size: 18),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(widget.date),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Color(0xFFF2693F), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.startTime} - ${widget.endTime}',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF2C1A14) : const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFF2693F), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.durationStr,
                      style: const TextStyle(
                        color: Color(0xFFF2693F),
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

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              color: context.textColor,
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ground Fare', style: TextStyle(color: context.subTextColor, fontSize: 14.5)),
              Text('₹${widget.fare}', style: TextStyle(color: context.textColor, fontSize: 14.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform Fee', style: TextStyle(color: context.subTextColor, fontSize: 14.5)),
              Text('₹${widget.platformFee}', style: TextStyle(color: context.textColor, fontSize: 14.5, fontWeight: FontWeight.w600)),
            ],
          ),
          Divider(color: context.borderColor, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total to Pay', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '₹${widget.finalPrice}',
                style: const TextStyle(color: Color(0xFFF2693F), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuredBadge() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 13, color: Color(0xFFFF7A2F)),
          const SizedBox(width: 4),
          Text(
            'Secured by ',
            style: TextStyle(color: context.subTextColor, fontSize: 12),
          ),
          const Text(
            'Razorpay',
            style: TextStyle(color: Color(0xFFFF7A2F), fontWeight: FontWeight.bold, fontSize: 12),
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
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A2F),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A2F).withValues(alpha: 0.35),
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
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            else
              Text(
                'Pay ₹${widget.finalPrice}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            const Spacer(),
            if (!_isCreatingOrder)
              const Icon(Icons.chevron_right, color: Colors.white, size: 22),
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
          const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFFFF7A2F)),
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

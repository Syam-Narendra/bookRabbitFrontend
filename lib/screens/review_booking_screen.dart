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
        'theme': {'color': '#E54F3F'},
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFD32F2F),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFD32F2F),
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
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        title: Text('Review Booking', style: TextStyle(color: context.textColor)),
        iconTheme: IconThemeData(color: context.textColor),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32.0 : 24.0,
                  vertical: 24.0,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Summary', style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold))
                          .animate().fade(duration: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      _buildSummaryCard().animate().fade(delay: 100.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      Text('Payment Details', style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold))
                          .animate().fade(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      _buildPaymentCard().animate().fade(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Secured by ',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            children: [
                              TextSpan(
                                text: 'Razorpay',
                                style: TextStyle(color: Color(0xFF3395FF), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(delay: 400.ms),
                      const SizedBox(height: 12),
                      TouchableOpacity(
                        onTap: _isCreatingOrder ? null : _startPayment,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE54F3F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: _isCreatingOrder
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text('Pay ₹${widget.finalPrice}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.ground['title'], style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${widget.ground['address']?.toString().isNotEmpty == true ? widget.ground['address'] : widget.ground['location']}', style: TextStyle(color: context.subTextColor, fontSize: 14)),
          Divider(color: context.borderColor, height: 24),
          _buildIconDetail(Icons.calendar_today, DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconDetail(Icons.access_time, '${widget.startTime} - ${widget.endTime}'),
              _buildIconDetail(Icons.timer, widget.durationStr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ground Fare', style: TextStyle(color: context.subTextColor, fontSize: 16)),
              Text('₹${widget.fare}', style: TextStyle(color: context.textColor, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform Fee', style: TextStyle(color: context.subTextColor, fontSize: 16)),
              Text('₹${widget.platformFee}', style: TextStyle(color: context.textColor, fontSize: 16)),
            ],
          ),
          Divider(color: context.borderColor, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total to Pay', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('₹${widget.finalPrice}', style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE54F3F), size: 18),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/vendor_models.dart';
import '../../services/api_client.dart';
import '../../services/vendor_auth_service.dart';
import '../../services/razorpay_web/razorpay_web_helper.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Billing: per-ground subscription status, payment history, and
/// activate/cancel subscription actions.
class VendorBillingPage extends StatefulWidget {
  final VendorDashboard dashboard;
  final Future<void> Function() onRefresh;

  const VendorBillingPage({
    super.key,
    required this.dashboard,
    required this.onRefresh,
  });

  @override
  State<VendorBillingPage> createState() => _VendorBillingPageState();
}

class _VendorBillingPageState extends State<VendorBillingPage> {
  late Razorpay _razorpay;
  bool _processing = false;
  String? _pendingSubscriptionId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  VendorSubscription? _subscriptionFor(String groundId) {
    for (final s in widget.dashboard.subscriptions) {
      if (s.groundId == groundId) return s;
    }
    return null;
  }

  List<VendorSubscriptionTransaction> _transactionsFor(String groundId) {
    return widget.dashboard.subTransactions
        .where((t) => t.groundId == groundId)
        .toList();
  }

  Future<void> _cancel(VendorGround ground) async {
    final sub = _subscriptionFor(ground.id);
    if (sub == null || sub.status == 'lifetime_free') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Plan'),
        content: Text('Are you sure you want to cancel the subscription for "${ground.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      await VendorAuthService.cancelSubscription(ground.id);
      await widget.onRefresh();
      if (!mounted) return;
      _toast('Subscription cancelled', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _activate(VendorGround ground) async {
    setState(() => _processing = true);
    try {
      final order = await VendorAuthService.createSubscriptionOrder(ground.id);
      _pendingSubscriptionId = order['subscriptionId'] as String?;
      final options = {
        'key': order['razorpayKeyId'],
        'subscription_id': _pendingSubscriptionId,
        'name': 'Book Rabbit',
        'description': 'Subscription — ${ground.name}',
        'prefill': {'contact': order['ownerPhone'] ?? ''},
        'theme': {'color': '#FF7A2F'},
      };
      if (kIsWeb) {
        launchRazorpayWebCheckout(
          options: options,
          onSuccess: (paymentId, orderId, signature) =>
              _verifyReactivation(paymentId, signature),
          onError: (code, message) => _onPaymentError(message),
        );
      } else {
        _razorpay.open(options);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _toast(e.message);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _verifyReactivation(response.paymentId!, response.signature!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onPaymentError(response.message ?? 'Payment was cancelled.');
  }

  Future<void> _verifyReactivation(String paymentId, String signature) async {
    try {
      await VendorAuthService.verifySubscriptionPayment(
        paymentId: paymentId,
        subscriptionId: _pendingSubscriptionId ?? '',
        signature: signature,
        addGround: false,
      );
      await widget.onRefresh();
      if (!mounted) return;
      _toast('Subscription activated successfully', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _toast(e.message);
    }
  }

  void _onPaymentError(String message) {
    if (!mounted) return;
    setState(() => _processing = false);
    _toast(message);
  }

  void _toast(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: success ? const Color(0xFF2E8443) : const Color(0xFFD32F2F),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final grounds = widget.dashboard.grounds;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Billing', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Subscription Management',
                  style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹499/month after trial',
                  style: TextStyle(color: context.subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                if (grounds.isEmpty)
                  VendorEmptyState(
                    icon: Icons.credit_card_outlined,
                    title: 'No grounds yet',
                    subtitle: 'Add a ground to manage its subscription.',
                  )
                else
                  ...grounds.map((g) => _buildGroundRow(g)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroundRow(VendorGround ground) {
    final sub = _subscriptionFor(ground.id);
    final status = sub?.status ?? 'none';
    final transactions = _transactionsFor(ground.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.subCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(ground.icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ground.name,
                        style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusLine(status, sub),
                        style: TextStyle(color: context.subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _SubscriptionStatusPill(status: status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (_canCancel(status))
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing ? null : () => _cancel(ground),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                if (_canActivate(status)) ...[
                  if (_canCancel(status)) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _processing ? null : () => _activate(ground),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8443),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Activate · ₹499'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (transactions.isNotEmpty) ...[
            Divider(color: context.borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment History',
                    style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...transactions.take(5).map((t) => _buildTxRow(t)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTxRow(VendorSubscriptionTransaction tx) {
    final paid = tx.status == 'paid';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle : Icons.cancel,
            color: paid ? const Color(0xFF2E8443) : const Color(0xFFD32F2F),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tx.period ?? '—',
              style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            formatInr(tx.amount),
            style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (paid ? const Color(0xFF2E8443) : const Color(0xFFD32F2F)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paid ? 'paid' : 'failed',
              style: TextStyle(
                color: paid ? const Color(0xFF2E8443) : const Color(0xFFD32F2F),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canCancel(String status) =>
      status == 'active' || status == 'trial';
  bool _canActivate(String status) =>
      status == 'none' || status == 'cancelled' || status == 'halted' || status == 'expired';

  String _statusLine(String status, VendorSubscription? sub) {
    switch (status) {
      case 'trial':
        return 'Free trial active — autopay starts ${_shortDate(sub?.trialEndsAt)}';
      case 'active':
        return 'Renews ${_shortDate(sub?.expiresAt)}';
      case 'cancelled':
        return 'Autopay cancelled — active until ${_shortDate(sub?.expiresAt)}';
      case 'halted':
        return 'Autopay halted';
      case 'pending':
        return 'Payment processing…';
      case 'lifetime_free':
        return 'Active forever — no billing, no expiry';
      default:
        return 'No active plan';
    }
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso.replaceFirst('Z', ''));
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return iso;
    }
  }
}

class _SubscriptionStatusPill extends StatelessWidget {
  final String status;
  const _SubscriptionStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'lifetime_free' => ('♾️ Lifetime Free', const Color(0xFF2E8443)),
      'active' => ('✓ Active', const Color(0xFF2E8443)),
      'trial' => ('🎉 Free Trial', const Color(0xFF7C3AED)),
      'cancelled' => ('✕ Cancelled', const Color(0xFFE11D48)),
      'halted' => ('🚨 Halted', const Color(0xFFE11D48)),
      'pending' => ('⋯ Pending', const Color(0xFF2E8443)),
      'expired' => ('Expired', const Color(0xFFF59E0B)),
      _ => ('No Plan', const Color(0xFF9CA3AF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

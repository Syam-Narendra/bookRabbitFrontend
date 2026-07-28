import 'razorpay_web_stub.dart'
    if (dart.library.js_interop) 'razorpay_web_impl.dart';

void launchRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required Function(String paymentId, String orderId, String signature) onSuccess,
  required Function(int code, String message) onError,
}) {
  openRazorpayWeb(
    options: options,
    onSuccess: onSuccess,
    onError: onError,
  );
}

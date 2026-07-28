void openRazorpayWeb({
  required Map<String, dynamic> options,
  required Function(String paymentId, String orderId, String signature) onSuccess,
  required Function(int code, String message) onError,
}) {
  throw UnsupportedError('Razorpay Web Checkout is only supported on Web platform');
}

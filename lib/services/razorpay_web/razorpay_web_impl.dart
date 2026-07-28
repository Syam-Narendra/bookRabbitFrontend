import 'dart:convert';
import 'dart:js_interop';

@JS('openRazorpayCheckout')
external void _jsOpenRazorpayCheckout(
  JSString optionsJson,
  JSFunction successCb,
  JSFunction errorCb,
);

void openRazorpayWeb({
  required Map<String, dynamic> options,
  required Function(String paymentId, String orderId, String signature) onSuccess,
  required Function(int code, String message) onError,
}) {
  final optionsJson = jsonEncode(options).toJS;

  final successJsCb = ((JSString paymentId, JSString orderId, JSString signature) {
    onSuccess(paymentId.toDart, orderId.toDart, signature.toDart);
  }).toJS;

  final errorJsCb = ((JSNumber code, JSString message) {
    onError(code.toDartInt, message.toDart);
  }).toJS;

  _jsOpenRazorpayCheckout(optionsJson, successJsCb, errorJsCb);
}

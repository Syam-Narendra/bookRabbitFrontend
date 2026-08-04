import 'package:http/http.dart' as http;

/// Native (iOS/Android/macOS/…) HTTP client. No cookie jar — the admin session
/// cookie is captured from `Set-Cookie` and re-sent as a `Cookie` header by
/// [ApiClient] (readable/settable on the VM, unlike in the browser).
http.Client createPlatformHttpClient() => http.Client();

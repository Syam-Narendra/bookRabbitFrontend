import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Browser HTTP client with `withCredentials` enabled so the browser
/// automatically stores the session cookie from `Set-Cookie` and re-sends it.
/// JS cannot read `Set-Cookie` or set the `Cookie` header, so the manual
/// cookie approach used on native cannot work on web.
http.Client createPlatformHttpClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}

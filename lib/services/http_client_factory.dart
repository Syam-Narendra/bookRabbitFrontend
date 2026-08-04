// Conditional import: web uses a credentialed BrowserClient (browser manages
// the session cookie); everything else uses the plain VM client (cookies are
// handled manually by ApiClient).
export 'http_client_factory_io.dart'
    if (dart.library.html) 'http_client_factory_web.dart';

// Conditional import: use web implementation on web, native on everything else.
export 'platform_storage_stub.dart'
    if (dart.library.html) 'platform_storage_web.dart'
    if (dart.library.io) 'platform_storage_native.dart';

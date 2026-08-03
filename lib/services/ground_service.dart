import 'api_client.dart';

class GroundService {
  GroundService._();

  static double? _feePctCache;
  static DateTime? _feePctCachedAt;

  /// Platform commission percent from server app-config (e.g. 7.0).
  /// Mirrors the backend default and the backend's 5-minute config cache.
  static Future<double> getPlatformCommissionPct() async {
    final now = DateTime.now();
    if (_feePctCache != null &&
        _feePctCachedAt != null &&
        now.difference(_feePctCachedAt!) < const Duration(minutes: 5)) {
      return _feePctCache!;
    }
    double pct = 7.0;
    try {
      final data = await ApiClient.get('/api/public/app-config') as Map<String, dynamic>;
      final config = data['config'] as Map<String, dynamic>? ?? {};
      final parsed = double.tryParse(config['platform_commission_pct']?.toString() ?? '');
      if (parsed != null && parsed > 0) pct = parsed;
    } catch (_) {
      // Keep the default; the next call retries after the cache window.
    }
    _feePctCache = pct;
    _feePctCachedAt = now;
    return pct;
  }

  static Future<List<Map<String, dynamic>>> fetchGrounds() async {
    final data = await ApiClient.get('/api/public/grounds') as Map<String, dynamic>;
    final grounds = data['grounds'] as List<dynamic>;

    return grounds.map<Map<String, dynamic>>((dynamic g) {
      final groundMap = g as Map<String, dynamic>;
      final images = groundMap['images'] as List<dynamic>? ?? [];
      return <String, dynamic>{
        ...groundMap,
        'title': groundMap['name'] ?? '',
        'location': groundMap['address'] ?? groundMap['city'] ?? '',
        'price': '₹${groundMap['price_per_hour']}/hr',
        'category': groundMap['type'] ?? 'All',
        'type': groundMap['tag'] ?? groundMap['type'] ?? '',
        'imageUrl': images.isNotEmpty ? images.first : 'assets/images/sports_bunnies.png',
      };
    }).toList();
  }

  /// Returns `{ bookedSegs: Set<String>, heldSegs: Set<String> }` — 24-hour
  /// "HH:MM" segment keys, mirroring select-time.tsx's bookedSegs/heldSegs.
  static Future<Map<String, Set<String>>> fetchSlotAvailability({
    required String groundId,
    required String date,
  }) async {
    final results = await Future.wait([
      ApiClient.get('/api/public/booked-slots?groundId=$groundId&date=$date'),
      ApiClient.get('/api/public/held-slots?groundId=$groundId&date=$date'),
    ]);
    final bookedData = results[0] as Map<String, dynamic>;
    final heldData = results[1] as Map<String, dynamic>;

    return {
      'bookedSegs': (bookedData['bookedSegs'] as List<dynamic>).cast<String>().toSet(),
      'heldSegs': (heldData['heldSegs'] as List<dynamic>).cast<String>().toSet(),
    };
  }
}

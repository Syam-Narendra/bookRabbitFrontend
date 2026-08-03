import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import '../models/vendor_models.dart';

/// Ground-owner ("vendor") session profile, as returned by the admin OTP-verify
/// and session-check endpoints. Separate from [AppUser] (the customer model) —
/// vendor auth uses a cookie session, not a bearer token.
class VendorOwner {
  final String id;
  final String phone;
  final String? ownerName;
  final bool hasBankDetails;

  const VendorOwner({
    required this.id,
    required this.phone,
    this.ownerName,
    this.hasBankDetails = false,
  });

  factory VendorOwner.fromJson(Map<String, dynamic> json) {
    return VendorOwner(
      id: json['id'].toString(),
      phone: (json['phone'] ?? json['ownerPhone']).toString(),
      ownerName: json['owner_name'] as String?,
      hasBankDetails: (json['has_bank_details'] ?? json['hasBankDetails'] ?? false) as bool,
    );
  }
}

class VendorAuthService {
  VendorAuthService._();

  static VendorOwner? currentOwner;

  /// Sends an OTP to a registered owner. Returns the echoed OTP when the
  /// backend runs with DEV_OTP_ECHO enabled (dev/stage only — null in prod).
  static Future<String?> sendOtp(String phone) async {
    final data = await ApiClient.adminPost('/api/admin/otp-send', body: {'phone': phone}) as Map<String, dynamic>;
    return data['otp'] as String?;
  }

  static Future<VendorOwner> verifyOtp(String phone, String otp) async {
    final data = await ApiClient.adminPost(
      '/api/admin/otp-verify',
      body: {'phone': phone, 'otp': otp},
    ) as Map<String, dynamic>;

    final owner = VendorOwner.fromJson(data['owner'] as Map<String, dynamic>);
    currentOwner = owner;
    return owner;
  }

  /// Discards the current OTP (used by "change number" on the login screen).
  static Future<void> invalidateOtp(String phone) async {
    await ApiClient.adminDelete('/api/admin/otp-invalidate', body: {'phone': phone});
  }

  /// Called at app boot / dashboard load to validate the admin cookie is still live.
  static Future<VendorOwner> fetchSession() async {
    final data = await ApiClient.adminGet('/api/admin/session') as Map<String, dynamic>;
    final owner = VendorOwner(
      id: data['ownerId'].toString(),
      phone: data['ownerPhone'].toString(),
      hasBankDetails: data['hasBankDetails'] as bool? ?? false,
    );
    currentOwner = owner;
    return owner;
  }

  /// Full dashboard payload: owner profile, grounds (+bookings), subscriptions,
  /// subscription transactions, bank account and revenue totals.
  static Future<VendorDashboard> fetchDashboard() async {
    final data = await ApiClient.adminGet('/api/admin/stats') as Map<String, dynamic>;
    return VendorDashboard.fromJson(data);
  }

  /// Whether new grounds require a paid subscription (vs. free mode).
  static Future<bool> fetchIsSubscriptionNeeded() async {
    final data = await ApiClient.adminGet('/api/admin/app-config') as Map<String, dynamic>;
    return data['isSubscriptionNeeded'] as bool? ?? true;
  }

  // ── Ground management ──────────────────────────────────────────────────────

  static const List<String> groundTypes = [
    'Cricket', 'Football', 'Badminton', 'Tennis', 'Basketball',
    'Volleyball', 'Table Tennis', 'Squash', 'Hockey',
  ];

  static const Map<String, String> groundIcons = {
    'Cricket': '🏏',
    'Football': '⚽',
    'Badminton': '🏸',
    'Tennis': '🎾',
    'Basketball': '🏀',
    'Volleyball': '🏐',
    'Table Tennis': '🏓',
    'Squash': '🎱',
    'Hockey': '🏑',
  };

  /// Creates a ground. In free mode the ground is created + activated server-side
  /// and this returns immediately. In paid mode it returns the Razorpay
  /// subscription order data which the caller uses to open checkout, then calls
  /// [verifySubscriptionPayment] with the resulting payment ids.
  static Future<Map<String, dynamic>> createGround({
    required String name,
    required String groundType,
    required String address,
    required int pricePerHour,
    required String openTime,
    required String closeTime,
    required List<String> operatingDays,
    String? city,
    String? pincode,
    String? mapsUrl,
  }) async {
    final data = await ApiClient.adminPost('/api/admin/ground-order', body: {
      'name': name,
      'groundType': groundType,
      'address': address,
      'pricePerHour': pricePerHour,
      'openTime': openTime,
      'closeTime': closeTime,
      'operatingDays': operatingDays,
      'city': ?city,
      'pincode': ?pincode,
      'mapsUrl': ?mapsUrl,
    }) as Map<String, dynamic>;
    return data;
  }

  static Future<void> updateGround({
    required String groundId,
    required String name,
    required String groundType,
    required String address,
    required int pricePerHour,
    required String openTime,
    required String closeTime,
    required List<String> operatingDays,
  }) async {
    await ApiClient.adminPost('/api/admin/settings', body: {
      'type': 'ground',
      'groundId': groundId,
      'name': name,
      'groundType': groundType,
      'icon': VendorAuthService.groundIcons[groundType] ?? '🏟️',
      'address': address,
      'pricePerHour': pricePerHour,
      'openTime': openTime,
      'closeTime': closeTime,
      'operatingDays': operatingDays,
    });
  }

  static Future<void> uploadGroundImages(String groundId, List<XFile> files) async {
    for (final file in files) {
      await ApiClient.adminUploadBytes(
        '/api/admin/ground-images',
        bytes: await file.readAsBytes(),
        filename: file.name,
        fields: {'groundId': groundId},
      );
    }
  }

  static Future<void> deleteGroundImage(String groundId, String imageUrl) async {
    await ApiClient.adminDelete('/api/admin/ground-images', body: {
      'groundId': groundId,
      'imageUrl': imageUrl,
    });
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  static Future<void> updateProfile(String ownerName) async {
    await ApiClient.adminPost('/api/admin/settings', body: {
      'type': 'profile',
      'ownerName': ownerName,
    });
  }

  static Future<void> updateBankDetails({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifscCode,
  }) async {
    await ApiClient.adminPost('/api/admin/settings', body: {
      'type': 'bank',
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'confirmAccountNumber': confirmAccountNumber,
      'ifscCode': ifscCode,
    });
  }

  static Future<void> cancelSubscription(String groundId) async {
    await ApiClient.adminPost('/api/admin/settings', body: {
      'type': 'subscription-cancel',
      'groundId': groundId,
    });
  }

  /// Creates a new Razorpay subscription for an existing ground (reactivation
  /// after cancel/expiry). Returns the checkout order data.
  static Future<Map<String, dynamic>> createSubscriptionOrder(String groundId) async {
    final data = await ApiClient.adminPost(
      '/api/admin/subscription-order',
      body: {'groundId': groundId},
    ) as Map<String, dynamic>;
    return data;
  }

  // ── Sessions / devices ─────────────────────────────────────────────────────

  static Future<List<VendorSession>> fetchSessions() async {
    final data = await ApiClient.adminGet('/api/admin/sessions') as Map<String, dynamic>;
    return (data['sessions'] as List<dynamic>? ?? [])
        .map((e) => VendorSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [type] is "logout-session" (with [sessionId]) or "logout-everywhere".
  /// Returns true if the current session was logged out.
  static Future<bool> manageSession(String type, {String? sessionId}) async {
    final data = await ApiClient.adminPost('/api/admin/sessions', body: {
      'type': type,
      'sessionId': ?sessionId,
    }) as Map<String, dynamic>;
    final loggedOutCurrent = data['loggedOutCurrentSession'] as bool? ?? false;
    if (loggedOutCurrent || type == 'logout-everywhere') {
      currentOwner = null;
      await ApiClient.clearAdminCookie();
    }
    return loggedOutCurrent || type == 'logout-everywhere';
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  /// Verifies a Razorpay subscription payment (add-ground / reactivation).
  /// [addGround] marks the flow as add-ground vs. reactivation. Images are
  /// attached as multipart files. The response sets the admin cookie.
  static Future<void> verifySubscriptionPayment({
    required String paymentId,
    required String subscriptionId,
    required String signature,
    required bool addGround,
    List<XFile>? images,
  }) async {
    final files = <http.MultipartFile>[];
    for (final file in images ?? []) {
      final ext = file.name.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      files.add(http.MultipartFile.fromBytes(
        'images',
        await file.readAsBytes(),
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      ));
    }
    await ApiClient.publicUpload(
      '/api/public/payment-verify',
      fields: {
        'razorpay_payment_id': paymentId,
        'razorpay_subscription_id': subscriptionId,
        'razorpay_signature': signature,
        'add_ground': addGround ? 'true' : 'false',
        'reactivation': addGround ? 'false' : 'true',
      },
      files: files.isEmpty ? null : files,
    );
  }

  // ── Session lifecycle ──────────────────────────────────────────────────────

  static Future<void> logout() async {
    try {
      // Returns a 302 redirect, not JSON — best-effort, ignore the response.
      await ApiClient.adminGet('/api/admin/logout');
    } catch (_) {
      // Best-effort — clear local state regardless.
    }
    currentOwner = null;
    await ApiClient.clearAdminCookie();
  }
}

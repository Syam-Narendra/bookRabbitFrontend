import 'api_client.dart';

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

  static Future<void> sendOtp(String phone) async {
    await ApiClient.adminPost('/api/admin/otp-send', body: {'phone': phone});
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

  static Future<Map<String, dynamic>> fetchStats() async {
    return await ApiClient.adminGet('/api/admin/stats') as Map<String, dynamic>;
  }

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

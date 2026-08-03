/// Data models for the vendor (ground-owner) dashboard.
/// Mirrors the response shapes of the backend /api/admin endpoints and the
/// Remix legacy admin dashboard types.
library;

/// Ground owned by a vendor, with its embedded bookings (from /api/admin/stats).
class VendorGround {
  final String id;
  final String name;
  final String type;
  final String icon;
  final int pricePerHour;
  final String status;
  final String address;
  final String? city;
  final String? pincode;
  final String? mapsUrl;
  final String? openTime;
  final String? closeTime;
  final List<String> operatingDays;
  final List<String> images;
  final String? createdAt;
  final List<VendorBooking> bookings;

  const VendorGround({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.pricePerHour,
    required this.status,
    required this.address,
    this.city,
    this.pincode,
    this.mapsUrl,
    this.openTime,
    this.closeTime,
    this.operatingDays = const [],
    this.images = const [],
    this.createdAt,
    this.bookings = const [],
  });

  factory VendorGround.fromJson(Map<String, dynamic> json) {
    return VendorGround(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? '🏟️',
      pricePerHour: (json['price_per_hour'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'pending',
      address: (json['address'] as String?) ?? '',
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      mapsUrl: json['maps_url'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      operatingDays: (json['operating_days'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      images: (json['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdAt: json['created_at'] as String?,
      bookings: (json['bookings'] as List<dynamic>? ?? [])
          .map((e) => VendorBooking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isActive => status == 'active';
  int get confirmedBookings => bookings.where((b) => b.status == 'confirmed').length;
  double get revenue => bookings
      .where((b) => b.status == 'confirmed')
      .fold(0.0, (sum, b) => sum + b.amount);
}

/// A single booking row returned inside a ground in /api/admin/stats.
class VendorBooking {
  final String id;
  final String groundId;
  final double amount;
  final String? date;
  final String status;
  final String? userName;
  final String? userPhone;
  final String? startTime;
  final String? endTime;
  final String? referenceId;
  final String? createdAt;

  const VendorBooking({
    required this.id,
    required this.groundId,
    required this.amount,
    this.date,
    this.status = 'confirmed',
    this.userName,
    this.userPhone,
    this.startTime,
    this.endTime,
    this.referenceId,
    this.createdAt,
  });

  factory VendorBooking.fromJson(Map<String, dynamic> json) {
    return VendorBooking(
      id: json['id']?.toString() ?? '',
      groundId: json['ground_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: json['date'] as String?,
      status: (json['status'] as String?) ?? 'confirmed',
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      referenceId: json['reference_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isConfirmed => status == 'confirmed';
}

/// Subscription record per ground (from /api/admin/stats -> subscriptions).
class VendorSubscription {
  final String groundId;
  final String status;
  final String? expiresAt;
  final double amount;
  final String? trialEndsAt;

  const VendorSubscription({
    required this.groundId,
    required this.status,
    this.expiresAt,
    this.amount = 0,
    this.trialEndsAt,
  });

  factory VendorSubscription.fromJson(Map<String, dynamic> json) {
    return VendorSubscription(
      groundId: json['ground_id']?.toString() ?? '',
      status: (json['status'] as String?) ?? 'none',
      expiresAt: json['expires_at'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      trialEndsAt: json['trial_ends_at'] as String?,
    );
  }
}

/// Subscription payment transaction (from /api/admin/stats -> subTransactions).
class VendorSubscriptionTransaction {
  final String id;
  final String? groundId;
  final String? subscriptionId;
  final double amount;
  final String? period;
  final String status;
  final String? paidAt;

  const VendorSubscriptionTransaction({
    required this.id,
    this.groundId,
    this.subscriptionId,
    this.amount = 0,
    this.period,
    this.status = 'paid',
    this.paidAt,
  });

  factory VendorSubscriptionTransaction.fromJson(Map<String, dynamic> json) {
    return VendorSubscriptionTransaction(
      id: json['id']?.toString() ?? '',
      groundId: json['ground_id']?.toString(),
      subscriptionId: json['subscription_id']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      period: json['period'] as String?,
      status: (json['status'] as String?) ?? 'paid',
      paidAt: json['paid_at'] as String?,
    );
  }
}

/// Owner bank account (from /api/admin/stats -> bankAccount).
class VendorBankAccount {
  final String? id;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? email;
  final String? payoutActivationStatus;
  final dynamic payoutRequirements;

  const VendorBankAccount({
    this.id,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
    this.email,
    this.payoutActivationStatus,
    this.payoutRequirements,
  });

  factory VendorBankAccount.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VendorBankAccount();
    return VendorBankAccount(
      id: json['id']?.toString(),
      accountHolderName: json['account_holder_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      bankName: json['bank_name'] as String?,
      email: json['email'] as String?,
      payoutActivationStatus: json['payout_activation_status'] as String?,
      payoutRequirements: json['payout_requirements'],
    );
  }

  bool get exists => accountHolderName != null;
  bool get isVerified =>
      payoutActivationStatus != null &&
      (payoutActivationStatus!.toLowerCase() == 'active' ||
          payoutActivationStatus!.toLowerCase() == 'activated');
}

/// Active admin session (from /api/admin/sessions).
class VendorSession {
  final String id;
  final String? ownerId;
  final String? ownerPhone;
  final String? ua;
  final String? ip;
  final String? createdAt;
  final String? lastSeen;
  final bool isCurrentSession;

  const VendorSession({
    required this.id,
    this.ownerId,
    this.ownerPhone,
    this.ua,
    this.ip,
    this.createdAt,
    this.lastSeen,
    this.isCurrentSession = false,
  });

  factory VendorSession.fromJson(Map<String, dynamic> json) {
    return VendorSession(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? json['owner_id']?.toString(),
      ownerPhone: json['ownerPhone']?.toString() ?? json['owner_phone']?.toString(),
      ua: json['ua'] as String?,
      ip: json['ip'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      lastSeen: json['lastSeen'] as String? ?? json['last_seen'] as String?,
      isCurrentSession: (json['isCurrentSession'] as bool?) ?? false,
    );
  }
}

/// Full dashboard payload returned by GET /api/admin/stats.
class VendorDashboard {
  final List<VendorGround> grounds;
  final List<VendorSubscription> subscriptions;
  final List<VendorSubscriptionTransaction> subTransactions;
  final Map<String, dynamic>? owner;
  final VendorBankAccount bankAccount;
  final double totalRevenue;
  final int totalBookings;

  const VendorDashboard({
    this.grounds = const [],
    this.subscriptions = const [],
    this.subTransactions = const [],
    this.owner,
    this.bankAccount = const VendorBankAccount(),
    this.totalRevenue = 0,
    this.totalBookings = 0,
  });

  factory VendorDashboard.fromJson(Map<String, dynamic> json) {
    return VendorDashboard(
      grounds: (json['grounds'] as List<dynamic>? ?? [])
          .map((e) => VendorGround.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>? ?? [])
          .map((e) => VendorSubscription.fromJson(e as Map<String, dynamic>))
          .toList(),
      subTransactions: (json['subTransactions'] as List<dynamic>? ?? [])
          .map((e) => VendorSubscriptionTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      owner: json['owner'] as Map<String, dynamic>?,
      bankAccount: VendorBankAccount.fromJson(json['bankAccount'] as Map<String, dynamic>?),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
    );
  }

  List<VendorBooking> get allBookings {
    final bookings = <VendorBooking>[];
    for (final g in grounds) {
      for (final b in g.bookings) {
        bookings.add(b);
      }
    }
    return bookings;
  }

  List<VendorBooking> get confirmedBookings =>
      allBookings.where((b) => b.isConfirmed).toList();
}

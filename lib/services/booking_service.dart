import 'package:intl/intl.dart';
import 'api_client.dart';

class BookingOrder {
  final String orderId;
  final String razorpayKeyId;
  final double totalAmount;
  final double baseAmount;
  final double platformFee;
  final String groundName;
  final String holdId;

  const BookingOrder({
    required this.orderId,
    required this.razorpayKeyId,
    required this.totalAmount,
    required this.baseAmount,
    required this.platformFee,
    required this.groundName,
    required this.holdId,
  });

  factory BookingOrder.fromJson(Map<String, dynamic> json) {
    return BookingOrder(
      orderId: json['orderId'] as String,
      razorpayKeyId: json['razorpayKeyId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      baseAmount: (json['baseAmount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      groundName: json['groundName'] as String,
      holdId: json['holdId'] as String,
    );
  }
}

class BookingService {
  BookingService._();

  static Future<BookingOrder> createOrder({
    required String groundId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final data = await ApiClient.post('/api/public/booking-order', body: {
      'groundId': groundId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
    }) as Map<String, dynamic>;
    return BookingOrder.fromJson(data);
  }

  static Future<String?> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final data = await ApiClient.post('/api/public/booking-payment-verify', body: {
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    }) as Map<String, dynamic>;
    return data['referenceId'] as String?;
  }

  static Future<void> releaseSlot({
    required String groundId,
    required String date,
    required String startTime,
    required String endTime,
    required String holdId,
  }) async {
    try {
      await ApiClient.post('/api/public/booking-release', body: {
        'groundId': groundId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'holdId': holdId,
      });
    } catch (_) {
      // Best-effort — the hold will expire on its own via Redis TTL.
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    final data = await ApiClient.get('/api/mobile/bookings') as Map<String, dynamic>;
    final bookings = data['bookings'] as List<dynamic>;
    final now = DateTime.now();

    return bookings.map<Map<String, dynamic>>((dynamic b) {
      final row = b as Map<String, dynamic>;
      final date = DateTime.parse(row['date'] as String);
      final startTime = row['start_time'] as String;
      final endTime = row['end_time'] as String;
      final images = row['images'] as List<dynamic>? ?? [];
      // amount/platform_fee are Postgres `numeric` columns, serialized as
      // strings by the backend to avoid float precision loss — parse them.
      final amount = num.parse(row['amount'].toString());
      final platformFee = num.parse(row['platform_fee'].toString());
      final total = amount + platformFee;

      final endParts = endTime.split(':');
      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      final startParts = startTime.split(':');
      final startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final durationMins = endMins > startMins ? endMins - startMins : (endMins + 1440) - startMins;
      final durationHours = durationMins / 60;

      String status;
      if (row['status'] == 'cancelled') {
        status = 'Cancelled';
      } else if (endDateTime.isAfter(now)) {
        status = 'Upcoming';
      } else {
        status = 'Completed';
      }

      final createdAtRaw = row['created_at'];
      String bookedOn = '';
      if (createdAtRaw != null) {
        try {
          final created = DateTime.parse(createdAtRaw.toString()).toLocal();
          bookedOn = DateFormat('d MMM yyyy, h:mm a').format(created);
        } catch (_) {
          bookedOn = '';
        }
      }

      return <String, dynamic>{
        'title': row['ground_name'] ?? '',
        'type': row['tag'] ?? row['type'] ?? '',
        'date': DateFormat('d MMM yyyy, E').format(date),
        'time': '${_to12Hour(startTime)} – ${_to12Hour(endTime)}',
        'price': '₹${total.round()}',
        'status': status,
        'imageUrl': images.isNotEmpty ? images.first : 'assets/images/sports_bunnies.png',
        // Extra detail fields for the booking-detail screen (not shown on the card).
        'referenceId': row['reference_id'] ?? '',
        'address': row['address'] ?? '',
        'city': row['city'] ?? '',
        'images': images,
        'fare': amount,
        'platformFee': platformFee,
        'totalAmount': total,
        'durationHours': durationHours,
        'bookedOn': bookedOn,
        'transactionId': row['razorpay_payment_id'] ?? '',
      };
    }).toList();
  }

  /// Aggregate stats for the Account tab, computed from the same booking
  /// list `fetchMyBookings()` returns — no separate backend endpoint needed.
  static Map<String, num> computeStats(List<Map<String, dynamic>> bookings) {
    final playedOrUpcoming = bookings.where((b) => b['status'] != 'Cancelled');
    final totalHours = playedOrUpcoming.fold<double>(
      0,
      (sum, b) => sum + (b['durationHours'] as num).toDouble(),
    );

    return {
      'games': playedOrUpcoming.length,
      'hours': totalHours,
      'upcoming': bookings.where((b) => b['status'] == 'Upcoming').length,
    };
  }

  static String _to12Hour(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}

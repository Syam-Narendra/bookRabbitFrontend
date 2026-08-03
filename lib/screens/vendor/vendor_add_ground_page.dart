import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_client.dart';
import '../../services/vendor_auth_service.dart';
import '../../services/razorpay_web/razorpay_web_helper.dart';
import '../../theme/app_theme.dart';
import '../vendor/vendor_helpers.dart';

/// Full-screen add-ground flow: details step → images/payment step.
/// In free mode the ground is created and activated server-side immediately;
/// in paid mode a Razorpay subscription checkout opens after details are saved.
class VendorAddGroundPage extends StatefulWidget {
  const VendorAddGroundPage({super.key});

  @override
  State<VendorAddGroundPage> createState() => _VendorAddGroundPageState();
}

class _VendorAddGroundPageState extends State<VendorAddGroundPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  int _step = 1;

  String _groundType = 'Cricket';
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  final Set<String> _operatingDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};

  List<XFile> _images = [];
  bool _isSubmitting = false;
  bool? _isSubscriptionNeeded;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _loadAppConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadAppConfig() async {
    try {
      final needed = await VendorAuthService.fetchIsSubscriptionNeeded();
      if (!mounted) return;
      setState(() => _isSubscriptionNeeded = needed);
    } catch (_) {
      if (mounted) setState(() => _isSubscriptionNeeded = true);
    }
  }

  String _to24h(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isOpen}) async {
    final initial = isOpen ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: context.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _openTime = picked;
      } else {
        _closeTime = picked;
      }
    });
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      limit: 6 - _images.length,
    );
    if (picked.isEmpty) return;
    setState(() => _images = [..._images, ...picked].take(6).toList());
  }

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Ground name is required.');
      return false;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showError('Enter a valid price per hour.');
      return false;
    }
    if (_openTime.hour == _closeTime.hour && _openTime.minute == _closeTime.minute) {
      _showError('Opening and closing times must differ.');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError('Ground address is required.');
      return false;
    }
    final city = _cityController.text.trim();
    if (city.isNotEmpty && !RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ]*$').hasMatch(city)) {
      _showError('City may only contain letters, numbers and spaces.');
      return false;
    }
    final pincode = _pincodeController.text.trim();
    if (pincode.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _showError('PIN code must be 6 digits.');
      return false;
    }
    if (_operatingDays.isEmpty) {
      _showError('Select at least one operating day.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final order = await VendorAuthService.createGround(
        name: _nameController.text.trim(),
        groundType: _groundType,
        address: _addressController.text.trim(),
        pricePerHour: int.tryParse(_priceController.text.trim()) ?? 500,
        openTime: _to24h(_openTime),
        closeTime: _to24h(_closeTime),
        operatingDays: _operatingDays.toList(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
      );

      final groundId = order['groundId'] as String?;
      final freeMode = order['freeMode'] == true;

      if (freeMode || order['subscriptionId'] == null) {
        if (groundId != null && _images.isNotEmpty) {
          await VendorAuthService.uploadGroundImages(groundId, _images);
        }
        if (!mounted) return;
        _showSuccess('Ground added & activated successfully');
        Navigator.of(context).pop(true);
        return;
      }

      // Paid: open Razorpay subscription checkout.
      final options = {
        'key': order['razorpayKeyId'],
        'subscription_id': order['subscriptionId'],
        'name': 'Book Rabbit',
        'description': 'Ground Subscription — ₹499/month',
        'prefill': {
          'contact': order['ownerPhone'] ?? '',
        },
        'theme': {'color': '#FF7A2F'},
      };

      if (kIsWeb) {
        launchRazorpayWebCheckout(
          options: options,
          onSuccess: (paymentId, orderId, signature) =>
              _verifyPayment(paymentId, signature, addGround: true),
          onError: (code, message) => _onPaymentError(message),
        );
      } else {
        _razorpay.open(options);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Failed to create ground. Please try again.');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _verifyPayment(
      response.paymentId!,
      response.signature!,
      addGround: true,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onPaymentError(response.message ?? 'Payment was cancelled.');
  }

  Future<void> _verifyPayment(String paymentId, String signature, {required bool addGround}) async {
    try {
      await VendorAuthService.verifySubscriptionPayment(
        paymentId: paymentId,
        subscriptionId: '',
        signature: signature,
        addGround: addGround,
        images: _images,
      );
      if (!mounted) return;
      _showSuccess('Ground added & activated successfully');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(e.message);
    }
  }

  void _onPaymentError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showError(message);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFD32F2F),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF2E8443),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Add Ground', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StepIndicator(current: _step),
                const SizedBox(height: 20),
                if (_step == 1) _buildDetailsStep() else _buildImagesStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ground Details', style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Ground Name', 'e.g. Alpha Cricket Arena', icon: Icons.stadium_outlined),
        const SizedBox(height: 14),
        _buildTypeDropdown(),
        const SizedBox(height: 14),
        _buildTextField(
          _priceController,
          'Price per Hour (₹)',
          'e.g. 600',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTimeField('Opens At', _openTime, isOpen: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField('Closes At', _closeTime, isOpen: false),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Operating Days', style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in kAllDays)
              GestureDetector(
                onTap: () => setState(() {
                  if (_operatingDays.contains(day)) {
                    _operatingDays.remove(day);
                  } else {
                    _operatingDays.add(day);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _operatingDays.contains(day)
                        ? const Color(0xFFFF7B42)
                        : context.subCardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: _operatingDays.contains(day) ? Colors.white : context.subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _buildTextField(_addressController, 'Ground Address', 'Full address', icon: Icons.location_on_outlined, maxLines: 2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _cityController,
                'City',
                'City',
                icon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _pincodeController,
                'PIN Code',
                '6-digit',
                icon: Icons.pin,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (!_validateStep1()) return;
                    setState(() => _step = 2);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7B42),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Next: Images →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesStep() {
    final subscriptionNeeded = _isSubscriptionNeeded ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: subscriptionNeeded
                ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
                : const Color(0xFF2E8443).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                subscriptionNeeded ? Icons.card_membership : Icons.celebration,
                color: subscriptionNeeded ? const Color(0xFF7C3AED) : const Color(0xFF2E8443),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subscriptionNeeded
                      ? 'A ₹499/month subscription applies after a free trial. Razorpay checkout will open on submit.'
                      : 'Free — No payment needed for listing your ground.',
                  style: TextStyle(color: context.textColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Ground Photos', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Optional · up to 6 images', style: TextStyle(color: context.subTextColor, fontSize: 12)),
        const SizedBox(height: 12),
        if (_images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _images.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _images[i].path,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          color: context.subCardBg,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (_images.length < 6) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: context.subCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: context.subTextColor),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add photos (PNG / JPG)',
                    style: TextStyle(color: context.subTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textColor,
                side: BorderSide(color: context.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('← Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7B42),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          subscriptionNeeded ? 'Pay ₹499 & Add →' : 'Add Ground Free →',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    IconData? icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: maxLength == null ? null : null,
      style: TextStyle(color: context.textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: context.subTextColor) : null,
        filled: true,
        fillColor: context.subCardBg,
        hintStyle: TextStyle(color: context.subTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7B42)),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _groundType,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: context.subTextColor),
          dropdownColor: context.cardBg,
          style: TextStyle(color: context.textColor, fontSize: 15),
          items: [
            for (final type in VendorAuthService.groundTypes)
              DropdownMenuItem(
                value: type,
                child: Text('${VendorAuthService.groundIcons[type] ?? '🏟️'} $type'),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _groundType = v);
          },
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, {required bool isOpen}) {
    return GestureDetector(
      onTap: () => _pickTime(isOpen: isOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.subCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: context.subTextColor, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: context.subTextColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  time.format(context),
                  style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= 2; i++) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: i <= current ? const Color(0xFFFF7B42) : context.subCardBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$i',
              style: TextStyle(
                color: i <= current ? Colors.white : context.subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (i < 2)
            Container(
              height: 2,
              width: 40,
              color: i < current ? const Color(0xFFFF7B42) : context.borderColor,
            ),
        ],
        const Spacer(),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import '../services/vendor_auth_service.dart';
import '../theme/app_theme.dart';
import 'vendor_otp_screen.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid 10-digit mobile number.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFFD32F2F),
      ));
      return;
    }
    final phone = _phoneController.text;
    setState(() => _isSubmitting = true);
    try {
      await VendorAuthService.sendOtp(phone);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => VendorOtpScreen(phone: phone)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD32F2F),
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroGradientColors = context.isDark
        ? [const Color(0xFF2C1C16), const Color(0xFF1E1410)]
        : [const Color(0xFFFFF7F2), const Color(0xFFFFEAE0)];

    return Scaffold(
      backgroundColor: context.bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          if (isWide) {
            // Wide: side-by-side
            return Row(
              children: [
                // Left — hero panel
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: heroGradientColors,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -40,
                        bottom: -40,
                        child: Image.asset(
                          'assets/images/vendor-login-rabbit.png',
                          height: constraints.maxHeight * 0.75,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: context.textColor, size: 28),
                              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            ),
                            const SizedBox(height: 32),
                            Text('Vendor', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: context.textColor, height: 1.1)),
                            const Text('Login', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Color(0xFFFF5200), height: 1.1)),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 260,
                              child: Text('Access your dashboard, manage bookings, track earnings and grow your business.',
                                  style: TextStyle(fontSize: 16, color: context.subTextColor, height: 1.5, fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(height: 16),
                            Container(width: 32, height: 4, decoration: BoxDecoration(color: const Color(0xFFFF5200), borderRadius: BorderRadius.circular(2))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Right — form
                Expanded(
                  flex: 4,
                  child: Container(
                    height: double.infinity,
                    color: context.cardBg,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildForm(context, showTitle: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Narrow — stacked design
          return Stack(
            children: [
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: -30,
                child: Image.asset(
                  'assets/images/vendor-login-rabbit.png',
                  height: MediaQuery.of(context).size.height * 0.45,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: context.textColor, size: 28),
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0, top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vendor', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: context.textColor, height: 1.1)),
                              const Text('Login', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Color(0xFFFF5200), height: 1.1)),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 220,
                                child: Text('Access your dashboard,\nmanage bookings, track\nearnings and grow\nyour business.',
                                    style: TextStyle(fontSize: 14, color: context.subTextColor, height: 1.5, fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(height: 16),
                              Container(width: 32, height: 4, decoration: BoxDecoration(color: const Color(0xFFFF5200), borderRadius: BorderRadius.circular(2))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -30),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFFF5200).withValues(alpha: 0.12), shape: BoxShape.circle),
                                  child: const Icon(Icons.storefront, color: Color(0xFFFF7B42), size: 36),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -10),
                                child: _buildForm(context, showTitle: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, {bool showTitle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'Welcome ', style: TextStyle(color: context.textColor)),
                const TextSpan(text: 'back!', style: TextStyle(color: Color(0xFFFF7B42))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Log in to continue to your account',
              style: TextStyle(fontSize: 14, color: context.subTextColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
        ],
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: context.subCardBg,
            hintText: 'Enter mobile number',
            hintStyle: TextStyle(color: context.subTextColor),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('+91', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF7B42))),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7B42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, color: Color(0xFFFF7B42), size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text('Secure login for our trusted partners',
                  style: TextStyle(color: context.subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

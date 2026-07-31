import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_client.dart';
import '../services/vendor_auth_service.dart';
import '../theme/app_theme.dart';

class VendorOtpScreen extends StatefulWidget {
  final String phone;
  const VendorOtpScreen({super.key, required this.phone});

  @override
  State<VendorOtpScreen> createState() => _VendorOtpScreenState();
}

class _VendorOtpScreenState extends State<VendorOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroGradientColors = context.isDark
        ? [const Color(0xFF2C1C16), const Color(0xFF1E1410)]
        : [const Color(0xFFFFF7F2), const Color(0xFFFFEAE0)];

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: heroGradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Icon(Icons.arrow_back, color: context.textColor, size: 26),
                        ),
                      ),
                    ).animate().fade().slideX(begin: -0.2),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enter OTP', style: TextStyle(color: context.textColor, fontSize: 32, fontWeight: FontWeight.bold))
                                  .animate().fade(delay: 100.ms).slideY(begin: 0.1),
                              const SizedBox(height: 8),
                              Text('Sent to +91 ${widget.phone}', style: TextStyle(color: context.subTextColor, fontSize: 16))
                                  .animate().fade(delay: 150.ms),
                              const SizedBox(height: 40),
                              Row(
                                children: [
                                  for (int i = 0; i < 6; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(child: _buildCodeBox(i)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _verify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7B42),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isVerifying
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : const Text('Verify OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ).animate().fade(delay: 400.ms),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: const Color(0xFFFF7B42), borderRadius: BorderRadius.circular(4)),
                              child: const Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 6),
                            Text('Book Rabbit', style: TextStyle(color: context.subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                          Text('Vendor login', style: TextStyle(color: context.subTextColor, fontSize: 12)),
                        ],
                      ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the 6-digit OTP.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFFD32F2F),
      ));
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await VendorAuthService.verifyOtp(widget.phone, otp);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/vendor_dashboard', (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD32F2F),
      ));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Widget _buildCodeBox(int index) {
    final hasText = _controllers[index].text.isNotEmpty;
    Widget box = Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasText ? const Color(0xFFFF7B42) : context.borderColor,
          width: hasText ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7B42).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            border: InputBorder.none,
            hintText: '•',
            hintStyle: TextStyle(color: context.subTextColor, fontSize: 24),
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
            if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          },
        ),
      ),
    );
    if (_isVerifying) {
      box = Shimmer.fromColors(baseColor: context.subCardBg, highlightColor: context.cardBg, child: box);
    }
    return box.animate().fade(delay: Duration(milliseconds: 200 + (index * 50))).slideY(begin: 0.1);
  }
}

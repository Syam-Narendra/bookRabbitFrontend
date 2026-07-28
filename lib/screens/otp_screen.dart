import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7F2), Color(0xFFFFEAE0)],
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
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Icon(Icons.arrow_back, color: Color(0xFF1C1C1E), size: 26),
                        ),
                      ),
                    ).animate().fade().slideX(begin: -0.2),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Enter OTP', style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 32, fontWeight: FontWeight.bold))
                                  .animate().fade(delay: 100.ms).slideY(begin: 0.1),
                              const SizedBox(height: 8),
                              Text('Sent to +91 ${widget.phone}', style: const TextStyle(color: Color(0xFF666666), fontSize: 16))
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
                                    backgroundColor: const Color(0xFFFF5200),
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
                              decoration: BoxDecoration(color: const Color(0xFFFF5200), borderRadius: BorderRadius.circular(4)),
                              child: const Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 6),
                            const Text('Book Rabbit', style: TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                          const Text('A Rabbit product', style: TextStyle(color: Color(0xFF999999), fontSize: 12)),
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
      final user = await AuthService.verifyOtp(widget.phone, otp);
      if (!mounted) return;
      if (user.fullName == null || user.fullName!.trim().isEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, '/setup_profile', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      for (final c in _controllers) c.clear();
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasText ? const Color(0xFFFF5200) : const Color(0xFFE0E0E0),
          width: hasText ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5200).withValues(alpha: 0.05),
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
          style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            border: InputBorder.none,
            hintText: '•',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 24),
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
      box = Shimmer.fromColors(baseColor: const Color(0xFFE0E0E0), highlightColor: Colors.white, child: box);
    }
    return box.animate().fade(delay: Duration(milliseconds: 200 + (index * 50))).slideY(begin: 0.1);
  }
}

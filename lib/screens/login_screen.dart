import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';
import '../widgets/touchable_opacity.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _isSubmitting = false;

  static const String cricketRabbitUrl = 'assets/images/cricket-rabbit.png';
  static const String footballRabbitUrl = 'assets/images/football-rabbit.png';
  static const String tennisRabbitUrl = 'assets/images/tennis-rabbit.png';

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Container(
          color: context.bgColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (isWide) {
                return Row(
                  children: [
                    // Left banner
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF7A2F), Color(0xFFF2693F)],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cruelty_free, color: Colors.white, size: 52)
                                .animate().fade(duration: 400.ms).scale(curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            const Text('Book Rabbit',
                                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white))
                                .animate().fade(delay: 100.ms).slideY(begin: 0.2),
                            const SizedBox(height: 12),
                            Text('Instantly book your favourite sports grounds.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.9), height: 1.5))
                                .animate().fade(delay: 150.ms).slideY(begin: 0.1),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Expanded(child: Image.asset(cricketRabbitUrl, fit: BoxFit.contain).animate().fade(delay: 200.ms).slideY(begin: 0.2)),
                                const SizedBox(width: 12),
                                Expanded(child: Image.asset(footballRabbitUrl, fit: BoxFit.contain).animate().fade(delay: 250.ms).slideY(begin: 0.2)),
                                const SizedBox(width: 12),
                                Expanded(child: Image.asset(tennisRabbitUrl, fit: BoxFit.contain).animate().fade(delay: 300.ms).slideY(begin: 0.2)),
                              ],
                            ),
                          ],
                        ),
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Welcome!', style: TextStyle(fontSize: 32, color: context.textColor, fontWeight: FontWeight.bold))
                                        .animate().fade(delay: 400.ms).slideY(begin: 0.1),
                                    const SizedBox(height: 10),
                                    Text('Book Rabbit lets you instantly book your favourite sports grounds.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 15, color: context.subTextColor, height: 1.5))
                                        .animate().fade(delay: 450.ms).slideY(begin: 0.1),
                                    const SizedBox(height: 30),
                                    _buildForm(context),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              // Narrow — stacked with bottom container
              return Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.cruelty_free, color: Colors.white, size: 42)
                      .animate().fade(duration: 400.ms).scale(curve: Curves.easeOutBack),
                  const SizedBox(height: 8),
                  const Text('Book Rabbit',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white))
                      .animate().fade(delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: Image.asset(cricketRabbitUrl, fit: BoxFit.contain).animate().fade(delay: 200.ms).slideY(begin: 0.2)),
                        const SizedBox(width: 8),
                        Expanded(child: Image.asset(footballRabbitUrl, fit: BoxFit.contain).animate().fade(delay: 250.ms).slideY(begin: 0.2)),
                        const SizedBox(width: 8),
                        Expanded(child: Image.asset(tennisRabbitUrl, fit: BoxFit.contain).animate().fade(delay: 300.ms).slideY(begin: 0.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Welcome!', style: TextStyle(fontSize: 28, color: context.textColor, fontWeight: FontWeight.bold))
                            .animate().fade(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 8),
                        Text('Book Rabbit lets you instantly book your favourite sports grounds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: context.subTextColor, height: 1.4))
                            .animate().fade(delay: 450.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildForm(context),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: context.subCardBg,
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
            hintText: 'Enter mobile number',
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
              borderSide: const BorderSide(color: Color(0xFFF2693F), width: 1.5),
            ),
          ),
        ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
        const SizedBox(height: 18),
        TouchableOpacity(
          onTap: _isSubmitting
              ? null
              : () async {
                  if (phoneController.text.length != 10) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a valid 10-digit mobile number.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      backgroundColor: Color(0xFFD32F2F),
                    ));
                    return;
                  }
                  final phone = phoneController.text;
                  setState(() => _isSubmitting = true);
                  try {
                    final devOtp = await AuthService.sendOtp(phone);
                    if (!context.mounted) return;
                    if (devOtp != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('DEV OTP: $devOtp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.black87,
                        duration: const Duration(seconds: 6),
                      ));
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFFD32F2F),
                    ));
                  } finally {
                    if (context.mounted) setState(() => _isSubmitting = false);
                  }
                },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF2693F),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
        ).animate().fade(delay: 550.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/vendor_login'),
            child: const Text('Vendor Login',
                style: TextStyle(
                    color: Color(0xFFF2693F),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFF2693F))),
          ),
        ),
      ],
    );
  }
}

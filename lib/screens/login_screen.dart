import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
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

  final String cricketRabbitUrl = 'assets/images/cricket-rabbit.png';
  final String footballRabbitUrl = 'assets/images/football-rabbit.png';
  final String tennisRabbitUrl = 'assets/images/tennis-rabbit.png';

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF57C4C), Color(0xFFF2693F)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (isWide) {
                return Row(
                  children: [
                    // Left — mascots
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cruelty_free, color: Colors.white, size: 52)
                                .animate().fade(duration: 400.ms).scale(curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            Text('Book Rabbit',
                                style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white))
                                .animate().fade(delay: 100.ms).slideY(begin: 0.2),
                            const SizedBox(height: 12),
                            Text('Instantly book your favourite sports grounds.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white.withValues(alpha: 0.9), height: 1.5))
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
                    // Right — form (solid white background like vendor login)
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: double.infinity,
                        color: Colors.white,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 420),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Welcome!', style: GoogleFonts.plusJakartaSans(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold))
                                        .animate().fade(delay: 400.ms).slideY(begin: 0.1),
                                    const SizedBox(height: 10),
                                    Text('Book Rabbit lets you instantly book your favourite sports grounds.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.grey[600], height: 1.5))
                                        .animate().fade(delay: 450.ms).slideY(begin: 0.1),
                                    const SizedBox(height: 30),
                                    _buildForm(context, isWhiteBg: true),
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
              // Narrow — stacked with bottom white container like vendor login
              return Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.cruelty_free, color: Colors.white, size: 42)
                      .animate().fade(duration: 400.ms).scale(curve: Curves.easeOutBack),
                  const SizedBox(height: 8),
                  Text('Book Rabbit',
                      style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white))
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Welcome!', style: GoogleFonts.plusJakartaSans(fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold))
                            .animate().fade(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 8),
                        Text('Book Rabbit lets you instantly book your favourite sports grounds.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600], height: 1.4))
                            .animate().fade(delay: 450.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildForm(context, isWhiteBg: true),
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

  Widget _buildForm(BuildContext context, {bool isWhiteBg = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isWhiteBg ? const Color(0xFFF8F9FA) : Colors.white,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🇮🇳', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('+91', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            hintText: 'Enter mobile number',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isWhiteBg ? const Color(0xFFE0E0E0) : Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isWhiteBg ? const Color(0xFFE0E0E0) : Colors.transparent),
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
                      content: Text('Please enter a valid 10-digit mobile number.'),
                      backgroundColor: Colors.redAccent,
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
                        content: Text('DEV OTP: $devOtp'),
                        backgroundColor: Colors.black87,
                        duration: const Duration(seconds: 6),
                      ));
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent));
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
                : Text('LOGIN', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
        ).animate().fade(delay: 550.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/vendor_login'),
            child: Text('Vendor Login',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFF2693F),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFF2693F))),
          ),
        ),
      ],
    );
  }
}

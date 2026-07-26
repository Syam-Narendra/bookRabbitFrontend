import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController phoneController = TextEditingController();
  bool _isSubmitting = false;

  // Replace with your real URLs later
  final String cricketRabbitUrl =
      "assets/images/cricket-rabbit.png";
  final String footballRabbitUrl =
      "assets/images/football-rabbit.png";
  final String tennisRabbitUrl =
      "assets/images/tennis-rabbit.png";

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF57C4C),
              Color(0xFFF2693F),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: isDesktop ? 430 : double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Icon(Icons.cruelty_free,
                            color: Colors.white, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          "Book Rabbit",
                          style: GoogleFonts.inter(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: Image.asset(cricketRabbitUrl,
                                      fit: BoxFit.contain)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Image.asset(footballRabbitUrl,
                                      fit: BoxFit.contain)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Image.asset(tennisRabbitUrl,
                                      fit: BoxFit.contain)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Welcome!",
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Book Rabbit lets you instantly book your favourite sports grounds.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: .95),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text("🇮🇳", style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 8),
                                  Text("+91", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            hintText: "Enter mobile number",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : () async {
                                    if (phoneController.text.length != 10) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please enter a valid 10-digit mobile number."),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                    final phone = phoneController.text;
                                    setState(() => _isSubmitting = true);
                                    try {
                                      final devOtp = await AuthService.sendOtp(phone);
                                      if (!context.mounted) return;
                                      if (devOtp != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('DEV OTP: $devOtp'),
                                            backgroundColor: Colors.black87,
                                            duration: const Duration(seconds: 6),
                                          ),
                                        );
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OtpScreen(phone: phone),
                                        ),
                                      );
                                    } on ApiException catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.message),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    } finally {
                                      if (context.mounted) {
                                        setState(() => _isSubmitting = false);
                                      }
                                    }
                                  },
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    "LOGIN",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/vendor_login');
                            },
                            child: Text(
                              "Vendor Login",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
              
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
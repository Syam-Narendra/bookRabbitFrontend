import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'otp_screen.dart';
import '../widgets/touchable_opacity.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {

  final TextEditingController phoneController = TextEditingController();

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
                            color: Colors.white, size: 42)
                            .animate().fade(duration: 400.ms).scale(curve: Curves.easeOutBack),
                        const SizedBox(height: 12),
                        Text(
                          "Book Rabbit",
                          style: GoogleFonts.inter(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                        const SizedBox(height: 28),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: Image.asset(cricketRabbitUrl,
                                      fit: BoxFit.contain)
                                      .animate().fade(delay: 200.ms).slideY(begin: 0.2)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Image.asset(footballRabbitUrl,
                                      fit: BoxFit.contain)
                                      .animate().fade(delay: 250.ms).slideY(begin: 0.2)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Image.asset(tennisRabbitUrl,
                                      fit: BoxFit.contain)
                                      .animate().fade(delay: 300.ms).slideY(begin: 0.2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Vendor Login",
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 10),
                        Text(
                          "Book Rabbit lets you instantly manage your sports grounds.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: .95),
                            height: 1.5,
                          ),
                        ).animate().fade(delay: 450.ms).slideY(begin: 0.1),
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
                        ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                        const SizedBox(height: 18),
                        TouchableOpacity(
                          onTap: () {
                            if (phoneController.text.length != 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter a valid 10-digit mobile number."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtpScreen(phone: phoneController.text),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "LOGIN",
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ).animate().fade(delay: 550.ms).slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/');
                            },
                            child: Text(
                              "User Login",
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

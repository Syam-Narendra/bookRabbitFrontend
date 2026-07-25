import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isVendor = false;

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
                                  child: ClipRect(
                                      child: Transform.scale(
                                          scale: 1.3,
                                          child: Image.asset(cricketRabbitUrl,
                                              fit: BoxFit.cover)))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: ClipRect(
                                      child: Transform.scale(
                                          scale: 1.3,
                                          child: Image.asset(footballRabbitUrl,
                                              fit: BoxFit.cover)))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: ClipRect(
                                      child: Transform.scale(
                                          scale: 1.3,
                                          child: Image.asset(tennisRabbitUrl,
                                              fit: BoxFit.cover)))),
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
                            color: Colors.white.withOpacity(.95),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              _toggle(false, "User"),
                              _toggle(true, "Vendor"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
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
                                  Icon(Icons.phone, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text("+91", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            hintText: "Enter mobile number",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
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
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/otp');
                            },
                            child: Text(
                              "LOGIN",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
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

  Widget _toggle(bool vendor, String label) {
    final selected = vendor == isVendor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isVendor = vendor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
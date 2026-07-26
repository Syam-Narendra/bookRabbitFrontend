import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
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
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFF7F2), Color(0xFFFFEAE0)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        bottom: 0,
                        top: 0,
                        child: Image.asset(
                          'assets/images/vendor-login-rabbit.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 48, top: 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E), size: 28),
                                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                              ),
                              const SizedBox(height: 32),
                              Text('Vendor', style: GoogleFonts.plusJakartaSans(fontSize: 52, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E), height: 1.1)),
                              Text('Login', style: GoogleFonts.plusJakartaSans(fontSize: 52, fontWeight: FontWeight.w800, color: const Color(0xFFFF5200), height: 1.1)),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 260,
                                child: Text('Access your dashboard, manage bookings, track earnings and grow your business.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF666666), height: 1.5, fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(height: 16),
                              Container(width: 32, height: 4, decoration: BoxDecoration(color: const Color(0xFFFF5200), borderRadius: BorderRadius.circular(2))),
                            ],
                          ),
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
                    color: Colors.white,
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

          // Narrow — original stacked design
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
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E), size: 28),
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0, top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vendor', style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E), height: 1.1)),
                              Text('Login', style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w800, color: const Color(0xFFFF5200), height: 1.1)),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 220,
                                child: Text('Access your dashboard,\nmanage bookings, track\nearnings and grow\nyour business.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF666666), height: 1.5, fontWeight: FontWeight.w500)),
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
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
                                  decoration: const BoxDecoration(color: Color(0xFFFFF0E5), shape: BoxShape.circle),
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
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800),
              children: const [
                TextSpan(text: 'Welcome ', style: TextStyle(color: Colors.black)),
                TextSpan(text: 'back!', style: TextStyle(color: Color(0xFFFF7B42))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Log in to continue to your account',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
        ],
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter mobile number',
            hintStyle: TextStyle(color: Colors.grey[400]),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF7B42))),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7B42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Log In', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

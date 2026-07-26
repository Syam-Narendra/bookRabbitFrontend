import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../widgets/touchable_opacity.dart';


class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  bool _acceptTerms = true;
  bool _isSubmitting = false;
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C3232),
              Color(0xFF1B1B1B),
              Color(0xFF1A1A1A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ).animate().fade().slideX(begin: -0.2),
                          const SizedBox(height: 20),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                          const SizedBox(height: 16),
                          Text(
                            'Enter a few more details to finish creating your\nBook Rabbit account.',
                            style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                          const SizedBox(height: 32),
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: const Color(0xFF333333),
                                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                                    child: _imageFile == null
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey[600],
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF4B3A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fade(delay: 200.ms).scale(),
                          const SizedBox(height: 40),
                          _buildTextFieldLabel('FIRST NAME *').animate().fade(delay: 250.ms),
                          _buildTextField(hintText: 'Enter your first name', controller: _nameController)
                              .animate().fade(delay: 300.ms).slideY(begin: 0.1),
                          const SizedBox(height: 24),
                          _buildCheckboxRow(
                            value: _acceptTerms,
                            onChanged: (val) => setState(() => _acceptTerms = val),
                            richTitle: TextSpan(
                              text: 'I have read and accept the ',
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                              children: [
                                const TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(decoration: TextDecoration.underline),
                                ),
                                const TextSpan(text: ' and\n'),
                                const TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(decoration: TextDecoration.underline),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Actions
                  TouchableOpacity(
                    onTap: _isSubmitting
                        ? null
                        : () async {
                            if (_nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter your first name."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            setState(() => _isSubmitting = true);
                            try {
                              await AuthService.updateName(_nameController.text.trim());
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4B3A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'B',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Book Rabbit',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'A Rabbit product',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ).animate().fade(delay: 550.ms).slideY(begin: 0.1),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField({required String hintText, TextEditingController? controller}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }



  Widget _buildCheckboxRow({
    required bool value,
    required Function(bool) onChanged,
    String? title,
    String? subtitle,
    InlineSpan? richTitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            margin: const EdgeInsets.only(top: 4, right: 16),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: value ? Colors.white : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : null,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              if (richTitle != null)
                RichText(
                  text: richTitle,
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../router/route_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/touchable_opacity.dart';
import '../widgets/app_snackbar.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  bool _acceptTerms = false;
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
      backgroundColor: context.bgColor,
      body: SafeArea(
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
                            icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 24),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ).animate().fade().slideX(begin: -0.2),
                        const SizedBox(height: 20),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        Text(
                          'Enter a few more details to finish creating your\nBook Rabbit account.',
                          style: TextStyle(
                            color: context.subTextColor,
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
                                  backgroundColor: context.subCardBg,
                                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                                  child: _imageFile == null
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: context.subTextColor,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5200),
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
                        _buildTextFieldLabel(context, 'FIRST NAME *').animate().fade(delay: 250.ms),
                        _buildTextField(context, hintText: 'Enter your first name', controller: _nameController)
                            .animate().fade(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildCheckboxRow(
                          context,
                          value: _acceptTerms,
                          onChanged: (val) => setState(() => _acceptTerms = val),
                          richTitle: TextSpan(
                            text: 'I have read and accept the ',
                            style: TextStyle(color: context.textColor, fontSize: 14, height: 1.4),
                            children: const [
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(decoration: TextDecoration.underline),
                              ),
                              TextSpan(text: ' and\n'),
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: TextStyle(decoration: TextDecoration.underline),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ).animate().fade(delay: 350.ms).slideY(begin: 0.1),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // Submit button
                TouchableOpacity(
                  onTap: _isSubmitting
                      ? null
                      : () async {
                          if (_nameController.text.trim().isEmpty) {
                            AppSnackBar.showError(context, "Please enter your first name.");
                            return;
                          }
                          if (!_acceptTerms) {
                            AppSnackBar.showError(
                              context,
                              "Please accept the Privacy Policy and Terms and Conditions.",
                            );
                            return;
                          }
                          setState(() => _isSubmitting = true);
                          try {
                            await AuthService.updateName(_nameController.text.trim());
                            if (!context.mounted) return;
                            context.goHome();
                          } on ApiException catch (e) {
                            if (!context.mounted) return;
                            AppSnackBar.showError(context, e.message);
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
                      color: const Color(0xFFFF5200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                            color: const Color(0xFFFF5200),
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
                        Text(
                          'Book Rabbit',
                          style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'A Rabbit product',
                      style: TextStyle(color: context.subTextColor, fontSize: 12),
                    ),
                  ],
                ).animate().fade(delay: 550.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: context.subTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {required String hintText, TextEditingController? controller}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: context.subTextColor, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(
    BuildContext context, {
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
              border: Border.all(color: context.textColor, width: 2),
              color: value ? const Color(0xFFFF5200) : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                  style: TextStyle(color: context.textColor, fontSize: 14, height: 1.4),
                ),
              if (richTitle != null)
                RichText(
                  text: richTitle,
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: context.subTextColor, fontSize: 12, height: 1.4),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}


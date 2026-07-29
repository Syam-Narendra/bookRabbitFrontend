import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../terms_conditions_screen.dart';
import '../support_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final TextEditingController _firstNameController = TextEditingController();
  bool _isUploadingPhoto = false;
  bool _isLoadingStats = true;

  int _gamesCount = 0;
  int _upcomingCount = 0;
  double _hoursTotal = 0;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = AuthService.currentUser?.fullName ?? '';
    AuthService.fetchMe().then((_) {
      if (!mounted) return;
      setState(() {
        _firstNameController.text = AuthService.currentUser?.fullName ?? '';
      });
    }).catchError((_) {
      // Offline / request failed — keep showing the cached currentUser.
    });
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final bookings = await BookingService.fetchMyBookings();
      final stats = BookingService.computeStats(bookings);
      if (!mounted) return;
      setState(() {
        _gamesCount = stats['games']!.toInt();
        _hoursTotal = stats['hours']!.toDouble();
        _upcomingCount = stats['upcoming']!.toInt();
        _isLoadingStats = false;
      });
    } catch (_) {
      // Offline / request failed — keep showing zeros rather than mock data.
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final sizeBytes = await file.length();
    if (sizeBytes > 8 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image is too large. Please choose a smaller photo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      await AuthService.updateProfileImage(file);
      if (!mounted) return;
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoggingOut = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.cardBg,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              title: Text('Confirm Logout',
                  style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              content: Text('Are you sure you want to log out?',
                  style: TextStyle(color: context.subTextColor, fontSize: 15)),
              actions: [
                TextButton(
                  onPressed: isLoggingOut ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: TextStyle(
                          fontSize: 15,
                          color: isLoggingOut ? const Color(0xFF52525B) : context.subTextColor)),
                ),
                TextButton(
                  onPressed: isLoggingOut
                      ? null
                      : () async {
                          setDialogState(() => isLoggingOut = true);
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await AuthService.logout();
                          } catch (_) {
                            // Proceed with logout navigation even if network request fails
                          }
                          if (!mounted) return;
                          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                  child: isLoggingOut
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE54F3F),
                          ),
                        )
                      : const Text('Log Out',
                          style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFE54F3F),
                              fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context) {
    bool isSaving = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.cardBg,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              title: Text('Edit Name',
                  style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              content: TextField(
                controller: _firstNameController,
                enabled: !isSaving,
                style: TextStyle(color: context.textColor, fontSize: 15),
                cursorColor: const Color(0xFFE54F3F),
                decoration: InputDecoration(
                  hintText: 'Enter your first name',
                  hintStyle: TextStyle(color: context.subTextColor, fontSize: 14),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE54F3F)),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 15,
                        color: isSaving ? const Color(0xFF52525B) : context.subTextColor),
                  ),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = _firstNameController.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => isSaving = true);
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await AuthService.updateName(name);
                            if (!mounted) return;
                            setState(() {});
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('User name updated successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } on ApiException catch (e) {
                            if (!mounted) return;
                            setDialogState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
                            );
                          } catch (_) {
                            if (!mounted) return;
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE54F3F),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFE54F3F),
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final bottomPad = isWide ? 40.0 : 140.0;

        if (isWide) {
          return Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 960),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Profile Info, Form, Stats & Actions
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 24),
                          _buildProfilePhotoSection(),
                          const SizedBox(height: 24),
                          _buildFormFields(),
                          const SizedBox(height: 16),
                          _buildStatsSection(),
                          const SizedBox(height: 24),
                          _buildMenuOptions(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Column: Invite Friends Card (Vertically Centered)
                  Expanded(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, rightConstraints) {
                        final minH = rightConstraints.maxHeight.isFinite
                            ? (rightConstraints.maxHeight - 48).clamp(0.0, double.infinity)
                            : 0.0;
                        return SingleChildScrollView(
                          child: Container(
                            constraints: BoxConstraints(minHeight: minH),
                            child: Center(
                              child: _buildInviteBannerWide().animate().fade(delay: 200.ms).slideY(begin: 0.1),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Mobile layout: Single column
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: EdgeInsets.only(top: 8, bottom: bottomPad, left: 16, right: 16),
              children: [
                _buildTitle(),
                const SizedBox(height: 32),
                _buildProfilePhotoSection(),
                const SizedBox(height: 32),
                _buildFormFields(),
                const SizedBox(height: 16),
                _buildStatsSection(),
                const SizedBox(height: 32),
                _buildMenuOptions(),
                const SizedBox(height: 24),
                _buildInviteBanner().animate().fade(delay: 700.ms).scale(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      'Profile',
      style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    ).animate().fade(duration: 300.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildProfilePhotoSection() {
    return Row(
      children: [
        GestureDetector(
          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage(
                  AuthService.currentUser?.profileImageUrl ??
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.subCardBg,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingPhoto
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.textColor),
                        )
                      : Icon(Icons.camera_alt, color: context.textColor, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replace photo',
              style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG or WebP. Max 2MB.',
              style: TextStyle(color: context.subTextColor, fontSize: 12),
            ),
          ],
        ),
      ],
    ).animate().fade(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildFormFields() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.subCardBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone, color: context.textColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Opacity(
                    opacity: 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MOBILE NUMBER', style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(
                          AuthService.currentUser?.phoneNumber ?? '',
                          style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 68.0, right: 16.0),
            child: Divider(color: context.borderColor, thickness: 1, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.subCardBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: context.textColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FIRST NAME', style: TextStyle(color: context.subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text(
                        _firstNameController.text,
                        style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditNameDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.subCardBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, color: context.textColor, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _isLoadingStats
          ? List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Shimmer.fromColors(
                    baseColor: context.subCardBg,
                    highlightColor: context.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: context.subCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : [
              _buildStatCard('Games', '$_gamesCount', Icons.sports_soccer).animate().fade(delay: 300.ms).slideY(begin: 0.2),
              _buildStatCard('Hours', _formatHours(_hoursTotal), Icons.schedule).animate().fade(delay: 350.ms).slideY(begin: 0.2),
              _buildStatCard('Upcoming', '$_upcomingCount', Icons.event).animate().fade(delay: 400.ms).slideY(begin: 0.2),
            ],
    );
  }

  Widget _buildMenuOptions() {
    return Column(
      children: [
        _buildThemeToggleOption().animate().fade(delay: 450.ms).slideY(begin: 0.1),
        _buildMenuOption('Help & Support', Icons.help_outline, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportScreen()),
          );
        }).animate().fade(delay: 500.ms).slideY(begin: 0.1),
        _buildMenuOption('Terms & Conditions', Icons.description_outlined, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
          );
        }).animate().fade(delay: 550.ms).slideY(begin: 0.1),
        _buildMenuOption('Log Out', Icons.logout, isDestructive: true, onTap: _logout).animate().fade(delay: 600.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildThemeToggleOption() {
    final isDark = ThemeService.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.subCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: context.textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeColor: const Color(0xFFFF4B3A),
            onChanged: (value) {
              ThemeService.toggleTheme(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInviteBannerWide() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.subCardBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.card_giftcard, color: context.textColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Invite Friends 👋',
                  style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Share your personal link and challenge your friends to a game on Book Rabbit.',
            style: TextStyle(color: context.subTextColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: context.subTextColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppConstants.inviteLink,
                    style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Share.share(
                  'Challenge me to a game on Book Rabbit! 🐰\nJoin using my link: ${AppConstants.inviteLink}',
                );
              },
              icon: const Icon(Icons.share, color: Colors.white, size: 18),
              label: const Text(
                'Invite Friends Now',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5200),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteBanner() {
    return InkWell(
      onTap: () {
        Share.share(
          'Challenge me to a game on Book Rabbit! 🐰\nJoin using my link: ${AppConstants.inviteLink}',
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite your friends!',
                    style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your link and challenge your friends\nto a game on Book Rabbit.',
                    style: TextStyle(color: context.subTextColor, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE56B3F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Invite now',
                style: TextStyle(color: Color(0xFFE56B3F), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '👋',
              style: TextStyle(fontSize: 40),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHours(double hours) {
    return hours % 1 == 0 ? hours.toInt().toString() : hours.toStringAsFixed(1);
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.isDark ? context.subCardBg : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: context.isDark ? null : Border.all(color: context.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE54F3F), size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: context.subTextColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? const Color(0xFFE54F3F) : context.textColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFE54F3F).withValues(alpha: 0.1) : context.subCardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            if (!isDestructive) Icon(Icons.chevron_right, color: context.subTextColor, size: 20),
          ],
        ),
      ),
    );
  }
}


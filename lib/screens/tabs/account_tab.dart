import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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

  String? get _profileImageUrl {
    final url = AuthService.currentUser?.profileImageUrl;
    return (url == null || url.isEmpty) ? null : url;
  }

  String get _profileInitials {
    final name = AuthService.currentUser?.fullName ?? '';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

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

    final bytes = await pickedFile.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image is too large. Please choose a smaller photo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      await AuthService.updateProfileImageBytes(bytes, pickedFile.name);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo. Please try again.'), backgroundColor: Colors.redAccent),
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
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final bottomPad = isWide ? 40.0 : 72.0;

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
                          const SizedBox(height: 16),
                          _buildBrandFooter(),
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
                const SizedBox(height: 16),
                _buildBrandFooter(),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildBrandFooter() {
    final isDark = context.isDark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0);
    const accentOrange = Color(0xFFFF5200);
    final watermarkColor = accentOrange.withValues(alpha: 0.10);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1.2),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background Line Art Icons Watermarks
                Positioned(
                  left: 12,
                  top: 18,
                  child: Icon(Icons.sports_cricket_outlined, size: 24, color: watermarkColor),
                ),
                Positioned(
                  left: 14,
                  bottom: 24,
                  child: Icon(Icons.sports_soccer_outlined, size: 24, color: watermarkColor),
                ),
                Positioned(
                  right: 12,
                  top: 18,
                  child: Icon(Icons.sports_tennis_outlined, size: 24, color: watermarkColor),
                ),
                Positioned(
                  right: 14,
                  bottom: 24,
                  child: Icon(Icons.sports_basketball_outlined, size: 24, color: watermarkColor),
                ),

                // Main Content Column
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Mascot Image (assets/images/footer_logo.png)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentOrange.withValues(alpha: 0.06),
                            ),
                          ),
                          Image.asset(
                            'assets/images/footer_logo.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/images/sports_bunnies.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Small sparkle accents
                          Positioned(
                            left: 0,
                            top: 6,
                            child: Text('✦', style: TextStyle(color: accentOrange.withValues(alpha: 0.6), fontSize: 8)),
                          ),
                          Positioned(
                            right: 0,
                            top: 10,
                            child: Text('✦', style: TextStyle(color: accentOrange.withValues(alpha: 0.6), fontSize: 7)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 2. Book Rabbit Brand Logo & Title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cruelty_free, size: 20, color: Color(0xFFFF5200)),
                          const SizedBox(width: 6),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                TextSpan(
                                  text: 'Book ',
                                  style: TextStyle(color: context.textColor),
                                ),
                                const TextSpan(
                                  text: 'Rabbit',
                                  style: TextStyle(color: Color(0xFFFF5200)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // 3. "A RABBIT PRODUCT" Subtitle with Side Lines
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 18, height: 1.0, color: accentOrange.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          const Text(
                            'A RABBIT PRODUCT',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 18, height: 1.0, color: accentOrange.withValues(alpha: 0.4)),
                        ],
                      ),


                  
                      // Hairline Separator Line
                      Divider(height: 1, thickness: 1, color: borderCol),

                      const SizedBox(height: 10),

                      // 5. Version Pill Badge at Bottom
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentOrange.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accentOrange.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 12, color: accentOrange),
                                const SizedBox(width: 4),
                                Text(
                                  'v1.0.0',
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentOrange.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5200), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFFFF5200).withValues(alpha: 0.12),
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? Text(
                          _profileInitials,
                          style: const TextStyle(
                              color: Color(0xFFFF5200),
                              fontSize: 28,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5200),
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingPhoto
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5200).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5200).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isUploadingPhoto) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5200)),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(Icons.file_upload_outlined, color: Color(0xFFFF5200), size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isUploadingPhoto ? 'Uploading...' : 'Replace photo',
                      style: const TextStyle(color: Color(0xFFFF5200), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'JPG, PNG or WebP. Max 8MB.',
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
            activeThumbColor: const Color(0xFFFF4B3A),
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
                SharePlus.instance.share(ShareParams(
                  text: 'Challenge me to a game on Book Rabbit! 🐰\nJoin using my link: ${AppConstants.inviteLink}',
                ));
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
        SharePlus.instance.share(ShareParams(
          text: 'Challenge me to a game on Book Rabbit! 🐰\nJoin using my link: ${AppConstants.inviteLink}',
        ));
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
    final rounded = (hours * 10).round() / 10;
    return rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toStringAsFixed(1);
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


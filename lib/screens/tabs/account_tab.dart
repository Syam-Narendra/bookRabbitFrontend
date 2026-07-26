import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final TextEditingController _firstNameController = TextEditingController();
  bool _isUploadingPhoto = false;

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
    try {
      final bookings = await BookingService.fetchMyBookings();
      final stats = BookingService.computeStats(bookings);
      if (!mounted) return;
      setState(() {
        _gamesCount = stats['games']!.toInt();
        _hoursTotal = stats['hours']!.toDouble();
        _upcomingCount = stats['upcoming']!.toInt();
      });
    } catch (_) {
      // Offline / request failed — keep showing zeros rather than mock data.
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    // Downscale on pick — full-resolution camera/gallery photos on real devices
    // (often 5-15MB) were blowing past the backend's upload size limit, which
    // is what made this only fail on mobile (simulators/small test images
    // stayed under the limit).
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
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _showEditNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _firstNameController,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFFE54F3F),
            decoration: const InputDecoration(
              hintText: 'Enter your first name',
              hintStyle: TextStyle(color: Color(0xFF98989E)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2C2C2E)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE54F3F)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF98989E))),
            ),
            TextButton(
              onPressed: () async {
                final name = _firstNameController.text.trim();
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
                  messenger.showSnackBar(
                    SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFFE54F3F), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 140),
      children: [

        // Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Profile',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
        ),
        const SizedBox(height: 32),
        
        // Profile Photo Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
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
                    ), // Placeholder portrait
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2E),
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
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Replace photo',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'JPG, PNG or WebP. Max 2MB.',
                    style: TextStyle(color: Color(0xFF98989E), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Form Fields
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Mobile Number Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Opacity(
                          opacity: 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MOBILE NUMBER', style: TextStyle(color: Color(0xFF98989E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              Text(
                                AuthService.currentUser?.phoneNumber ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.only(left: 68.0, right: 16.0),
                  child: Divider(color: Color(0xFF2C2C2E), thickness: 1, height: 1),
                ),
                
                // First Name Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FIRST NAME', style: TextStyle(color: Color(0xFF98989E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text(
                              _firstNameController.text,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditNameDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Stats Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Games', '$_gamesCount', Icons.sports_soccer),
              _buildStatCard('Hours', _formatHours(_hoursTotal), Icons.schedule),
              _buildStatCard('Upcoming Games', '$_upcomingCount', Icons.event),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildMenuOption('Help & Support', Icons.help_outline, onTap: () async {
          final url = Uri.parse('${AppConstants.apiBaseUrl}/support');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        }),
        _buildMenuOption('Terms & Conditions', Icons.description_outlined, onTap: () async {
          final url = Uri.parse('${AppConstants.apiBaseUrl}/terms');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        }),
        _buildMenuOption('Log Out', Icons.logout, isDestructive: true, onTap: _logout),
        
        const SizedBox(height: 24),
        _buildInviteBanner(),
      ],
    );
  }

  Widget _buildInviteBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () {
          Share.share(
            'Challenge me to a game on Book Rabbit! 🐰\nJoin using my link: ${AppConstants.inviteLink}',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C2E)),
          ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Invite your friends!',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Share your link and challenge your friends\nto a game on Book Rabbit.',
                    style: TextStyle(color: Color(0xFF98989E), fontSize: 13, height: 1.4),
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
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE54F3F), size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF98989E), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? const Color(0xFFE54F3F) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive ? const Color(0xFFE54F3F).withValues(alpha: 0.1) : const Color(0xFF2C2C2E),
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
          if (!isDestructive) const Icon(Icons.chevron_right, color: Color(0xFF98989E), size: 20),
        ],
      ),
      ),
    );
  }
}

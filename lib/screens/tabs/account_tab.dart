import 'package:flutter/material.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final TextEditingController _firstNameController = TextEditingController(text: 'Alex');

  @override
  void dispose() {
    _firstNameController.dispose();
    super.dispose();
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
              onPressed: () {
                setState(() {}); // Trigger a rebuild to reflect the new name in the Text widget
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User name updated successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
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
      padding: const EdgeInsets.only(top: 90, bottom: 140),
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
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 44,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop'), // Placeholder portrait
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
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ],
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
                            children: const [
                              Text('MOBILE NUMBER', style: TextStyle(color: Color(0xFF98989E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              SizedBox(height: 4),
                              Text('+91 9876543210', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
              _buildStatCard('Games', '12', Icons.sports_soccer),
              _buildStatCard('Hours', '24', Icons.schedule),
              _buildStatCard('Rating', '4.8', Icons.star_border),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildMenuOption('Help & Support', Icons.help_outline),
        _buildMenuOption('Log Out', Icons.logout, isDestructive: true),
        
        const SizedBox(height: 24),
        _buildInviteBanner(),
      ],
    );
  }

  Widget _buildInviteBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    'Invite friends, get rewards!',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Share your link and earn exciting rewards\nwhen your friends join.',
                    style: TextStyle(color: Color(0xFF98989E), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE56B3F).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Invite now',
                style: TextStyle(color: Color(0xFFE56B3F), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '🎁',
              style: TextStyle(fontSize: 40),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildMenuOption(String title, IconData icon, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFE54F3F) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive ? const Color(0xFFE54F3F).withOpacity(0.1) : const Color(0xFF2C2C2E),
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
    );
  }
}

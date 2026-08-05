import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../router/route_extensions.dart';
import '../../services/api_client.dart';
import '../../services/vendor_auth_service.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Devices & sessions: lists active logins, lets the owner sign out a single
/// device or every device at once.
class VendorSessionsPage extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const VendorSessionsPage({super.key, required this.onRefresh});

  @override
  State<VendorSessionsPage> createState() => _VendorSessionsPageState();
}

class _VendorSessionsPageState extends State<VendorSessionsPage> {
  List<VendorSession> _sessions = [];
  bool _loading = true;
  String? _error;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await VendorAuthService.fetchSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _deviceLabel(VendorSession s) {
    final ua = s.ua ?? '';
    if (ua.isEmpty) return 'Unknown device';
    if (ua.contains('iPhone')) return 'iPhone';
    if (ua.contains('Android')) return 'Android';
    if (ua.contains('Mac')) return 'Mac';
    if (ua.contains('Windows')) return 'Windows';
    if (ua.contains('Linux')) return 'Linux';
    return 'Device';
  }

  IconData _deviceIcon(VendorSession s) {
    final ua = s.ua ?? '';
    if (ua.contains('iPhone') || ua.contains('Android')) return Icons.smartphone;
    if (ua.contains('Mac')) return Icons.laptop_mac;
    if (ua.contains('Windows')) return Icons.laptop_windows;
    return Icons.devices_other;
  }

  Future<void> _logoutSession(VendorSession session) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final loggedOutCurrent = await VendorAuthService.manageSession(
        'logout-session',
        sessionId: session.id,
      );
      if (loggedOutCurrent) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Signed out of this device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: Color(0xFF2E8443),
        ));
        context.goVendorLogin();
        return;
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _logoutEverywhere() async {
    if (_processing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out everywhere?'),
        content: const Text('You will be signed out on all devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out Everywhere', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      await VendorAuthService.manageSession('logout-everywhere');
      if (!mounted) return;
      context.goVendorLogin();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _toast(e.message);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFD32F2F),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Devices & Sessions', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          VendorEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load sessions',
            subtitle: _error!,
            action: OutlinedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sessions', style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '${_sessions.length} active login${_sessions.length == 1 ? '' : 's'}',
                    style: TextStyle(color: context.subTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _processing || _sessions.length <= 1 ? null : _logoutEverywhere,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out Everywhere'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._sessions.map((s) => _buildSessionCard(s)),
        const SizedBox(height: 12),
        Text(
          'Sessions are created whenever you sign in to the Book Rabbit owner panel.',
          style: TextStyle(color: context.subTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSessionCard(VendorSession session) {
    final isCurrent = session.isCurrentSession;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? const Color(0xFFFF7B42) : context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isCurrent ? const Color(0xFFFF7B42) : context.subCardBg).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(_deviceIcon(session), color: isCurrent ? Colors.white : context.subTextColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _deviceLabel(session),
                        style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7B42).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'This device',
                          style: TextStyle(color: Color(0xFFFF7B42), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  session.lastSeen != null
                      ? 'Last seen ${_relativeTime(session.lastSeen!)}'
                      : 'Signed in recently',
                  style: TextStyle(color: context.subTextColor, fontSize: 12),
                ),
                if (session.ip != null)
                  Text(
                    'IP ${session.ip}',
                    style: TextStyle(color: context.subTextColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              onPressed: _processing ? null : () => _logoutSession(session),
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 20),
            ),
        ],
      ),
    );
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso.replaceFirst('Z', '')).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 30) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

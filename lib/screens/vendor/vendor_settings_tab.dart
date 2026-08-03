import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';
import 'vendor_profile_page.dart';
import 'vendor_bank_page.dart';
import 'vendor_billing_page.dart';
import 'vendor_edit_ground_page.dart';
import 'vendor_sessions_page.dart';

/// Settings home: list of account sections. Each row opens a dedicated page.
class VendorSettingsTab extends StatelessWidget {
  final VendorDashboard dashboard;
  final Future<void> Function() onRefresh;

  const VendorSettingsTab({
    super.key,
    required this.dashboard,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ownerName = dashboard.owner?['owner_name'] as String?;
    final phone = dashboard.owner?['phone'] as String?;

    final sections = <(IconData, String, String, Widget Function())>[
      (
        Icons.business_outlined,
        'Business Profile',
        'Owner / business name and contact details',
        () => VendorProfilePage(dashboard: dashboard, onRefresh: onRefresh),
      ),
      (
        Icons.account_balance_outlined,
        'Bank Account',
        'Where your payouts are sent',
        () => VendorBankPage(dashboard: dashboard, onRefresh: onRefresh),
      ),
      (
        Icons.credit_card_outlined,
        'Billing',
        'Manage subscriptions and payment history',
        () => VendorBillingPage(dashboard: dashboard, onRefresh: onRefresh),
      ),
      (
        Icons.stadium_outlined,
        'Edit Ground',
        'Update ground details and photos',
        () => VendorEditGroundPage(dashboard: dashboard, onRefresh: onRefresh),
      ),
      (
        Icons.devices_outlined,
        'Devices & Sessions',
        'Review and manage active logins',
        () => VendorSessionsPage(onRefresh: onRefresh),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Settings', style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Manage your account', style: TextStyle(color: context.subTextColor, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7B42).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (ownerName?.isNotEmpty ?? false) ? ownerName!.substring(0, 1).toUpperCase() : 'O',
                  style: const TextStyle(color: Color(0xFFFF7B42), fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName ?? 'Owner',
                      style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone ?? '—',
                      style: TextStyle(color: context.subTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < sections.length; i++)
                _SectionRow(
                  icon: sections[i].$1,
                  title: sections[i].$2,
                  subtitle: sections[i].$3,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => sections[i].$4()),
                  ),
                  showDivider: i < sections.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SectionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.borderColor))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.subCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF7B42), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: context.subTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.subTextColor),
          ],
        ),
      ),
    );
  }
}

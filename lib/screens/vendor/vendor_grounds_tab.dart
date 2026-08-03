import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';
import 'vendor_add_ground_page.dart';
import 'vendor_edit_ground_page.dart';

/// Manage listed venues: overview cards + add/edit entry points.
class VendorGroundsTab extends StatelessWidget {
  final VendorDashboard dashboard;
  final Future<void> Function() onRefresh;

  const VendorGroundsTab({
    super.key,
    required this.dashboard,
    required this.onRefresh,
  });

  Future<void> _addGround(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const VendorAddGroundPage(),
      ),
    );
    if (created == true) onRefresh();
  }

  void _editGround(BuildContext context, VendorGround ground) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VendorEditGroundPage(
          dashboard: dashboard,
          initialGroundId: ground.id,
          onRefresh: onRefresh,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grounds = dashboard.grounds;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage', style: TextStyle(color: const Color(0xFFFF7B42), fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(
                    'My Grounds',
                    style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your listed venues and sports',
                    style: TextStyle(color: context.subTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _addGround(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Ground'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7B42),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (grounds.isEmpty)
          VendorEmptyState(
            icon: Icons.stadium_outlined,
            title: 'No grounds yet',
            subtitle: 'List your first ground to start receiving bookings',
            action: ElevatedButton.icon(
              onPressed: () => _addGround(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Ground'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7B42),
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 760;
            final cards = grounds.map((g) => _buildGroundCard(context, g)).toList();
            if (!twoCol) {
              return Column(children: cards);
            }
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [for (final c in cards) SizedBox(width: 420, child: c)],
            );
          }),
      ],
    );
  }

  Widget _buildGroundCard(BuildContext context, VendorGround ground) {
    final statusColor = groundStatusColor(context, ground.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 5, color: statusColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.subCardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(ground.icon, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ground.name,
                            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ground.address,
                            style: TextStyle(color: context.subTextColor, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ground.type,
                            style: TextStyle(color: const Color(0xFFFF7B42), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    statusPill(context, ground.status, statusColor),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _GroundStat(label: 'Bookings', value: '${ground.confirmedBookings}'),
                    const SizedBox(width: 8),
                    _GroundStat(label: 'Revenue', value: formatInr(ground.revenue)),
                    const SizedBox(width: 8),
                    _GroundStat(label: 'Per Hour', value: '₹${ground.pricePerHour}'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '🕐 ${format12h(ground.openTime)} – ${format12h(ground.closeTime)} · ${ground.operatingDays.isEmpty ? 'All days' : ground.operatingDays.join(', ')}',
                  style: TextStyle(color: context.subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _editGround(context, ground),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textColor,
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Edit Ground →', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundStat extends StatelessWidget {
  final String label;
  final String value;
  const _GroundStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.subCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: context.subTextColor, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

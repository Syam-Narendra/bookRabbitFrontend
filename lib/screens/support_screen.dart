import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // Track expanded FAQ index (null = all collapsed, 0..3 = open item index)
  int? _expandedFaqIndex;

  Future<void> _launchUrlStr(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  final List<Map<String, dynamic>> _faqs = const [
    {
      'icon': Icons.calendar_today_outlined,
      'question': 'How do I book a ground?',
      'answer':
          'Select your ground from the Discover tab, choose your preferred date & time slot, and confirm your booking with instant online payment.',
    },
    {
      'iconText': '₹',
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept all major UPI apps (GPay, PhonePe, Paytm), Credit & Debit Cards, Net Banking, and digital wallets.',
    },
    {
      'icon': Icons.cancel_outlined,
      'question': 'What is the cancellation policy?',
      'answer':
          'All confirmed bookings are final. Cancellation or rescheduling is subject to venue vendor discretion as detailed in our Terms & Conditions.',
    },
    {
      'icon': Icons.headset_mic_outlined,
      'question': 'How can I contact customer support?',
      'answer':
          'You can reach us directly via Email (support@bookrabbit.in), Phone call (+91 98765 43210), or WhatsApp (+91 98765 43210). We\'re always here to help!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9FB);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final mutedColor = isDark ? const Color(0xFF98989E) : const Color(0xFF6E6E73);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F5);
    const orangeColor = Color(0xFFF2693F);

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          const mascotAsset = 'assets/images/rabbit_support_half.png';
          const fallbackMascot = 'assets/images/rabbit_support.png';

          return Column(
            children: [
              // ── Header Banner ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF7A2F), Color(0xFFF2693F)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isWide ? 960 : double.infinity),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Mascot image sitting flush at bottom line (bottom: 0) on the RIGHT side
                            Positioned(
                              bottom: 0,
                              right: isWide ? 24 : 12,
                              child: Image.asset(
                                mascotAsset,
                                height: isWide ? 220 : 165,
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomCenter,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  fallbackMascot,
                                  height: isWide ? 220 : 165,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/sports_bunnies.png',
                                    height: isWide ? 220 : 165,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),

                            // Foreground Content (Top nav + Text Greeting)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 24 : 16,
                                12,
                                isWide ? 24 : 16,
                                isWide ? 20 : 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Top Navigation bar row
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Support',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 36), // Balance title
                                    ],
                                  ),
                                  SizedBox(height: isWide ? 24 : 16),

                                  // Greeting Row: Text on LEFT, Mascot reserved space on RIGHT for all screens
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'We\'re here\nto help you!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isWide ? 32 : 26,
                                                fontWeight: FontWeight.bold,
                                                height: 1.2,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Have a question or need assistance?\nOur team is always ready to support you.',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: isWide ? 15 : 13,
                                                height: 1.4,
                                              ),
                                            ),
                                            SizedBox(height: isWide ? 16 : 8),
                                          ],
                                        ),
                                      ),
                                      // Reserved space for Mascot on RIGHT
                                      SizedBox(width: isWide ? 200 : 135),
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
                ),
              ),

              // ── Scrollable Body ───────────────────────────────────────────
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isWide ? 960 : 720),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 24 : 16,
                        isWide ? 28 : 20,
                        isWide ? 24 : 16,
                        40,
                      ),
                      children: [
                        // ── Contact Us Section ────────────────────────────────
                        Text(
                          'Contact Us',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isWide ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ).animate().fade(duration: 300.ms).slideX(begin: -0.05),

                        const SizedBox(height: 14),

                        // Contact Cards: Row on Wide screens (2 columns), Column on Mobile
                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: _buildContactCard(
                                  context,
                                  icon: Icons.email_rounded,
                                  title: 'Email Us',
                                  highlightText: 'support@bookrabbit.in',
                                  subtitle: 'We reply within 24 hours',
                                  cardBg: cardBg,
                                  textColor: textColor,
                                  mutedColor: mutedColor,
                                  borderColor: borderColor,
                                  orangeColor: orangeColor,
                                  onTap: () => _launchUrlStr('mailto:support@bookrabbit.in'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildContactCard(
                                  context,
                                  icon: Icons.chat_bubble_rounded,
                                  title: 'WhatsApp Us',
                                  highlightText: '+91 98765 43210',
                                  subtitle: 'Quick chat support',
                                  cardBg: cardBg,
                                  textColor: textColor,
                                  mutedColor: mutedColor,
                                  borderColor: borderColor,
                                  orangeColor: orangeColor,
                                  onTap: () => _launchUrlStr('https://wa.me/919876543210'),
                                ),
                              ),
                            ],
                          ).animate().fade(delay: 100.ms).slideY(begin: 0.1)
                        else
                          Column(
                            children: [
                              _buildContactCard(
                                context,
                                icon: Icons.email_rounded,
                                title: 'Email Us',
                                highlightText: 'support@bookrabbit.in',
                                subtitle: 'We usually reply within 24 hours',
                                cardBg: cardBg,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                orangeColor: orangeColor,
                                onTap: () => _launchUrlStr('mailto:support@bookrabbit.in'),
                              ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                              const SizedBox(height: 12),
                              _buildContactCard(
                                context,
                                icon: Icons.chat_bubble_rounded,
                                title: 'WhatsApp Us',
                                highlightText: '+91 98765 43210',
                                subtitle: 'Quick chat support',
                                cardBg: cardBg,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                orangeColor: orangeColor,
                                onTap: () => _launchUrlStr('https://wa.me/919876543210'),
                              ).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                            ],
                          ),

                        SizedBox(height: isWide ? 32 : 28),

                        // ── FAQs Section (Dropdown Accordion) ──────────────────
                        Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isWide ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ).animate().fade(delay: 250.ms).slideX(begin: -0.05),

                        const SizedBox(height: 14),

                        // FAQ Container Card with Accordion Dropdowns
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Column(
                            children: List.generate(_faqs.length, (index) {
                              final faq = _faqs[index];
                              final isExpanded = _expandedFaqIndex == index;
                              final isFirst = index == 0;
                              final isLast = index == _faqs.length - 1;

                              return _buildDropdownFaqItem(
                                context,
                                index: index,
                                icon: faq['icon'] as IconData?,
                                iconText: faq['iconText'] as String?,
                                question: faq['question'] as String,
                                answer: faq['answer'] as String,
                                isExpanded: isExpanded,
                                isFirst: isFirst,
                                isLast: isLast,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                orangeColor: orangeColor,
                              );
                            }),
                          ),
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Contact Card Builder ─────────────────────────────────────────────────

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String highlightText,
    required String subtitle,
    required Color cardBg,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color orangeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFF2693F),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    highlightText,
                    style: const TextStyle(
                      color: Color(0xFFF2693F),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Trailing Chevron Button
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFFF2693F), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dropdown FAQ Accordion Item Builder ─────────────────────────────────

  Widget _buildDropdownFaqItem(
    BuildContext context, {
    required int index,
    IconData? icon,
    String? iconText,
    required String question,
    required String answer,
    required bool isExpanded,
    required bool isFirst,
    required bool isLast,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color orangeColor,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedFaqIndex = isExpanded ? null : index;
            });
          },
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isExpanded ? orangeColor.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(16) : Radius.zero,
                bottom: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isExpanded ? orangeColor : const Color(0xFFFFF0EB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: iconText != null
                            ? Text(
                                iconText,
                                style: TextStyle(
                                  color: isExpanded ? Colors.white : orangeColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Icon(
                                icon,
                                color: isExpanded ? Colors.white : orangeColor,
                                size: 18,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Question text
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          color: isExpanded ? orangeColor : textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Snappy Minimal Rotating Chevron Icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? orangeColor.withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: isExpanded ? orangeColor : mutedColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                // Minimal Inline Expandable Answer Dropdown with Smooth Fade
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: isExpanded
                      ? AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: isExpanded ? 1.0 : 0.0,
                          curve: Curves.easeOutCubic,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10, left: 52, right: 8),
                            child: Text(
                              answer,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: borderColor, indent: 68),
      ],
    );
  }
}

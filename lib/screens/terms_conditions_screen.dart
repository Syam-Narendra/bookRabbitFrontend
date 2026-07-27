import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  int _selectedTab = 0; // 0: Customer Terms, 1: Vendor Terms

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9FB);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final mutedColor = isDark ? const Color(0xFF98989E) : const Color(0xFF6E6E73);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E0E0);
    const orangeColor = Color(0xFFF2693F);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24.0 : 16.0,
                  vertical: 20.0,
                ),
                children: [
                  // ── Hero Banner ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF7A2F), Color(0xFFF2693F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.description, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'BOOK RABBIT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please read these terms carefully before using Book Rabbit.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Last Updated: July 27, 2026',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms).slideY(begin: 0.05),

                  const SizedBox(height: 20),

                  // ── Tab Segmented Switcher ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? orangeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Customer Terms',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedTab == 0 ? Colors.white : mutedColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? orangeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Vendor Terms',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedTab == 1 ? Colors.white : mutedColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Terms Content ─────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _selectedTab == 0
                        ? _buildCustomerTerms(cardColor, textColor, mutedColor, borderColor, orangeColor)
                        : _buildVendorTerms(cardColor, textColor, mutedColor, borderColor, orangeColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Customer Terms ───────────────────────────────────────────────────────

  Widget _buildCustomerTerms(
      Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color orangeColor) {
    return Column(
      key: const ValueKey('customer_terms'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreambleCard(cardColor, textColor, mutedColor, borderColor),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '1. About Book Rabbit',
          [
            'Book Rabbit is an online platform that enables users to discover, view, and book sports grounds, turfs, courts, arenas, and other recreational venues offered by independent venue owners, operators, and vendors ("Vendors").',
            'Book Rabbit acts solely as a technology intermediary and booking facilitator.',
            'Book Rabbit does not own, operate, manage, control, supervise, or maintain any venue listed on the Platform unless explicitly stated otherwise.',
            'All venue-related services are provided directly by the respective Vendor.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '2. Eligibility',
          [
            'By using the Platform, you represent and warrant that:',
            '• You are legally capable of entering into a binding contract.',
            '• The information provided by you is accurate and complete.',
            '• You will use the Platform only for lawful purposes.',
            'Book Rabbit reserves the right to suspend or terminate accounts found to contain false, misleading, or fraudulent information.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '3. Booking Confirmation',
          [
            'A booking shall be considered confirmed only when:',
            '1. Payment has been successfully completed; and',
            '2. A booking confirmation has been generated by the Platform.',
            'Customers are responsible for verifying their booking details immediately after receiving confirmation.',
            'Book Rabbit shall not be responsible for errors caused by incorrect information provided by the customer.',
          ],
        ),
        const SizedBox(height: 16),
        // Highlighted Alert Box for No Cancellation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: orangeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: orangeColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: orangeColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '4. No Cancellation Policy (ALL BOOKINGS ARE FINAL)',
                    style: TextStyle(
                      color: orangeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Once a booking has been confirmed, it cannot be cancelled, modified, transferred, rescheduled, or refunded through Book Rabbit.',
                style: TextStyle(color: textColor, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'Customers acknowledge and agree that Book Rabbit does not provide cancellation facilities after booking confirmation. Any cancellation request, rescheduling request, goodwill refund, compensation, or booking modification shall be solely at the discretion of the respective Vendor.',
                style: TextStyle(color: mutedColor, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '5. Vendor Responsibility',
          [
            'The Vendor is solely responsible for:',
            '• Venue availability, access, facilities, and maintenance.',
            '• Venue safety, security, and compliance with local laws.',
            '• Honoring confirmed bookings.',
            'Any dispute regarding venue quality, condition, cleanliness, availability, staff behavior, safety, amenities, or services shall be resolved directly between the customer and the Vendor.',
            'Book Rabbit shall not be liable for any act, omission, negligence, misconduct, delay, cancellation, or failure by any Vendor.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '6. Refund Claims for Vendor Non-Performance',
          [
            'If a Vendor fails to provide access to a venue despite a valid confirmed booking, the customer must contact Book Rabbit and submit a complaint within 24 hours from the time the booking was created on the Platform.',
            'Customers may be required to provide evidence including booking confirmation, payment receipt, photographs, videos, or communication records.',
            'Complaints or refund claims submitted after 24 hours from booking creation time shall not be eligible for review through Book Rabbit.',
            'After 24 hours, all disputes, settlements, compensations, and refunds shall be handled directly between customer and Vendor.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '7. Failed Transactions',
          [
            'A booking shall not be considered successful unless a valid booking confirmation is generated by the Platform.',
            'If payment is deducted but no booking confirmation is generated, the transaction shall be considered a failed transaction.',
            'Eligible refunds for failed transactions may take up to 7 working days to process and reflect, subject to payment gateway and bank timelines.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '8. WhatsApp Notifications',
          [
            'WhatsApp notifications are provided as an optional convenience feature.',
            'Message delivery depends on third-party services and network availability. Failure or delay of messages shall not create liability for Book Rabbit.',
            'Customers should verify booking status directly through the Platform.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '9. Chargebacks & Payment Disputes',
          [
            'Customers agree to contact Book Rabbit before initiating any chargeback or payment reversal.',
            'Fraudulent or bad-faith chargebacks may result in account suspension, permanent termination, and legal action where permitted by law.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '10. User Conduct & Liability',
          [
            'Users agree not to provide false information, use stolen payment methods, interfere with Platform operations, or abuse Vendors/staff.',
            'Limitation of Liability: Book Rabbit shall not be liable for venue closures, injury, property damage, or consequential losses. Total liability shall not exceed the booking amount paid.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '11. Force Majeure & Intellectual Property',
          [
            'Book Rabbit shall not be liable for failures resulting from natural disasters, government actions, internet outages, or power failures.',
            'All logos, content, software, and trademarks are property of Book Rabbit.',
          ],
        ),
        const SizedBox(height: 16),
        _buildContactCard(cardColor, textColor, mutedColor, borderColor, orangeColor),
      ],
    );
  }

  // ─── Vendor Terms ─────────────────────────────────────────────────────────

  Widget _buildVendorTerms(
      Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color orangeColor) {
    return Column(
      key: const ValueKey('vendor_terms'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '1. Vendor Registration & Listing',
          [
            'By listing a venue on Book Rabbit, Vendors agree to provide accurate information regarding venue pricing, availability, operating hours, amenities, and location.',
            'Vendors must maintain updated schedule calendars on the Platform to prevent double bookings.',
            'Book Rabbit reserves the right to review, approve, or reject venue listings at its discretion.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '2. Honoring Bookings & Non-Performance',
          [
            'Vendors must honor all confirmed customer bookings generated through the Platform.',
            'If a Vendor fails to provide access to a confirmed customer, the Vendor shall be responsible for full refund processing and any associated compensation.',
            'Repeated non-performance or customer complaints may result in listing suspension or removal from Book Rabbit.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '3. Payouts & Platform Fees',
          [
            'Payouts for completed bookings are settled to the Vendor’s bank account according to agreed settlement cycles (T+1 / T+2 working days).',
            'Book Rabbit deducts applicable platform service fees before remitting net booking amounts to the Vendor.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          cardColor,
          textColor,
          mutedColor,
          borderColor,
          '4. Safety & Legal Compliance',
          [
            'Vendors are solely responsible for ensuring venue safety, security, structural integrity, lighting, and emergency facilities.',
            'Vendors must maintain all necessary local municipal licenses, permissions, and insurance required to operate sports venues.',
          ],
        ),
        const SizedBox(height: 16),
        _buildContactCard(cardColor, textColor, mutedColor, borderColor, orangeColor),
      ],
    );
  }

  // ─── Helper Cards ─────────────────────────────────────────────────────────

  Widget _buildPreambleCard(Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        'By accessing, browsing, registering on, or using Book Rabbit ("Platform", "Book Rabbit", "we", "our", or "us"), you agree to be bound by these Terms & Conditions. If you do not agree to these Terms, you must not use the Platform.',
        style: TextStyle(color: textColor, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSectionCard(
      Color cardColor, Color textColor, Color mutedColor, Color borderColor, String title, List<String> paragraphs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                p,
                style: TextStyle(color: mutedColor, fontSize: 13, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
      Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color orangeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('For support, complaints, or inquiries, reach us at:',
              style: TextStyle(color: mutedColor, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_outlined, color: orangeColor, size: 16),
              const SizedBox(width: 8),
              Text('support@bookrabbit.in',
                  style: TextStyle(color: orangeColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.language, color: orangeColor, size: 16),
              const SizedBox(width: 8),
              Text('https://book.arabbit.in',
                  style: TextStyle(color: orangeColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'By using the Platform, you acknowledge that you have read, understood, and agreed to these Terms & Conditions.',
            style: TextStyle(color: mutedColor, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

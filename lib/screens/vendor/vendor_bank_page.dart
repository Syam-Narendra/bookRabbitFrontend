import 'package:flutter/material.dart';
import '../../models/vendor_models.dart';
import '../../services/api_client.dart';
import '../../services/vendor_auth_service.dart';
import '../../theme/app_theme.dart';

/// Bank account: shows current bank info + verification status, and lets the
/// owner update the details (validated identically to the backend).
class VendorBankPage extends StatefulWidget {
  final VendorDashboard dashboard;
  final Future<void> Function() onRefresh;

  const VendorBankPage({
    super.key,
    required this.dashboard,
    required this.onRefresh,
  });

  @override
  State<VendorBankPage> createState() => _VendorBankPageState();
}

class _VendorBankPageState extends State<VendorBankPage> {
  final _holderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountController = TextEditingController();
  final _confirmController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _isSaving = false;

  VendorBankAccount get _bank => widget.dashboard.bankAccount;

  @override
  void initState() {
    super.initState();
    _holderController.text = _bank.accountHolderName ?? '';
    _bankNameController.text = _bank.bankName ?? '';
    _ifscController.text = _bank.ifscCode ?? '';
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _confirmController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  bool get _readOnly => _bank.exists;

  Future<void> _save() async {
    final accountNumber = _accountController.text.replaceAll(RegExp(r'\D'), '');
    final confirm = _confirmController.text.replaceAll(RegExp(r'\D'), '');
    final ifsc = _ifscController.text.trim().toUpperCase();

    if (_holderController.text.trim().isEmpty) {
      _showError('Account holder name is required.');
      return;
    }
    if (_bankNameController.text.trim().isEmpty) {
      _showError('Bank name is required.');
      return;
    }
    if (!RegExp(r'^\d{9,18}$').hasMatch(accountNumber)) {
      _showError('Enter a valid 9–18 digit account number.');
      return;
    }
    if (accountNumber != confirm) {
      _showError('Account numbers do not match.');
      return;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      _showError('Invalid IFSC (e.g. SBIN0001234).');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await VendorAuthService.updateBankDetails(
        accountHolderName: _holderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: accountNumber,
        confirmAccountNumber: confirm,
        ifscCode: ifsc,
      );
      await widget.onRefresh();
      if (!mounted) return;
      _showSuccess('Bank details updated');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e.message);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF2E8443),
    ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFD32F2F),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bank = _bank;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Bank Account', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Account',
                            style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Where your payouts are sent',
                            style: TextStyle(color: context.subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (bank.exists)
                      _BankStatusPill(
                        label: bank.isVerified ? '✓ Verified' : '⏳ Pending',
                        color: bank.isVerified ? const Color(0xFF2E8443) : const Color(0xFFF59E0B),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (bank.exists) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.subCardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Bank', value: bank.bankName ?? '—'),
                        _InfoRow(label: 'Account No.', value: bank.accountNumber ?? '—'),
                        _InfoRow(label: 'IFSC', value: bank.ifscCode ?? '—', last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Update Bank Details',
                    style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your account details are being reviewed by Razorpay. Updates take 1–2 business days.',
                    style: TextStyle(color: context.subTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildField(_holderController, 'Account Holder Name', 'As it appears on passbook', readOnly: _readOnly),
                const SizedBox(height: 14),
                _buildField(_bankNameController, 'Bank Name', 'e.g. HDFC Bank', readOnly: _readOnly),
                const SizedBox(height: 14),
                _buildField(
                  _accountController,
                  'Account Number',
                  '9–18 digits',
                  keyboardType: TextInputType.number,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  _confirmController,
                  'Confirm Account Number',
                  'Re-enter account number',
                  keyboardType: TextInputType.number,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  _ifscController,
                  'IFSC Code',
                  'e.g. SBIN0001234',
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7B42),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Update Bank Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint, {
    bool readOnly = false,
    bool obscure = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: TextStyle(color: context.textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: readOnly ? context.subCardBg : context.cardBg,
        hintStyle: TextStyle(color: context.subTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7B42)),
        ),
      ),
    );
  }
}

class _BankStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _BankStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _InfoRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: context.subTextColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

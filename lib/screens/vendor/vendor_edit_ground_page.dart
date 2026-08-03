import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vendor_models.dart';
import '../../services/api_client.dart';
import '../../services/vendor_auth_service.dart';
import '../../theme/app_theme.dart';
import 'vendor_helpers.dart';

/// Edit an existing ground: picker (when opened from Settings), editable
/// details, photo management (delete existing / add new), and save.
class VendorEditGroundPage extends StatefulWidget {
  final VendorDashboard dashboard;
  final String? initialGroundId;
  final Future<void> Function() onRefresh;

  const VendorEditGroundPage({
    super.key,
    required this.dashboard,
    this.initialGroundId,
    required this.onRefresh,
  });

  @override
  State<VendorEditGroundPage> createState() => _VendorEditGroundPageState();
}

class _VendorEditGroundPageState extends State<VendorEditGroundPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedGroundId;
  String _groundType = 'Cricket';
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  Set<String> _operatingDays = {...kAllDays};
  List<XFile> _newImages = [];
  bool _isSaving = false;

  VendorGround? get _ground {
    for (final g in widget.dashboard.grounds) {
      if (g.id == _selectedGroundId) return g;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedGroundId = widget.initialGroundId ?? widget.dashboard.grounds.firstOrNull?.id;
    _loadGround(_ground);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _loadGround(VendorGround? g) {
    if (g == null) return;
    _nameController.text = g.name;
    _priceController.text = g.pricePerHour > 0 ? '${g.pricePerHour}' : '';
    _addressController.text = g.address;
    _cityController.text = g.city ?? '';
    _pincodeController.text = g.pincode ?? '';
    _groundType = VendorAuthService.groundTypes.contains(g.type) ? g.type : g.type;
    _openTime = _toTimeOfDay(g.openTime);
    _closeTime = _toTimeOfDay(g.closeTime);
    _operatingDays = g.operatingDays.isEmpty ? {...kAllDays} : g.operatingDays.toSet();
  }

  void _onGroundChanged(String? id) {
    setState(() {
      _selectedGroundId = id;
      _newImages = [];
    });
    _loadGround(_ground);
  }

  TimeOfDay _toTimeOfDay(String? time) {
    if (time == null || time.isEmpty) return const TimeOfDay(hour: 6, minute: 0);
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 6;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _to24h(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isOpen}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _openTime = picked;
      } else {
        _closeTime = picked;
      }
    });
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      limit: 6 - _newImages.length,
    );
    if (picked.isEmpty) return;
    setState(() => _newImages = [..._newImages, ...picked].take(6).toList());
  }

  bool _validate() {
    final ground = _ground;
    if (ground == null) {
      _showError('Select a ground to edit.');
      return false;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('Ground name is required.');
      return false;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showError('Enter a valid price per hour.');
      return false;
    }
    if (_openTime.hour == _closeTime.hour && _openTime.minute == _closeTime.minute) {
      _showError('Opening and closing times must differ.');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError('Ground address is required.');
      return false;
    }
    if (_operatingDays.isEmpty) {
      _showError('Select at least one operating day.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final ground = _ground!;
    setState(() => _isSaving = true);
    try {
      await VendorAuthService.updateGround(
        groundId: ground.id,
        name: _nameController.text.trim(),
        groundType: _groundType,
        address: _addressController.text.trim(),
        pricePerHour: int.tryParse(_priceController.text.trim()) ?? ground.pricePerHour,
        openTime: _to24h(_openTime),
        closeTime: _to24h(_closeTime),
        operatingDays: _operatingDays.toList(),
      );
      if (_newImages.isNotEmpty) {
        await VendorAuthService.uploadGroundImages(ground.id, _newImages);
      }
      await widget.onRefresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ground updated', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFF2E8443),
      ));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e.message);
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    final ground = _ground!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from the ground?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await VendorAuthService.deleteGroundImage(ground.id, imageUrl);
      await widget.onRefresh();
      if (!mounted) return;
      _loadGround(_ground);
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFD32F2F),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ground = _ground;
    final hasGrounds = widget.dashboard.grounds.isNotEmpty;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Edit Ground', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.initialGroundId == null) ...[
                  _buildGroundPicker(hasGrounds),
                  const SizedBox(height: 20),
                ],
                if (!hasGrounds)
                  VendorEmptyState(
                    icon: Icons.stadium_outlined,
                    title: 'No grounds yet',
                    subtitle: 'Add a ground before editing.',
                  )
                else if (ground == null)
                  VendorEmptyState(
                    icon: Icons.error_outline,
                    title: 'No ground selected',
                    subtitle: 'Pick a ground from the list to edit it.',
                  )
                else ...[
                  _buildDetails(ground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroundPicker(bool hasGrounds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Ground', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (hasGrounds)
          GroundFilterDropdown(
            grounds: widget.dashboard.grounds,
            selectedId: _selectedGroundId,
            onChanged: _onGroundChanged,
            allLabel: 'Select a ground…',
          ),
      ],
    );
  }

  Widget _buildDetails(VendorGround ground) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ground.icon} ${ground.name}',
          style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Status: ${ground.status}',
          style: TextStyle(color: context.subTextColor, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Ground Name', 'e.g. Alpha Cricket Arena'),
        const SizedBox(height: 14),
        _buildTypeDropdown(),
        const SizedBox(height: 14),
        _buildTextField(
          _priceController,
          'Price per Hour (₹)',
          'e.g. 600',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTimeField('Opens At', _openTime, isOpen: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeField('Closes At', _closeTime, isOpen: false)),
          ],
        ),
        const SizedBox(height: 18),
        Text('Operating Days', style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in kAllDays)
              GestureDetector(
                onTap: () => setState(() {
                  if (_operatingDays.contains(day)) {
                    _operatingDays.remove(day);
                  } else {
                    _operatingDays.add(day);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _operatingDays.contains(day) ? const Color(0xFFFF7B42) : context.subCardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: _operatingDays.contains(day) ? Colors.white : context.subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _buildTextField(_addressController, 'Ground Address', 'Full address', maxLines: 2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_cityController, 'City', 'City'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _pincodeController,
                'PIN Code',
                '6-digit',
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ground Photos', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${ground.images.length + _newImages.length}/6 · tap ✕ to remove', style: TextStyle(color: context.subTextColor, fontSize: 12)),
        const SizedBox(height: 12),
        if (ground.images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < ground.images.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        ground.images[i],
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          color: context.subCardBg,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => _deleteImage(ground.images[i]),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (_newImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _newImages.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _newImages[i].path,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          color: context.subCardBg,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _newImages.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (ground.images.length + _newImages.length < 6) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: context.subCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 30, color: context.subTextColor),
                  const SizedBox(height: 6),
                  Text('Add photos (PNG / JPG)', style: TextStyle(color: context.subTextColor, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
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
                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(color: context.textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: context.subCardBg,
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

  Widget _buildTypeDropdown() {
    final items = VendorAuthService.groundTypes;
    final effectiveType = items.contains(_groundType) ? _groundType : _groundType;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveType,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: context.subTextColor),
          dropdownColor: context.cardBg,
          style: TextStyle(color: context.textColor, fontSize: 15),
          items: [
            if (!items.contains(_groundType))
              DropdownMenuItem(value: _groundType, child: Text(_groundType)),
            for (final type in items)
              DropdownMenuItem(
                value: type,
                child: Text('${VendorAuthService.groundIcons[type] ?? '🏟️'} $type'),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _groundType = v);
          },
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, {required bool isOpen}) {
    return GestureDetector(
      onTap: () => _pickTime(isOpen: isOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.subCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: context.subTextColor, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: context.subTextColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  time.format(context),
                  style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

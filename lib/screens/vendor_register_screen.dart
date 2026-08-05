import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:go_router/go_router.dart';
import '../router/route_extensions.dart';
import '../services/api_client.dart';
import '../services/vendor_auth_service.dart';
import '../theme/app_theme.dart';

class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  // Form Controllers
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _groundNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mapSearchController = TextEditingController();

  // Selected State
  String _selectedSport = 'Cricket';
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  final Set<String> _selectedDays = {
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  };

  List<XFile> _pickedImages = [];
  bool _isPhoneVerified = false;
  bool _isSendingOtp = false;
  bool _isSubmitting = false;
  String? _sentDevOtp;

  // Map & OpenStreetMap Location State
  double _mapLat = 17.3850; // Default Hyderabad coordinates
  double _mapLng = 78.4867;
  double _mapZoom = 14.0;
  bool _isLocating = false;
  String _pinnedAddress = '';

  // Search Results state
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  final List<String> _allDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  final List<Map<String, String>> _sports = [
    {'name': 'Cricket', 'icon': '🏏'},
    {'name': 'Football', 'icon': '⚽'},
    {'name': 'Badminton', 'icon': '🏸'},
    {'name': 'Tennis', 'icon': '🎾'},
    {'name': 'Basketball', 'icon': '🏀'},
    {'name': 'Volleyball', 'icon': '🏐'},
    {'name': 'Table Tennis', 'icon': '🏓'},
    {'name': 'Squash', 'icon': '🎱'},
    {'name': 'Hockey', 'icon': '🏒'},
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    if (VendorAuthService.currentOwner != null) {
      final owner = VendorAuthService.currentOwner!;
      _phoneController.text = owner.phone;
      if (owner.ownerName != null && owner.ownerName!.isNotEmpty) {
        _ownerNameController.text = owner.ownerName!;
      }
      _isPhoneVerified = true;
      // Router guard handles redirect to dashboard for already-logged-in vendors.
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _groundNameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _mapSearchController.dispose();
    super.dispose();
  }

  // Calculate completion percentage (0 - 100)

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _to24h(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  int get _operatingHoursCount {
    int openMinutes = _openTime.hour * 60 + _openTime.minute;
    int closeMinutes = _closeTime.hour * 60 + _closeTime.minute;
    if (closeMinutes <= openMinutes) {
      closeMinutes += 24 * 60;
    }
    return ((closeMinutes - openMinutes) / 60).round();
  }

  // ── OTP Handlers ─────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      final devOtp = await VendorAuthService.sendOtp(phone);
      setState(() {
        _sentDevOtp = devOtp;
        _isSendingOtp = false;
      });

      if (!mounted) return;
      _showOtpDialog(phone, devOtp: devOtp);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      _showSnackBar('Failed to send OTP. Please try again.', isError: true);
    }
  }

  void _showOtpDialog(String phone, {String? devOtp}) {
    final otpController = TextEditingController();
    if (devOtp != null && devOtp.isNotEmpty) {
      otpController.text = devOtp;
    }
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: modalContext.cardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verify Phone Number',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: modalContext.textColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit OTP sent to +91 $phone',
                      style: TextStyle(
                        fontSize: 14,
                        color: modalContext.subTextColor,
                      ),
                    ),
                    if (devOtp != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFFF7A2F,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'DEV OTP: $devOtp',
                          style: const TextStyle(
                            color: Color(0xFFFF7A2F),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: modalContext.subCardBg,
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: modalContext.subTextColor.withValues(
                            alpha: 0.5,
                          ),
                          letterSpacing: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: modalContext.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF7A2F),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final otp = otpController.text.trim();
                                if (otp.length != 6) {
                                  _showSnackBar(
                                    'Enter a 6-digit OTP',
                                    isError: true,
                                  );
                                  return;
                                }
                                setModalState(() => isVerifying = true);
                                try {
                                  await VendorAuthService.verifyOtp(phone, otp);
                                  if (mounted) {
                                    setState(() {
                                      _isPhoneVerified = true;
                                    });
                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
                                    _showSnackBar(
                                      'Phone number verified successfully!',
                                    );
                                  }
                                } on ApiException catch (e) {
                                  setModalState(() => isVerifying = false);
                                  _showSnackBar(e.message, isError: true);
                                } catch (_) {
                                  setModalState(() => isVerifying = false);
                                  _showSnackBar(
                                    'Invalid OTP. Please check and retry.',
                                    isError: true,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A2F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── OpenStreetMap & Location Handlers ─────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _mapLat = position.latitude;
          _mapLng = position.longitude;
        });

        // Reverse geocode position via OpenStreetMap Nominatim
        await _reverseGeocodeOsm(position.latitude, position.longitude);
      } else {
        _showSnackBar('Location permission denied.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Unable to fetch current location.', isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocodeOsm(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(url, headers: {'User-Agent': 'BookRabbitApp/1.0'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final road =
            (addr['road'] as String?) ??
            (addr['pedestrian'] as String?) ??
            (addr['suburb'] as String?) ??
            (addr['neighbourhood'] as String?) ??
            '';
        final city =
            (addr['city'] as String?) ??
            (addr['town'] as String?) ??
            (addr['village'] as String?) ??
            (addr['municipality'] as String?) ??
            (addr['county'] as String?) ??
            '';
        final postcode = (addr['postcode'] as String?) ?? '';
        final fullAddr = data['display_name'] as String? ?? '';

        if (mounted) {
          setState(() {
            _addressController.text = fullAddr.isNotEmpty ? fullAddr : road;
            if (city.isNotEmpty) _cityController.text = city;
            if (postcode.isNotEmpty) _pincodeController.text = postcode;
            _pinnedAddress = fullAddr.isNotEmpty
                ? fullAddr
                : '$road, $city, $postcode';
          });
        }
      }
    } catch (_) {}
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeLocationSearch(query.trim());
    });
  }

  Future<void> _executeLocationSearch(String query) async {
    if (query.isEmpty) return;
    try {
      List<Map<String, dynamic>> parsedResults = [];

      // 1. Try Photon OpenStreetMap API (Fast, zero CORS issues)
      try {
        final photonUrl = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5',
        );
        final res = await http
            .get(photonUrl)
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>? ?? [];
          for (final f in features) {
            final geom = f['geometry'] as Map<String, dynamic>? ?? {};
            final coords = geom['coordinates'] as List<dynamic>? ?? [];
            final props = f['properties'] as Map<String, dynamic>? ?? {};

            if (coords.length >= 2) {
              final lng = double.tryParse(coords[0].toString()) ?? 0.0;
              final lat = double.tryParse(coords[1].toString()) ?? 0.0;

              final name = (props['name'] as String?) ?? '';
              final street = (props['street'] as String?) ?? name;
              final city =
                  (props['city'] as String?) ??
                  (props['state'] as String?) ??
                  '';
              final postcode = (props['postcode'] as String?) ?? '';

              final subtitleList = [
                props['city'],
                props['state'],
                props['country'],
              ].where((s) => s != null && s.toString().isNotEmpty).join(', ');

              parsedResults.add({
                'title': name.isNotEmpty ? name : street,
                'subtitle': subtitleList.isNotEmpty
                    ? subtitleList
                    : 'OpenStreetMap location',
                'lat': lat,
                'lng': lng,
                'street': street,
                'city': city,
                'postcode': postcode,
              });
            }
          }
        }
      } catch (_) {}

      // 2. Fallback to Nominatim if Photon yields no results
      if (parsedResults.isEmpty) {
        final nomUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&addressdetails=1&limit=5',
        );
        final res = await http
            .get(nomUrl, headers: {'User-Agent': 'BookRabbitApp/1.0'})
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final results = json.decode(res.body) as List<dynamic>;
          for (final r in results) {
            final item = r as Map<String, dynamic>;
            final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
            final lng = double.tryParse(item['lon'].toString()) ?? 0.0;
            final name = (item['display_name'] as String?) ?? query;
            final addr = item['address'] as Map<String, dynamic>? ?? {};
            final road =
                (addr['road'] as String?) ?? (addr['suburb'] as String?) ?? '';
            final city =
                (addr['city'] as String?) ??
                (addr['town'] as String?) ??
                (addr['village'] as String?) ??
                '';
            final postcode = (addr['postcode'] as String?) ?? '';

            parsedResults.add({
              'title': road.isNotEmpty ? road : name.split(',').first,
              'subtitle': name,
              'lat': lat,
              'lng': lng,
              'street': road,
              'city': city,
              'postcode': postcode,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = parsedResults;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = item['lat'] as double;
    final lng = item['lng'] as double;
    final title = item['title'] as String;
    final subtitle = item['subtitle'] as String;
    final city = item['city'] as String;
    final postcode = item['postcode'] as String;

    setState(() {
      _mapLat = lat;
      _mapLng = lng;
      _mapZoom = 15.0;
      _pinnedAddress = '$title, $subtitle';
      _mapSearchController.text = title;
      _searchResults = [];
      _isSearching = false;

      _addressController.text = '$title, $subtitle';
      if (city.isNotEmpty) _cityController.text = city;
      if (postcode.isNotEmpty) _pincodeController.text = postcode;
    });

    FocusScope.of(context).unfocus();
  }

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 80,
        limit: 6 - _pickedImages.length,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _pickedImages = [..._pickedImages, ...pickedFiles].take(6).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting images.', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  // ── Time Pickers ──────────────────────────────────────────────────────────

  Future<void> _selectTime(bool isOpenTime) async {
    final initial = isOpenTime ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFF7A2F),
              onPrimary: Colors.white,
              surface: context.cardBg,
              onSurface: context.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  // ── Submit Registration ──────────────────────────────────────────────────

  Future<void> _submitRegistration() async {
    final ownerName = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    final groundName = _groundNameController.text.trim();
    final priceStr = _priceController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (ownerName.isEmpty) {
      _showSnackBar('Please enter owner name.', isError: true);
      return;
    }
    if (phone.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit phone number.',
        isError: true,
      );
      return;
    }
    if (email.isNotEmpty && !email.contains('@')) {
      _showSnackBar('Please enter a valid email address.', isError: true);
      return;
    }
    if (groundName.isEmpty) {
      _showSnackBar('Please enter ground name.', isError: true);
      return;
    }
    final price = int.tryParse(priceStr);
    if (price == null || price <= 0) {
      _showSnackBar('Please enter a valid price per hour.', isError: true);
      return;
    }
    if (address.isEmpty) {
      _showSnackBar('Please enter ground address.', isError: true);
      return;
    }
    if (_selectedDays.isEmpty) {
      _showSnackBar('Please select at least one operating day.', isError: true);
      return;
    }

    // Check if phone needs OTP verification first
    if (!_isPhoneVerified && VendorAuthService.currentOwner == null) {
      await _sendOtp();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Update owner name if logged in
      if (ownerName.isNotEmpty && VendorAuthService.currentOwner != null) {
        await VendorAuthService.updateProfile(ownerName);
      }

      // 2. Create ground with OpenStreetMap lat/lng coordinates
      final mapsUrl =
          'https://www.openstreetmap.org/?mlat=$_mapLat&mlon=$_mapLng#map=16/$_mapLat/$_mapLng';
      final order = await VendorAuthService.createGround(
        name: groundName,
        groundType: _selectedSport,
        address: address,
        pricePerHour: price,
        openTime: _to24h(_openTime),
        closeTime: _to24h(_closeTime),
        operatingDays: _selectedDays.toList(),
        city: city.isEmpty ? null : city,
        pincode: pincode.isEmpty ? null : pincode,
        mapsUrl: mapsUrl,
      );

      final groundId = order['groundId'] as String?;

      // 3. Upload images if any
      if (groundId != null && _pickedImages.isNotEmpty) {
        await VendorAuthService.uploadGroundImages(groundId, _pickedImages);
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Show success modal & navigate to dashboard
      _showSuccessDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(
        'An error occurred during ground registration. Please try again.',
        isError: true,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Registration Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ground "${_groundNameController.text}" is now registered and live for bookings!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.subTextColor),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.goVendorDashboard();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Vendor Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF388E3C),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build Method ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goUserLogin();
        }
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 900;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 960 : double.infinity,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Banner
                      _buildHeaderAndBanner(),
                      const SizedBox(height: 20),

                      // Form Body
                      _buildStep1OwnerInfo(isWide: isDesktop || isTablet),
                      const SizedBox(height: 16),

                      _buildStep2MapLocation(),
                      const SizedBox(height: 16),

                      _buildStep3GroundDetails(isWide: isDesktop || isTablet),
                      const SizedBox(height: 16),

                      _buildStep4OperatingHours(isWide: isDesktop || isTablet),
                      const SizedBox(height: 16),

                      _buildStep5GroundImages(),
                      const SizedBox(height: 24),

                      // Footer Banner & Register Button
                      _buildFooterAction(isWide: isDesktop || isTablet),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),  // closes SafeArea
      ),    // closes Scaffold
    );      // closes PopScope
  }

  // ── Header & Banner Widget ────────────────────────────────────────────────

  Widget _buildHeaderAndBanner() {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF231B17)
            : const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF7A2F).withValues(alpha: 0.15),
        ),
      ),
      child: Stack(
        children: [
          // Background Rabbit Mascot (Top Right)
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/images/vendor-login-rabbit.png',
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Nav Row
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goUserLogin();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    'Register Your Ground',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Lifetime Free Offer Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBg.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF7A2F).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFFFF7A2F),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.textColor,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Lifetime Free Offer: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF7A2F),
                                ),
                              ),
                              TextSpan(
                                text:
                                    'No payment required. Your ground goes live immediately.',
                                style: TextStyle(
                                  color: context.subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Owner Information ─────────────────────────────────────────────

  Widget _buildStep1OwnerInfo({required bool isWide}) {
    return _buildCardWrapper(
      stepNumber: '1',
      title: 'Owner Information',
      child: Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Owner Name *',
                    hint: 'Your full name',
                    controller: _ownerNameController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildPhoneFieldWithOtp()),
              ],
            )
          else ...[
            _buildTextField(
              label: 'Owner Name *',
              hint: 'Your full name',
              controller: _ownerNameController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _buildPhoneFieldWithOtp(),
          ],
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Email Address *',
            hint: 'owner@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneFieldWithOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.subCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPhoneVerified
                  ? const Color(0xFF4CAF50)
                  : context.borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {
                    _isPhoneVerified = false;
                  }),
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      color: context.subTextColor.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_isPhoneVerified)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: _isSendingOtp ? null : _sendOtp,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF7A2F),
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              color: Color(0xFFFF7A2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (_sentDevOtp != null && _sentDevOtp!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'DEV OTP Sent: $_sentDevOtp',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFFF7A2F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 2: Ground Details ────────────────────────────────────────────────

  Widget _buildStep3GroundDetails({required bool isWide}) {
    return _buildCardWrapper(
      stepNumber: '3',
      title: 'Ground Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    label: 'Ground Name *',
                    hint: 'e.g. Alpha Cricket Ground',
                    controller: _groundNameController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    label: 'Price / Hour (₹) *',
                    hint: '500',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            )
          else ...[
            _buildTextField(
              label: 'Ground Name *',
              hint: 'e.g. Alpha Cricket Ground',
              controller: _groundNameController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'Price / Hour (₹) *',
              hint: '500',
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),

          // Sport Type Selection
          Text(
            'Sport Type *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _sports.map((sport) {
              final isSelected = _selectedSport == sport['name'];
              return ChoiceChip(
                showCheckmark: false,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sport['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      sport['name']!,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFFF7A2F)
                            : context.textColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFFFF3EC),
                backgroundColor: context.subCardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF7A2F)
                        : context.borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSport = sport['name']!);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Ground Address *',
            hint: 'Full street address',
            controller: _addressController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'City *',
                    hint: 'e.g. Hyderabad',
                    controller: _cityController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'PIN Code *',
                    hint: '500001',
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            )
          else ...[
            _buildTextField(
              label: 'City *',
              hint: 'e.g. Hyderabad',
              controller: _cityController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'PIN Code *',
              hint: '500001',
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 3: OpenStreetMap & Leaflet Location ───────────────────────────────────────

  Widget _buildStep2MapLocation() {
    return _buildCardWrapper(
      stepNumber: '2',
      title: '📍 Pin Location on Map',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help players find your ground easily. Search for your address, click "My Location" to auto-detect via GPS, or tap on the map to drop a pin. Your address fields will be auto-filled.',
            style: TextStyle(
              fontSize: 12.5,
              color: context.subTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Search + My Location Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.subCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, right: 6),
                        child: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _mapSearchController,
                          onChanged: _onSearchQueryChanged,
                          onSubmitted: (q) => _executeLocationSearch(q),
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search address or landmark...',
                            hintStyle: TextStyle(
                              color: context.subTextColor.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_mapSearchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _mapSearchController.clear();
                            setState(() {
                              _searchResults = [];
                              _isSearching = false;
                            });
                          },
                        ),
                      InkWell(
                        onTap: () =>
                            _executeLocationSearch(_mapSearchController.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7A2F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isLocating ? null : _getCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      _isLocating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF7A2F),
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: Color(0xFFFF7A2F),
                              size: 16,
                            ),
                      const SizedBox(width: 6),
                      const Text(
                        'My Location',
                        style: TextStyle(
                          color: Color(0xFFFF7A2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Live OpenStreetMap Autocomplete Search Results Overlay
          if (_isSearching) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF7A2F),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Searching OpenStreetMap...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF7A2F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF7A2F).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: context.borderColor),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFFFF7A2F),
                      size: 20,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.subTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSearchResult(item),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Interactive Leaflet + OpenStreetMap Map Engine Widget
          LeafletOsmMap(
            lat: _mapLat,
            lng: _mapLng,
            zoom: _mapZoom,
            onZoomChanged: (newZoom) {
              setState(() => _mapZoom = newZoom);
            },
            onLocationChanged: (newLat, newLng) {
              setState(() {
                _mapLat = newLat;
                _mapLng = newLng;
              });
              _reverseGeocodeOsm(newLat, newLng);
            },
          ),
          const SizedBox(height: 10),

          if (_pinnedAddress.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF7A2F).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color: Color(0xFFFF7A2F),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pinnedAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF7A2F),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ── Step 4: Operating Hours ──────────────────────────────────────────────

  Widget _buildStep4OperatingHours({required bool isWide}) {
    final totalHours = _operatingHoursCount;

    return _buildCardWrapper(
      stepNumber: '4',
      title: 'Operating Hours',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operating Days *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Day Selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _allDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedDays.length > 1) {
                            _selectedDays.remove(day);
                          }
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF7A2F)
                            : context.subCardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Time Selectors Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opens At (24h)',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.subTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _selectTime(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.subCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _to24h(_openTime),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: context.subTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Closes At (24h)',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.subTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _selectTime(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.subCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _to24h(_closeTime),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: context.subTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Hours Calculation Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF7A2F).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFFF7A2F),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatTimeOfDay(_openTime)} → ${_formatTimeOfDay(_closeTime)}  •  ${totalHours}h open per day',
                  style: const TextStyle(
                    color: Color(0xFFFF7A2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Ground Images ─────────────────────────────────────────────────

  Widget _buildStep5GroundImages() {
    return _buildCardWrapper(
      stepNumber: '5',
      title: 'Ground Images',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashed Upload Box
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: const Color(0xFFFF7A2F).withValues(alpha: 0.5),
                borderRadius: 16,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFFFF7A2F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Click to upload or drag & drop',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG, JPG up to 10 MB - Max 6 images',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Picked Images Gallery Preview
          if (_pickedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 6),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: _pickedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 0,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Footer Action & Submit ────────────────────────────────────────────────

  Widget _buildFooterAction({required bool isWide}) {
    final giftBanner = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFFF7A2F),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Join free for lifetime',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFFFF7A2F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No payment, no subscription. Your ground is listed permanently.',
                  style: TextStyle(fontSize: 11.5, color: context.subTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final submitBtn = SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Register Free - Lifetime Access',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );

    return Column(
      children: [
        if (isWide)
          Row(
            children: [
              Expanded(flex: 5, child: giftBanner),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: submitBtn),
            ],
          )
        else ...[
          giftBanner,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: submitBtn),
        ],
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'By submitting you agree to our Terms & Conditions.',
                style: TextStyle(fontSize: 11.5, color: context.subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helper UI Wrappers ───────────────────────────────────────────────────

  Widget _buildCardWrapper({
    required String stepNumber,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A2F),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            color: context.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.subCardBg,
            hintText: hint,
            hintStyle: TextStyle(
              color: context.subTextColor.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFFFF7A2F),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Leaflet OpenStreetMap Engine Widget (flutter_map) ────────────────────────

class LeafletOsmMap extends StatefulWidget {
  final double lat;
  final double lng;
  final double zoom;
  final ValueChanged<double>? onZoomChanged;
  final Function(double lat, double lng)? onLocationChanged;

  const LeafletOsmMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.zoom,
    this.onZoomChanged,
    this.onLocationChanged,
  });

  @override
  State<LeafletOsmMap> createState() => _LeafletOsmMapState();
}

class _LeafletOsmMapState extends State<LeafletOsmMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant LeafletOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent changed lat/lng (e.g. from search or GPS), move the map
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _mapController.move(
        LatLng(widget.lat, widget.lng),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // flutter_map (Leaflet) with OpenStreetMap tiles
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.lat, widget.lng),
                initialZoom: widget.zoom,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, point) {
                  widget.onLocationChanged?.call(
                    point.latitude,
                    point.longitude,
                  );
                },
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    // Update zoom if changed by gesture
                    widget.onZoomChanged?.call(position.zoom);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bookrabbit.app',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.lat, widget.lng),
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A2F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF7A2F,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Zoom Controls (Top Left)
            Positioned(
              top: 12,
              left: 12,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      final newZoom = (_mapController.camera.zoom + 1).clamp(
                        3.0,
                        19.0,
                      );
                      _mapController.move(
                        _mapController.camera.center,
                        newZoom,
                      );
                      widget.onZoomChanged?.call(newZoom);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: context.textColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final newZoom = (_mapController.camera.zoom - 1).clamp(
                        3.0,
                        19.0,
                      );
                      _mapController.move(
                        _mapController.camera.center,
                        newZoom,
                      );
                      widget.onZoomChanged?.call(newZoom);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 18,
                        color: context.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Leaflet & OpenStreetMap Attribution (Bottom Right)
            Positioned(
              bottom: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.cardBg.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      size: 12,
                      color: Color(0xFFFF7A2F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Leaflet | © OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ────────────────────────────────────────────────────

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double distance = 0.0;
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;

    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

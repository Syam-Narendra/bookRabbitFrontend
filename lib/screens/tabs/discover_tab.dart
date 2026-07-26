import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
// geocoding is NOT supported on web — we use Nominatim for web instead
import 'package:geocoding/geocoding.dart' as geo;
import '../ground_details_screen.dart';
import '../../services/ground_service.dart';

class DiscoverTab extends StatefulWidget {
  final VoidCallback? onProfileTapped;

  const DiscoverTab({super.key, this.onProfileTapped});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> allGrounds = [];
  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic>? _selectedGround;

  // Location state
  String _locationArea = 'Detecting...';
  String _locationAddress = 'Fetching your location';
  bool _isDetectingLocation = false;
  StreamSubscription<Position>? _positionStream;

  static final List<Map<String, dynamic>> categoryData = [
    {'name': 'All', 'icon': Icons.auto_awesome},
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Pickleball', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  @override
  void initState() {
    super.initState();
    _fetchGrounds();
    _initLocationDetection();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ─── Location Logic ──────────────────────────────────────────────────────────

  Future<void> _initLocationDetection() async {
    setState(() => _isDetectingLocation = true);

    // On web, isLocationServiceEnabled is not implemented — skip it
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationFallback('Location services off');
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setLocationFallback('Location access denied');
      if (!kIsWeb) _showPermissionDeniedBanner();
      return;
    }

    _startLocationStream();
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 100, // update every 100 metres
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _reverseGeocode(position),
      onError: (_) => _setLocationFallback('Unable to detect'),
    );
  }

  /// Reverse geocode using [geocoding] on mobile, Nominatim on web.
  Future<void> _reverseGeocode(Position position) async {
    try {
      if (kIsWeb) {
        await _reverseGeocodeWeb(position.latitude, position.longitude);
      } else {
        await _reverseGeocodeMobile(position.latitude, position.longitude);
      }
    } catch (_) {
      _setLocationFallback('Could not resolve address');
    }
  }

  Future<void> _reverseGeocodeMobile(double lat, double lng) async {
    final placemarks = await geo.placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final area = p.subLocality?.isNotEmpty == true
          ? p.subLocality!
          : p.locality?.isNotEmpty == true
              ? p.locality!
              : 'Current Location';
      final address = [p.locality, p.administrativeArea, p.country]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');

      if (!mounted) return;
      setState(() {
        _locationArea = area;
        _locationAddress = address.isNotEmpty ? address : 'Location detected';
        _isDetectingLocation = false;
      });
    }
  }

  /// Uses OpenStreetMap Nominatim (no API key, CORS-friendly) for web.
  Future<void> _reverseGeocodeWeb(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2&lat=$lat&lon=$lng&accept-language=en',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'BookRabbit/1.0'},
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      // Prefer suburb > city_district > city > town > county
      final area = (addr['suburb'] as String?)?.isNotEmpty == true
          ? addr['suburb'] as String
          : (addr['city_district'] as String?)?.isNotEmpty == true
              ? addr['city_district'] as String
              : (addr['city'] as String?)?.isNotEmpty == true
                  ? addr['city'] as String
                  : (addr['town'] as String?)?.isNotEmpty == true
                      ? addr['town'] as String
                      : (addr['county'] as String?) ?? 'Current Location';

      final city = (addr['city'] as String?) ??
          (addr['town'] as String?) ??
          (addr['county'] as String?) ??
          '';
      final state = (addr['state'] as String?) ?? '';
      final country = (addr['country'] as String?) ?? '';

      final addressStr = [city, state, country]
          .where((s) => s.isNotEmpty)
          .join(', ');

      if (!mounted) return;
      setState(() {
        _locationArea = area;
        _locationAddress = addressStr.isNotEmpty ? addressStr : 'Location detected';
        _isDetectingLocation = false;
      });
    } else {
      throw Exception('Nominatim error: ${response.statusCode}');
    }
  }

  void _setLocationFallback(String reason) {
    if (!mounted) return;
    setState(() {
      _locationArea = 'Select Location';
      _locationAddress = reason;
      _isDetectingLocation = false;
    });
  }

  /// Re-detect once (called from the bottom sheet).
  Future<void> _detectOnce(BuildContext sheetContext) async {
    setState(() => _isDetectingLocation = true);
    if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);

    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationFallback('Location services off');
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setLocationFallback('Location access denied');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await _reverseGeocode(position);
      // Restart live stream
      await _positionStream?.cancel();
      _startLocationStream();
    } catch (_) {
      _setLocationFallback('Unable to detect');
    }
  }

  void _showPermissionDeniedBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF2C2C2E),
        content: const Text(
          'Location permission denied. Tap to open settings.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Open Settings',
                style: TextStyle(color: Color(0xFFE54F3F))),
          ),
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Dismiss',
                style: TextStyle(color: Color(0xFF98989E))),
          ),
        ],
      ),
    );
  }

  // ─── Grounds ─────────────────────────────────────────────────────────────────

  Future<void> _fetchGrounds() async {
    try {
      final grounds = await GroundService.fetchGrounds();
      setState(() {
        allGrounds = grounds;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // ─── Nominatim forward-geocode search ───────────────────────────────────────

  Timer? _searchDebounce;

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=jsonv2&addressdetails=1&limit=6&accept-language=en',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'BookRabbit/1.0'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // ─── Bottom Sheet ─────────────────────────────────────────────────────────────

  void _showLocationPickerBottomSheet() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void onSearchChanged(String query) {
              _searchDebounce?.cancel();
              if (query.trim().length < 2) {
                setModalState(() {
                  suggestions = [];
                  isSearching = false;
                });
                return;
              }
              setModalState(() => isSearching = true);
              _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
                final results = await _searchPlaces(query);
                if (ctx.mounted) {
                  setModalState(() {
                    suggestions = results;
                    isSearching = false;
                  });
                }
              });
            }

            void pickSuggestion(Map<String, dynamic> place) {
              final addr = place['address'] as Map<String, dynamic>? ?? {};
              final area =
                  (addr['suburb'] as String?)?.isNotEmpty == true
                      ? addr['suburb'] as String
                      : (addr['city_district'] as String?)?.isNotEmpty == true
                          ? addr['city_district'] as String
                          : (addr['city'] as String?)?.isNotEmpty == true
                              ? addr['city'] as String
                              : (addr['town'] as String?)?.isNotEmpty == true
                                  ? addr['town'] as String
                                  : (addr['county'] as String?) ??
                                      (place['display_name'] as String? ?? 'Location');

              final city = (addr['city'] as String?) ??
                  (addr['town'] as String?) ??
                  (addr['county'] as String?) ??
                  '';
              final state = (addr['state'] as String?) ?? '';
              final country = (addr['country'] as String?) ?? '';
              final fullAddress =
                  [city, state, country].where((s) => s.isNotEmpty).join(', ');

              _positionStream?.cancel();
              setState(() {
                _locationArea = area;
                _locationAddress =
                    fullAddress.isNotEmpty ? fullAddress : area;
              });
              Navigator.pop(modalContext);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3C),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Set Your Location',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ── GPS button ──────────────────────────────────────────────
                  InkWell(
                    onTap: _isDetectingLocation
                        ? null
                        : () => _detectOnce(modalContext),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE54F3F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE54F3F)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location,
                              color: Color(0xFFE54F3F), size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Use Current Location',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  _isDetectingLocation
                                      ? 'Fetching live location…'
                                      : '',
                                  style: const TextStyle(
                                      color: Color(0xFF98989E), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_isDetectingLocation)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE54F3F)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('OR SEARCH FOR A LOCATION',
                      style: TextStyle(
                          color: Color(0xFF98989E),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 12),

                  // ── Live search field ───────────────────────────────────────
                  TextField(
                    controller: searchController,
                    autofocus: false,
                    style: const TextStyle(color: Colors.white),
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Type a city, area or landmark…',
                      hintStyle:
                          const TextStyle(color: Color(0xFF98989E), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF98989E)),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE54F3F)),
                              ),
                            )
                          : searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Color(0xFF98989E), size: 18),
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() {
                                      suggestions = [];
                                      isSearching = false;
                                    });
                                  },
                                )
                              : null,
                    ),
                  ),

                  // ── Suggestions list ────────────────────────────────────────
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFF3A3A3C)),
                          itemBuilder: (_, i) {
                            final place = suggestions[i];
                            final displayName =
                                place['display_name'] as String? ?? '';
                            // Split display name: first part is the main name,
                            // rest is the address breadcrumb
                            final parts = displayName.split(', ');
                            final title = parts.first;
                            final subtitle = parts.length > 1
                                ? parts.skip(1).join(', ')
                                : '';
                            return InkWell(
                              onTap: () => pickSuggestion(place),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.location_on,
                                          color: Color(0xFFE54F3F), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              subtitle,
                                              style: const TextStyle(
                                                  color: Color(0xFF98989E),
                                                  fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  if (suggestions.isEmpty &&
                      !isSearching &&
                      searchController.text.trim().length >= 2) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.search_off,
                              color: Color(0xFF98989E), size: 18),
                          SizedBox(width: 10),
                          Text('No locations found',
                              style: TextStyle(
                                  color: Color(0xFF98989E), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _searchDebounce?.cancel();
      searchController.dispose();
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filteredGrounds = allGrounds.where((ground) {
      final matchesCategory = _selectedCategory == 'All' ||
          ground['category'] == _selectedCategory;
      final matchesSearch = ground['title']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: _selectedGround != null
          ? KeyedSubtree(
              key: ValueKey(_selectedGround!['id']),
              child: GroundDetailsScreen(
                ground: _selectedGround!,
                onBackPressed: () =>
                    setState(() => _selectedGround = null),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('discover_list'),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTopSearch(),
                  _buildChips(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth >= 1100
                            ? 4
                            : constraints.maxWidth >= 720
                                ? 3
                                : 2;
                        final bottomPad =
                            MediaQuery.of(context).size.width >= 720
                                ? 24.0
                                : 140.0;
                        final gridDelegate =
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.66,
                        );
                        if (isLoading) {
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                                16.0, 16.0, 16.0, bottomPad),
                            gridDelegate: gridDelegate,
                            itemCount: cols * 2,
                            itemBuilder: (context, index) {
                              return Shimmer.fromColors(
                                baseColor: const Color(0xFF2C2C2E),
                                highlightColor: const Color(0xFF3A3A3C),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12)))),
                                    const SizedBox(height: 8),
                                    Container(
                                        height: 14,
                                        width: double.infinity,
                                        color: Colors.white),
                                    const SizedBox(height: 4),
                                    Container(
                                        height: 12,
                                        width: 80,
                                        color: Colors.white),
                                    const SizedBox(height: 4),
                                    Container(
                                        height: 12,
                                        width: 120,
                                        color: Colors.white),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        if (hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Failed to load grounds',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchGrounds,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFE54F3F)),
                                  child: const Text('Retry',
                                      style: TextStyle(
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }
                        if (filteredGrounds.isEmpty) {
                          return const Center(
                              child: Text('No grounds found.',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16)));
                        }
                        return GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                              16.0, 16.0, 16.0, bottomPad),
                          gridDelegate: gridDelegate,
                          itemCount: filteredGrounds.length,
                          itemBuilder: (context, index) {
                            return _buildGroundCard(
                                    context, filteredGrounds[index])
                                .animate()
                                .fade(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    delay: Duration(
                                        milliseconds: index * 50))
                                .slideY(
                                    begin: 0.1,
                                    end: 0,
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showLocationPickerBottomSheet,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isDetectingLocation)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE54F3F)
                                .withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.4, 1.4),
                              duration:
                                  const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scale(
                              begin: const Offset(1.4, 1.4),
                              end: const Offset(1, 1),
                              duration:
                                  const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                            ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isDetectingLocation
                              ? const Color(0xFFE54F3F)
                                  .withValues(alpha: 0.15)
                              : const Color(0xFFEBEBF5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isDetectingLocation
                              ? Icons.gps_fixed
                              : Icons.location_on,
                          color: _isDetectingLocation
                              ? const Color(0xFFE54F3F)
                              : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 400),
                                child: Text(
                                  _locationArea,
                                  key: ValueKey(_locationArea),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _locationAddress,
                            key: ValueKey(_locationAddress),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onProfileTapped,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2E),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=100&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────────

  Widget _buildTopSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF323232),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Color(0xFF8E8E93), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search by ground name or sport',
                  hintStyle:
                      TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category chips ───────────────────────────────────────────────────────────

  Widget _buildChips() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: categoryData.length,
        itemBuilder: (context, index) {
          final data = categoryData[index];
          final category = data['name'] as String;
          final isSelected = category == _selectedCategory;
          final color = isSelected
              ? const Color(0xFFE54F3F)
              : const Color(0xFF8E8E93);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFFE54F3F)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(data['icon'] as IconData,
                      color: color, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Ground card ──────────────────────────────────────────────────────────────

  Widget _buildGroundCard(
      BuildContext context, Map<String, dynamic> ground) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGround = ground),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'ground_image_${ground['id'] ?? ground['title']}',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: ground['imageUrl'].startsWith('http')
                        ? NetworkImage(ground['imageUrl'])
                            as ImageProvider
                        : AssetImage(ground['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ground['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  ground['price'],
                  style: const TextStyle(
                      color: Color(0xFFE54F3F),
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '• ${ground['type']}',
                  style: const TextStyle(
                      color: Color(0xFF98989E), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Color(0xFF98989E), size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ground['city']?.toString().isNotEmpty == true
                      ? ground['city']
                      : ground['location'],
                  style: const TextStyle(
                      color: Color(0xFF98989E), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

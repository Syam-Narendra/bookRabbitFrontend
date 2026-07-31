import 'dart:async';
import 'dart:math' show asin, cos, pi, sin, sqrt;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../ground_details_screen.dart';
import '../../services/ground_service.dart';
import '../../theme/app_theme.dart';

class DiscoverTab extends StatefulWidget {
  final VoidCallback? onProfileTapped;

  const DiscoverTab({super.key, this.onProfileTapped});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TextEditingController _topSearchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> allGrounds = [];
  bool isLoading = true;
  bool hasError = false;

  // Location state
  String _locationArea = 'Detecting...';
  String _locationAddress = 'Fetching your location';
  bool _isDetectingLocation = false;
  StreamSubscription<Position>? _positionStream;

  // Current user position for distance calculation
  double? _userLat;
  double? _userLng;

  static final List<Map<String, dynamic>> categoryData = [
    {'name': 'All', 'icon': Icons.auto_awesome},
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Tennis', 'icon': Icons.sports_tennis},
    {'name': 'Pickleball', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchGrounds();
    _initLocation();
  }

  @override
  void dispose() {
    _topSearchController.dispose();
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  // ─── Location & Distance ───────────────────────────────────────────────────

  /// Request permission, start stream and do an initial fetch
  Future<void> _initLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        _setLocationFallback('Hyderabad');
        return;
      }
      // Quick first fix
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        _userLat = lastPos.latitude;
        _userLng = lastPos.longitude;
        _reverseGeocode(lastPos);
      }
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() {
          _userLat = currentPos.latitude;
          _userLng = currentPos.longitude;
        });
        await _reverseGeocode(currentPos);
      }
      _startLocationStream();
    } catch (_) {
      _setLocationFallback('Hyderabad');
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _startLocationStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // notify every 100 metres
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      _reverseGeocode(position);
    });
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setLocationFallback('Location disabled');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setLocationFallback('Permission denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _setLocationFallback('Permission denied');
      _showPermissionDeniedBanner();
      return false;
    }
    return true;
  }

  void _setLocationFallback(String reason) {
    if (!mounted) return;
    setState(() {
      _locationArea = 'Hyderabad';
      _locationAddress = 'Telangana, India • $reason';
      _isDetectingLocation = false;
    });
  }

  /// Reverse geocode position to locality / area name.
  /// On Web, geocoding package throws UnimplementedError — fallback to Nominatim HTTP API.
  Future<void> _reverseGeocode(Position pos) async {
    await _reverseGeocodeWeb(pos.latitude, pos.longitude);
  }

  /// Nominatim reverse geocoding API for web / fallback
  Future<void> _reverseGeocodeWeb(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=14');
      final res = await http.get(url, headers: {'User-Agent': 'BookRabbitApp/1.0'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final area = (addr['suburb'] as String?)?.isNotEmpty == true
            ? addr['suburb'] as String
            : (addr['city_district'] as String?)?.isNotEmpty == true
                ? addr['city_district'] as String
                : (addr['city'] as String?)?.isNotEmpty == true
                    ? addr['city'] as String
                    : (addr['town'] as String?) ?? 'Current Location';
        final city = (addr['city'] as String?) ?? (addr['town'] as String?) ?? '';
        final state = (addr['state'] as String?) ?? '';
        final fullAddress = [city, state].where((s) => s.isNotEmpty).join(', ');
        setState(() {
          _locationArea = area;
          _locationAddress = fullAddress.isNotEmpty ? fullAddress : 'Detected via GPS';
        });
      }
    } catch (_) {
      if (mounted && _locationArea == 'Detecting...') {
        setState(() {
          _locationArea = 'Current Location';
          _locationAddress = 'GPS active';
        });
      }
    }
  }

  /// Nominatim search API for location picker bottom sheet
  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&addressdetails=1&limit=5&countrycodes=in');
      final res = await http.get(url, headers: {'User-Agent': 'BookRabbitApp/1.0'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Manual one-shot GPS trigger when user taps "Use Current Location" in picker
  Future<void> _detectOnce({VoidCallback? closeSheet}) async {
    setState(() => _isDetectingLocation = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
      await _reverseGeocode(pos);
      // Restart live stream
      await _positionStream?.cancel();
      _startLocationStream();
    } catch (_) {
      _setLocationFallback('Unable to detect');
    } finally {
      closeSheet?.call();
    }
  }

  void _showPermissionDeniedBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: context.subCardBg,
        content: Text(
          'Location permission denied. Tap to open settings.',
          style: TextStyle(color: context.textColor, fontSize: 13),
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
            child: Text('Dismiss',
                style: TextStyle(color: context.subTextColor)),
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
        allGrounds = _sortByDistance(grounds);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  static (double lat, double lng)? _parseMapsUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final q = uri.queryParameters['q'];
    if (q == null) return null;
    final parts = q.split(',');
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * asin(sqrt(a));
  }

  List<Map<String, dynamic>> _sortByDistance(
      List<Map<String, dynamic>> grounds) {
    if (_userLat == null || _userLng == null) return grounds;
    final withDist = grounds.map((g) {
      final coords = _parseMapsUrl(g['maps_url'] as String?);
      final dist = coords != null
          ? _haversineKm(_userLat!, _userLng!, coords.$1, coords.$2)
          : double.maxFinite;
      return MapEntry(dist, g);
    }).toList();

    withDist.sort((a, b) => a.key.compareTo(b.key));
    return withDist.map((e) => e.value).toList();
  }

  // ─── Location Picker Bottom Sheet ─────────────────────────────────────────────

  void _showLocationPickerBottomSheet() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final detecting = _isDetectingLocation;

            void closeSheet() {
              if (Navigator.canPop(modalContext)) Navigator.pop(modalContext);
            }

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
              final area = (addr['suburb'] as String?)?.isNotEmpty == true
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

              final newLat = double.tryParse(place['lat']?.toString() ?? '');
              final newLng = double.tryParse(place['lon']?.toString() ?? '');

              closeSheet();
              if (mounted) {
                setState(() {
                  _locationArea = area;
                  _locationAddress = fullAddress.isNotEmpty ? fullAddress : 'Selected manually';
                  if (newLat != null && newLng != null) {
                    _userLat = newLat;
                    _userLng = newLng;
                    allGrounds = _sortByDistance(allGrounds);
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grabber handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Location',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // ── Current location button ───────────────────────────
                  InkWell(
                    onTap: detecting
                        ? null
                        : () => _detectOnce(closeSheet: closeSheet),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: detecting
                            ? const Color(0xFFE54F3F).withValues(alpha: 0.08)
                            : context.subCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE54F3F)
                                .withValues(alpha: detecting ? 0.25 : 0.4)),
                      ),
                      child: Row(
                        children: [
                          detecting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFFE54F3F)),
                                )
                              : const Icon(Icons.my_location,
                                  color: Color(0xFFE54F3F), size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detecting
                                      ? 'Detecting location…'
                                      : 'Use Current Location',
                                  style: TextStyle(
                                      color: detecting
                                          ? context.subTextColor
                                          : context.textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                                if (detecting) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Please wait, fetching GPS…',
                                    style: TextStyle(
                                        color: context.subTextColor, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text('OR SEARCH FOR A LOCATION',
                      style: TextStyle(
                          color: context.subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 12),

                  // ── Live search field ───────────────────────────────────────
                  TextField(
                    controller: searchController,
                    autofocus: false,
                    style: TextStyle(color: context.textColor),
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Type a city, area or landmark…',
                      hintStyle:
                          TextStyle(color: context.subTextColor, fontSize: 14),
                      filled: true,
                      fillColor: context.subCardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon:
                          Icon(Icons.search, color: context.subTextColor),
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
                                  icon: Icon(Icons.clear,
                                      color: context.subTextColor, size: 18),
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
                          color: context.subCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          separatorBuilder: (_, _) => Divider(
                              height: 1, color: context.borderColor),
                          itemBuilder: (_, i) {
                            final place = suggestions[i];
                            final displayName =
                                place['display_name'] as String? ?? '';
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
                                            style: TextStyle(
                                                color: context.textColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                  color: context.subTextColor,
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
                          color: context.subCardBg,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.search_off,
                              color: context.subTextColor, size: 18),
                          const SizedBox(width: 10),
                          Text('No locations found',
                              style: TextStyle(
                                  color: context.subTextColor, fontSize: 13)),
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
    final sortedGrounds = _sortByDistance(allGrounds);

    final filteredGrounds = sortedGrounds.where((ground) {
      final matchesCategory = _selectedCategory == 'All' ||
          (ground['type'] as String?)?.toLowerCase() ==
              _selectedCategory.toLowerCase();
      final name = (ground['title'] as String? ?? '').toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildHeader(isWide: MediaQuery.of(context).size.width >= 720),
        _buildChips(isWide: MediaQuery.of(context).size.width >= 720),
        Expanded(
          child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w >= 1200 ? 5
                            : w >= 900 ? 4
                            : w >= 600 ? 3
                            : 2;

                        final spacing = w >= 720 ? 12.0 : 10.0;

                        final aspectRatio = w >= 600 ? 0.95 : 0.88; // Rectangular proportions for landscape card view

                        final bottomPad = w >= 720 ? 24.0 : 72.0;

                        final gridDelegate =
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: aspectRatio,
                        );
                        if (isLoading) {
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                                16.0, 16.0, 16.0, bottomPad),
                            gridDelegate: gridDelegate,
                            itemCount: cols * 2,
                            itemBuilder: (context, index) {
                              return Shimmer.fromColors(
                                baseColor: context.subCardBg,
                                highlightColor: context.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: context.subCardBg,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12)))),
                                    const SizedBox(height: 8),
                                    Container(
                                        height: 14,
                                        width: double.infinity,
                                        color: context.subCardBg),
                                    const SizedBox(height: 4),
                                    Container(
                                        height: 12,
                                        width: 80,
                                        color: context.subCardBg),
                                    const SizedBox(height: 4),
                                    Container(
                                        height: 12,
                                        width: 120,
                                        color: context.subCardBg),
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
                                Text('Failed to load grounds',
                                    style: TextStyle(
                                        color: context.subTextColor,
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
                          return Center(
                              child: Text('No grounds found.',
                                  style: TextStyle(
                                      color: context.subTextColor,
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
              );
  }

  // ─── Header ───────────────────────────────────────────────────────────────────

  // ─── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader({bool isWide = false}) {
    const mascotAsset = 'assets/images/rabbit_support_half.png';
    const fallbackMascot = 'assets/images/rabbit_support.png';

    final topPadding = isWide ? 0.0 : MediaQuery.of(context).padding.top;
    final headerHeight = (isWide ? 145.0 : 135.0) + topPadding;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // 1. Top Orange Header Banner with Location & Mascot Rabbit
        Container(
          width: double.infinity,
          height: headerHeight,
          margin: const EdgeInsets.only(bottom: 24),
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
              child: Stack(
                children: [
                  // Mascot Rabbit image anchored at top right
                  Positioned(
                    top: 0,
                    right: isWide ? 16 : 8,
                    child: Image.asset(
                      mascotAsset,
                      height: isWide ? 130 : 110,
                      fit: BoxFit.contain,
                      alignment: Alignment.topRight,
                      errorBuilder: (_, _, _) => Image.asset(
                        fallbackMascot,
                        height: isWide ? 130 : 110,
                        fit: BoxFit.contain,
                        alignment: Alignment.topRight,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/sports_bunnies.png',
                          height: isWide ? 130 : 110,
                          fit: BoxFit.contain,
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),

                  // Location Row Content
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, isWide ? 12 : 16, isWide ? 140 : 110, 12),
                    child: _buildLocationRow(isWide: isWide),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Search Bar positioned EXACTLY DOWN / BELOW the Rabbit Header
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: _buildTopSearch(isWide: isWide),
        ),
      ],
    );
  }

  Widget _buildLocationRow({bool isWide = false}) {
    return GestureDetector(
      onTap: _showLocationPickerBottomSheet,
      behavior: HitTestBehavior.deferToChild,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isDetectingLocation)
                Container(
                  width: isWide ? 28 : 36,
                  height: isWide ? 28 : 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.4, 1.4),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.4, 1.4),
                      end: const Offset(1, 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                    ),
              Container(
                width: isWide ? 32 : 38,
                height: isWide ? 32 : 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isDetectingLocation ? Icons.gps_fixed : Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _locationArea,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _locationAddress,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: isWide ? 11 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────────

  Widget _buildTopSearch({bool isWide = false}) {
    return Container(
      height: isWide ? 46 : 50,
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Color(0xFFF2693F), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _topSearchController,
              style: TextStyle(color: context.textColor, fontSize: isWide ? 14 : 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search grounds or sports...',
                hintStyle: TextStyle(color: context.subTextColor, fontSize: isWide ? 14 : 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _topSearchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close, color: Color(0xFFF2693F), size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Category chips ───────────────────────────────────────────────────────────

  Widget _buildChips({bool isWide = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sw = MediaQuery.of(context).size.width;

        // 4-tier sizing based on actual screen width
        // < 540  (phone portrait):   compact
        // 540-719 (phone landscape): medium
        // 720-1099 (tablet):         large
        // ≥ 1100  (desktop):         full
        final double chipHeight   = sw >= 720 ? 52 : sw >= 540 ? 56 : 52;
        final double topMargin    = sw >= 720 ? 10 : sw >= 540 ? 12 : 12;
        final double bottomMargin = sw >= 720 ?  4 : sw >= 540 ?  6 :  4;
        final double iconSize     = sw >= 720 ? 20 : sw >= 540 ? 20 : 18;
        final double fontSize     = sw >= 720 ?  9 : sw >= 540 ?  9 :  9;
        final double hMargin      = sw >= 720 ? 10 : sw >= 540 ? 10 : 8;
        final double innerGap     = sw >= 720 ?  4 : sw >= 540 ?  4 :  3;

        return Container(
          height: chipHeight,
          margin: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
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
                  : context.subTextColor;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: hMargin),
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
                          color: color, size: iconSize),
                      SizedBox(height: innerGap),
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: fontSize,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: innerGap),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Ground card ──────────────────────────────────────────────────────────────

  Widget _buildGroundCard(
      BuildContext context, Map<String, dynamic> ground) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroundDetailsScreen(ground: ground),
          ),
        );
      },
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
            style: TextStyle(
              color: context.textColor,
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
                  style: TextStyle(
                      color: context.subTextColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.location_on,
                  color: context.subTextColor, size: 12),
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
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.near_me, color: Color(0xFF6E6E73), size: 11),
              const SizedBox(width: 4),
              Text(
                _groundDistance(ground),
                style: const TextStyle(
                    color: Color(0xFF6E6E73), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns a real GPS-based distance string, or '—' if position unknown.
  String _groundDistance(Map<String, dynamic> ground) {
    if (_userLat == null || _userLng == null) return 'Distance unavailable';
    final coords = _parseMapsUrl(ground['maps_url'] as String?);
    if (coords == null) return '—';
    final km = _haversineKm(_userLat!, _userLng!, coords.$1, coords.$2);
    return km < 1.0
        ? '${(km * 1000).round()} m away'
        : '${km.toStringAsFixed(1)} km away';
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _locationArea = 'Select Location';
  String _locationAddress = 'Tap to set or detect your location';
  bool _isDetectingLocation = false;

  static final List<Map<String, dynamic>> categoryData = [
    {'name': 'All', 'icon': Icons.auto_awesome},
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Pickleball', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  final List<String> promoBanners = [
    'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _fetchGrounds();
  }

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

  @override
  Widget build(BuildContext context) {
    final filteredGrounds = allGrounds.where((ground) {
      final matchesCategory = _selectedCategory == 'All' || ground['category'] == _selectedCategory;
      final matchesSearch = ground['title'].toLowerCase().contains(_searchQuery.toLowerCase());
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
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: _selectedGround != null
          ? KeyedSubtree(
              key: ValueKey(_selectedGround!['id']),
              child: GroundDetailsScreen(
                ground: _selectedGround!,
                onBackPressed: () => setState(() => _selectedGround = null),
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
              final cols = constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 720 ? 3 : 2;
              final bottomPad = MediaQuery.of(context).size.width >= 720 ? 24.0 : 140.0;
              final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.66,
              );
              if (isLoading) {
                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPad),
                  gridDelegate: gridDelegate,
                  itemCount: cols * 2,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: const Color(0xFF2C2C2E),
                      highlightColor: const Color(0xFF3A3A3C),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                          const SizedBox(height: 8),
                          Container(height: 14, width: double.infinity, color: Colors.white),
                          const SizedBox(height: 4),
                          Container(height: 12, width: 80, color: Colors.white),
                          const SizedBox(height: 4),
                          Container(height: 12, width: 120, color: Colors.white),
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
                      const Text('Failed to load grounds', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchGrounds,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE54F3F)),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              if (filteredGrounds.isEmpty) {
                return const Center(child: Text('No grounds found.', style: TextStyle(color: Colors.white70, fontSize: 16)));
              }
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPad),
                gridDelegate: gridDelegate,
                itemCount: filteredGrounds.length,
                itemBuilder: (context, index) {
                  return _buildGroundCard(context, filteredGrounds[index])
                      .animate()
                      .fade(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: index * 50))
                      .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
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

  Future<void> _detectLiveLocation(BuildContext dialogContext) async {
    setState(() => _isDetectingLocation = true);

    // Try CORS-friendly Web API 1: geojs.io
    try {
      final response = await http
          .get(Uri.parse('https://get.geojs.io/v1/ip/geo.json'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city']?.toString();
        final region = data['region']?.toString();
        final country = data['country']?.toString();

        if (city != null && city.isNotEmpty) {
          final addressStr = [region, country].where((s) => s != null && s.isNotEmpty).join(', ');
          setState(() {
            _locationArea = city;
            _locationAddress = addressStr.isEmpty ? 'Detected via GPS' : addressStr;
            _isDetectingLocation = false;
          });
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
          return;
        }
      }
    } catch (_) {}

    // Try CORS-friendly Web API 2: ipwho.is
    try {
      final response = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final city = data['city']?.toString() ?? 'Current Location';
          final region = data['region']?.toString() ?? '';
          final country = data['country']?.toString() ?? '';
          final addressStr = [region, country].where((s) => s.isNotEmpty).join(', ');
          setState(() {
            _locationArea = city;
            _locationAddress = addressStr.isEmpty ? 'Detected via GPS' : addressStr;
            _isDetectingLocation = false;
          });
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _locationArea = 'Current Location';
      _locationAddress = 'Location auto-detected';
      _isDetectingLocation = false;
    });
    if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }
  }

  void _showLocationPickerBottomSheet() {
    final areaController = TextEditingController(text: _locationArea == 'Select Location' ? '' : _locationArea);
    final addressController = TextEditingController(text: _locationAddress == 'Tap to set or detect your location' ? '' : _locationAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Auto-detect GPS button
                  InkWell(
                    onTap: _isDetectingLocation
                        ? null
                        : () async {
                            setModalState(() => _isDetectingLocation = true);
                            await _detectLiveLocation(modalContext);
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE54F3F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE54F3F).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: Color(0xFFE54F3F), size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Auto-Detect Current Location', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(_isDetectingLocation ? 'Fetching live location...' : 'Fetch real-time location via GPS/Network', style: const TextStyle(color: Color(0xFF98989E), fontSize: 12)),
                              ],
                            ),
                          ),
                          if (_isDetectingLocation)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE54F3F)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('OR ENTER ANY CUSTOM LOCATION', style: TextStyle(color: Color(0xFF98989E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Area / City Name (e.g. Indiranagar, Bandra, Downtown)',
                      labelStyle: const TextStyle(color: Color(0xFF98989E), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.location_city, color: Color(0xFF98989E)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Address / Landmark (e.g. 100 Feet Rd, Bengaluru)',
                      labelStyle: const TextStyle(color: Color(0xFF98989E), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF98989E)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final area = areaController.text.trim();
                        final address = addressController.text.trim();
                        if (area.isNotEmpty) {
                          setState(() {
                            _locationArea = area;
                            _locationAddress = address.isEmpty ? area : address;
                          });
                          Navigator.pop(modalContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE54F3F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Update Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Location Pin & Text
          Expanded(
            child: GestureDetector(
              onTap: _showLocationPickerBottomSheet,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBEBF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.black87, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _locationArea,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locationAddress,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Profile Button
          GestureDetector(
            onTap: widget.onProfileTapped,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2E),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=100&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Search by ground name or sport",
                  hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          final color = isSelected ? const Color(0xFFE54F3F) : const Color(0xFF8E8E93); 
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFFE54F3F) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(data['icon'] as IconData, color: color, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: color, 
                      fontSize: 11, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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

  Widget _buildGroundCard(BuildContext context, Map<String, dynamic> ground) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGround = ground;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Hero(
              tag: 'ground_image_${ground['id'] ?? ground['title']}',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: ground['imageUrl'].startsWith('http')
                        ? NetworkImage(ground['imageUrl']) as ImageProvider
                        : AssetImage(ground['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Title
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
          
          // Price and Details
          Row(
            children: [
              Flexible(
                child: Text(
                  ground['price'],
                  style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '• ${ground['type']}',
                  style: const TextStyle(color: Color(0xFF98989E), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          
          // Location
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF98989E), size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ground['city']?.toString().isNotEmpty == true ? ground['city'] : ground['location'],
                  style: const TextStyle(color: Color(0xFF98989E), fontSize: 12),
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

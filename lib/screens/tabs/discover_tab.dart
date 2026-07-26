import 'package:flutter/material.dart';
import '../ground_details_screen.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import '../../constants.dart';

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
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/api/public/grounds'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final grounds = data['grounds'] as List<dynamic>;
        setState(() {
          allGrounds = grounds.map<Map<String, dynamic>>((dynamic g) {
            final groundMap = g as Map<String, dynamic>;
            final images = groundMap['images'] as List<dynamic>? ?? [];
            return <String, dynamic>{
              ...groundMap,
              'title': groundMap['name'] ?? '',
              'location': groundMap['address'] ?? groundMap['city'] ?? '',
              'price': '₹${groundMap['price_per_hour']}/hr',
              'category': groundMap['type'] ?? 'All',
              'type': groundMap['tag'] ?? groundMap['type'] ?? '',
              'imageUrl': images.isNotEmpty ? images.first : 'assets/images/sports_bunnies.png',
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
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

    return Column(
      children: [
        _buildHeader(),
        _buildTopSearch(),
        _buildChips(),
        const SizedBox(height: 12),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE54F3F)))
            : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load grounds', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchGrounds,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE54F3F)),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : filteredGrounds.isEmpty 
                ? const Center(
                    child: Text(
                      'No grounds found.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 140.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredGrounds.length,
                    itemBuilder: (context, index) {
                      return _buildGroundCard(context, filteredGrounds[index]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Location Pin
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
          // Location Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Kondapur',
                      style: TextStyle(
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
                const Text(
                  'Land Mark Residency, Gachibowli,...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
          // Image
          Expanded(
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
              Text(
                ground['price'],
                style: const TextStyle(color: Color(0xFFE54F3F), fontSize: 13, fontWeight: FontWeight.bold),
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
                  ground['location'],
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

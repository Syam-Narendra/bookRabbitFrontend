import 'package:flutter/material.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static final List<String> categories = [
    'All',
    'Cricket',
    'Football',
    'Pickleball',
    'Basketball',
    'Badminton',
    'Volleyball'
  ];

  static final List<Map<String, dynamic>> allGrounds = [
    // 5 Cricket
    {'title': 'Greenfield Ground', 'location': 'Midtown', 'price': '₹600/hr', 'category': 'Cricket', 'type': 'Nets', 'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Oval Park Arena', 'location': 'Downtown', 'price': '₹1200/hr', 'category': 'Cricket', 'type': 'Full Ground', 'imageUrl': 'https://images.unsplash.com/photo-1518605368461-1ee7e53086eb?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Strikers Practice', 'location': 'Westside', 'price': '₹500/hr', 'category': 'Cricket', 'type': 'Nets', 'imageUrl': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=1935&auto=format&fit=crop'},
    {'title': 'Boundary Bashers', 'location': 'East End', 'price': '₹1500/hr', 'category': 'Cricket', 'type': 'Full Ground', 'imageUrl': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2067&auto=format&fit=crop'},
    {'title': 'Pitch Perfect', 'location': 'North Hills', 'price': '₹800/hr', 'category': 'Cricket', 'type': 'Turf', 'imageUrl': 'https://images.unsplash.com/photo-1624314138470-5a2f24623f10?q=80&w=1974&auto=format&fit=crop'},
    
    // 5 Football
    {'title': 'Goalazo Turf', 'location': 'South Park', 'price': '₹1000/hr', 'category': 'Football', 'type': '5v5', 'imageUrl': 'https://images.unsplash.com/photo-1518605368461-1ee7e53086eb?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Kickoff Arena', 'location': 'Midtown', 'price': '₹1800/hr', 'category': 'Football', 'type': '7v7', 'imageUrl': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=1935&auto=format&fit=crop'},
    {'title': 'Champions Field', 'location': 'Downtown', 'price': '₹2500/hr', 'category': 'Football', 'type': '11v11', 'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Street Soccer', 'location': 'East End', 'price': '₹900/hr', 'category': 'Football', 'type': 'Turf', 'imageUrl': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2067&auto=format&fit=crop'},
    {'title': 'Golden Boot', 'location': 'Westside', 'price': '₹1200/hr', 'category': 'Football', 'type': '5v5', 'imageUrl': 'https://images.unsplash.com/photo-1624314138470-5a2f24623f10?q=80&w=1974&auto=format&fit=crop'},
    
    // 5 Pickleball
    {'title': 'Pickle Point', 'location': 'North Hills', 'price': '₹400/hr', 'category': 'Pickleball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?q=80&w=1974&auto=format&fit=crop'},
    {'title': 'Smash Court', 'location': 'South Park', 'price': '₹450/hr', 'category': 'Pickleball', 'type': 'Outdoor', 'imageUrl': 'https://images.unsplash.com/photo-1587280501635-a19ee5aca3ab?q=80&w=2070&auto=format&fit=crop'},
    {'title': 'Dink Arena', 'location': 'Downtown', 'price': '₹500/hr', 'category': 'Pickleball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Paddle Club', 'location': 'Midtown', 'price': '₹350/hr', 'category': 'Pickleball', 'type': 'Outdoor', 'imageUrl': 'https://images.unsplash.com/photo-1518605368461-1ee7e53086eb?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Rally Courts', 'location': 'East End', 'price': '₹400/hr', 'category': 'Pickleball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=1935&auto=format&fit=crop'},
    
    // 5 Basketball
    {'title': 'Hoop Dreams', 'location': 'Westside', 'price': '₹700/hr', 'category': 'Basketball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2067&auto=format&fit=crop'},
    {'title': 'Swish Arena', 'location': 'Downtown', 'price': '₹600/hr', 'category': 'Basketball', 'type': 'Outdoor', 'imageUrl': 'https://images.unsplash.com/photo-1624314138470-5a2f24623f10?q=80&w=1974&auto=format&fit=crop'},
    {'title': 'Court Kings', 'location': 'North Hills', 'price': '₹800/hr', 'category': 'Basketball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Slam Dunk', 'location': 'South Park', 'price': '₹500/hr', 'category': 'Basketball', 'type': 'Outdoor', 'imageUrl': 'https://images.unsplash.com/photo-1518605368461-1ee7e53086eb?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Alley-Oop Center', 'location': 'East End', 'price': '₹750/hr', 'category': 'Basketball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=1935&auto=format&fit=crop'},
    
    // 5 Badminton
    {'title': 'Shuttle Masters', 'location': 'Midtown', 'price': '₹300/hr', 'category': 'Badminton', 'type': 'Wooden', 'imageUrl': 'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?q=80&w=1974&auto=format&fit=crop'},
    {'title': 'Smashers Club', 'location': 'Westside', 'price': '₹400/hr', 'category': 'Badminton', 'type': 'Synthetic', 'imageUrl': 'https://images.unsplash.com/photo-1587280501635-a19ee5aca3ab?q=80&w=2070&auto=format&fit=crop'},
    {'title': 'Feather Courts', 'location': 'Downtown', 'price': '₹350/hr', 'category': 'Badminton', 'type': 'Wooden', 'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Drop Shot Arena', 'location': 'North Hills', 'price': '₹450/hr', 'category': 'Badminton', 'type': 'Synthetic', 'imageUrl': 'https://images.unsplash.com/photo-1518605368461-1ee7e53086eb?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Racket Hub', 'location': 'East End', 'price': '₹300/hr', 'category': 'Badminton', 'type': 'Wooden', 'imageUrl': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=1935&auto=format&fit=crop'},
    
    // 5 Volleyball
    {'title': 'Spike Zone', 'location': 'South Park', 'price': '₹500/hr', 'category': 'Volleyball', 'type': 'Sand', 'imageUrl': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2067&auto=format&fit=crop'},
    {'title': 'Net Ninjas', 'location': 'Midtown', 'price': '₹600/hr', 'category': 'Volleyball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1624314138470-5a2f24623f10?q=80&w=1974&auto=format&fit=crop'},
    {'title': 'Block Party', 'location': 'Downtown', 'price': '₹450/hr', 'category': 'Volleyball', 'type': 'Sand', 'imageUrl': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Dig Center', 'location': 'Westside', 'price': '₹700/hr', 'category': 'Volleyball', 'type': 'Indoor', 'imageUrl': 'https://images.unsplash.com/photo-1518605368461-1ee7e53086eb?q=80&w=2000&auto=format&fit=crop'},
    {'title': 'Ace Courts', 'location': 'North Hills', 'price': '₹550/hr', 'category': 'Volleyball', 'type': 'Sand', 'imageUrl': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=1935&auto=format&fit=crop'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredGrounds = allGrounds.where((ground) {
      final matchesCategory = _selectedCategory == 'All' || ground['category'] == _selectedCategory;
      final matchesSearch = ground['title'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 90), // Padding for the glossy top bar
        _buildTopSearch(),
        _buildChips(),
        const SizedBox(height: 12),
        Expanded(
          child: filteredGrounds.isEmpty 
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
                  return _buildGroundCard(filteredGrounds[index]);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildTopSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Color(0xFFEBEBF5), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Color(0xFFEBEBF5), fontSize: 16, fontWeight: FontWeight.w400),
                decoration: const InputDecoration(
                  hintText: 'Search fields and arenas',
                  hintStyle: TextStyle(color: Color(0xFF98989E), fontSize: 16, fontWeight: FontWeight.w400),
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
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white, 
                  fontSize: 14, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroundCard(Map<String, dynamic> ground) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(ground['imageUrl']),
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
    );
  }
}

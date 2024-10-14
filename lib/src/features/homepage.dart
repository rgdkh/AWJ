import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<homepage> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch the username from FirebaseAuth and Firestore
  Future<void> _fetchUserName() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            _userName = snapshot.data()?['name'] ?? 'Guest';
          });
        }
      } else {
        // No user is logged in, set username to "Guest"
        setState(() {
          _userName = 'Guest';
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _userName = 'Guest';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE9DD), // Background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF374923), // Dark green color
        elevation: 0,
        automaticallyImplyLeading: false, // This removes the back arrow
        centerTitle: true, // Centers the title
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image.asset(
                'assets/images/logow.png', // Your logo image path
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName == null
                    ? 'Welcome' // Show "Welcome" initially
                    : 'Welcome, $_userName!', // Show "Welcome, Name!" after fetching
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374923), // Dark green color
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Explore Trails', () {
                // Navigate to see all trails
              }),
              const SizedBox(height: 8),
              _buildTrailsFromFirestore(context), // Pass context to the function
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Add a horizontal line under the "Explore Trails" section title
  Widget _buildSectionTitle(String title, VoidCallback onSeeAllPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onSeeAllPressed,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 2, // Horizontal line thickness
          color: const Color(0xFFF7A22C), // Horizontal line color
        ),
      ],
    );
  }

  // StreamBuilder to fetch and display the trails from Firestore in a horizontal ListView
  Widget _buildTrailsFromFirestore(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trails').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No trails found.');
        }

        var trails = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return TrailData(
            name: data.containsKey('Name') ? data['Name'] : 'Unknown Name',
            images: data.containsKey('images') ? List<String>.from(data['images']) : [],
          );
        }).toList();

        return _buildHorizontalListView(context, trails); // Pass context and trails
      },
    );
  }

  // Builds a horizontal ListView for displaying trails
  Widget _buildHorizontalListView(BuildContext context, List<TrailData> trails) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final trailWidth = (screenWidth / 2) - 24; // Width for each trail item (to show 2 at a time)

    return SizedBox(
      height: 200, // Adjust the height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: trails.length,
        itemBuilder: (context, index) {
          final trail = trails[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: trailWidth, // Set the width dynamically
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.asset(
                        trail.images.isNotEmpty
                            ? trail.images[0]
                            : 'assets/placeholder.png', // Use the first image or a placeholder
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trail.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF374923), // Dark green background color for the bar
      selectedItemColor: Colors.white, // White for the selected item
      unselectedItemColor: const Color(0xFFE9E6D7), // Light color (#E9E6D7) for unselected items
      selectedIconTheme: IconThemeData(
        size: 35, // Make the selected item icon bigger
        color: const Color(0xFFF7A22C), // Set color for selected icon
        shadows: [
          Shadow(
            blurRadius: 10.0,
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      unselectedIconTheme: const IconThemeData(
        size: 24, // Keep unselected item icons smaller
        color: Color(0xFFE9E6D7),
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Group Trips',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_walk),
          label: 'Hiking 101',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum),
          label: 'Chatbot',
        ),
      ],
    );
  }
}

// Model class for Trail Data
class TrailData {
  final String name;
  final List<String> images;

  TrailData({
    required this.name,
    required this.images,
  });
}

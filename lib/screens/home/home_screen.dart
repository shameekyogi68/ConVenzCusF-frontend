import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_colors.dart';
import 'subscription_plans_page.dart';
import '../../services/location_services.dart';

import 'my_booking_screen.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import 'customer_profile_screen.dart';
import 'booking/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentAddress = "Loading address...";

  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  // Subscription state
  Map<String, dynamic>? _userSubscription;
  bool _loadingSubscription = true;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Painting', 'icon': Icons.format_paint},
    {'name': 'Moving', 'icon': Icons.local_shipping},
    {'name': 'More', 'icon': Icons.grid_view},
  ];

  final List<Map<String, String>> popularServices = [
    {'name': 'AC Repair', 'image': 'assets/images/ac_repair.png'},
    {'name': 'Sofa Cleaning', 'image': 'assets/images/sofa.png'},
    {'name': 'Car Wash', 'image': 'assets/images/car_wash.png'},
  ];

  @override
  void initState() {
    super.initState();
    // 1. Start Background Tracking
    LocationService.startLocationTracking();

    // 2. Load existing address first (Fast UI)
    _loadAddressFromDatabase();

    // 3. Force a fresh GPS sync (Accurate UI)
    _updateLocationAndSyncDB();

    // 4. Load subscription data with timeout
    _loadUserSubscription();
    
    // 5. Timeout after 8 seconds to prevent infinite loading
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _loadingSubscription) {
        print("⏱️ Subscription load timeout - stopping loader");
        setState(() => _loadingSubscription = false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ✅ FIX: Improved Address Loading Logic
  void _loadAddressFromDatabase() async {
    try {
      final response = await ProfileService.getProfile();

      if (response['success'] == true && response['data'] != null) {
        // Check 'address' field in the 'data' object
        String dbAddress = response['data']['address'] ?? "";

        if (mounted) {
          setState(() {
            // Only update if we have a valid address, otherwise keep "Loading..."
            // or set a placeholder if it's truly empty.
            if (dbAddress.isNotEmpty) {
              _currentAddress = dbAddress;
            } else {
              _currentAddress = "Location not set";
            }
          });
        }
      }
    } catch (e) {
      print("Profile Fetch Error: $e");
    }
  }

  // ✅ FIX: Update UI immediately after successful sync
  void _updateLocationAndSyncDB() async {
    try {
      String? userId = SharedPrefs.getUserId();

      if (userId == null) {
        await Future.delayed(const Duration(seconds: 1));
        userId = SharedPrefs.getUserId();
      }

      if (userId == null) {
        if (mounted) setState(() => _currentAddress = "User not logged in");
        return;
      }

      Position? pos = await LocationService.determinePosition();

      if (pos != null) {
        final response = await AuthService.updateUserLocation(
          userId,
          pos.latitude,
          pos.longitude,
        );

        if (response['success'] == true && response['location'] != null) {
          // ✅ Extract new address from response
          String newAddress = response['location']['address'] ?? "";

          if (mounted && newAddress.isNotEmpty) {
            setState(() {
              _currentAddress = newAddress;
            });
          }
        }
      }
    } catch (e) {
      print("Location Sync Error: $e");
      // Don't overwrite with error message if we already loaded a cached address
    }
  }

  Future<void> _loadUserSubscription() async {
    try {
      final userId = SharedPrefs.getUserId();
      print("📱 Loading subscription for userId: $userId");
      
      if (userId == null || userId.isEmpty) {
        print("⚠️ No userId found");
        setState(() => _loadingSubscription = false);
        return;
      }

      final result = await SubscriptionService.getUserSubscription(userId);
      print("📥 Subscription result: $result");
      
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            _userSubscription = result['data'];
            print("✅ Subscription loaded: ${_userSubscription?['currentPack']}");
          } else {
            print("⚠️ No active subscription found");
            _userSubscription = null;
          }
          _loadingSubscription = false;
        });
      }
    } catch (e) {
      print("❌ Subscription Load Error: $e");
      if (mounted) {
        setState(() {
          _loadingSubscription = false;
          _userSubscription = null;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ... (Rest of your UI code: _buildBannerCarousel, _buildHomeContent, build method) ...
  // Insert your UI code here exactly as it was in the previous file

  Widget _buildBannerCarousel() {
    final List<Widget> banners = [
      _buildActivePlanBanner(),
      _buildPromoBanner(),
    ];
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return banners[index];
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentBannerIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? AppColors.primaryTeal
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActivePlanBanner() {
    // If loading AND we don't have any cached data, show loading state briefly
    // But default to upgrade banner if it takes too long
    if (_loadingSubscription && _userSubscription == null) {
      // Show loading for max 5 seconds, then show upgrade banner
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F465A), Color(0xFF3A7A94)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accentMint),
          ),
        ),
      );
    }

    // If user has active subscription, show subscription details
    if (_userSubscription != null && _userSubscription!['status'] == 'Active') {
      final planName = _userSubscription!['currentPack'] ?? 'Premium Plan';
      final expiryDate = _userSubscription!['expiryDate'];
      
      String formattedExpiry = 'Soon';
      if (expiryDate != null) {
        try {
          final expiry = DateTime.parse(expiryDate);
          formattedExpiry = '${expiry.day} ${_getMonthName(expiry.month)}, ${expiry.year}';
        } catch (e) {
          print("Date parse error: $e");
        }
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F465A), Color(0xFF3A7A94)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "✓ ACTIVE PLAN",
                      style: TextStyle(
                        color: Color(0xFF1F465A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Valid until: $formattedExpiry",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: AppColors.accentMint, size: 40),
            ),
          ],
        ),
      );
    }

    // If user has NO active subscription, show upgrade prompt
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F465A), Color(0xFF3A7A94)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "UPGRADE PLAN",
                      style: TextStyle(
                        color: Color(0xFF1F465A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Upgrade Your Plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Get exclusive benefits & premium access",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, color: AppColors.accentMint, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month > 0 && month <= 12 ? months[month - 1] : '';
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, Color(0xFF4D9F98)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "25% OFF",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "On your first home cleaning service!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(
                            selectedService: 'Cleaning',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Book Now", style: TextStyle(fontSize: 12)),
                  ),
                )
              ],
            ),
          ),
          const Icon(Icons.cleaning_services, color: Colors.white24, size: 80),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Location",
                      style: TextStyle(color: AppColors.darkGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primaryTeal, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search for services...",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.darkGrey),
              ),
            ),
          ),

          const SizedBox(height: 25),
          _buildBannerCarousel(),
          const SizedBox(height: 25),

          const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final isMoreCard = categories[index]['name'] == 'More';
              
              return InkWell(
                onTap: isMoreCard ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        selectedService: categories[index]['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)
                      ]),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(categories[index]['icon'], 
                          color: AppColors.primaryTeal, 
                          size: 30),
                        const SizedBox(height: 8),
                        Text(
                          categories[index]['name'], 
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        )
                      ]),
                ),
              );
            },
          ),

          const SizedBox(height: 25),

          const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history, color: AppColors.primaryTeal, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Home Cleaning", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Booking Confirmed • Yesterday", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text("Popular Near You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularServices.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.miscellaneous_services, size: 32, color: AppColors.primaryTeal),
                      const SizedBox(height: 8),
                      Text(
                        popularServices[index]['name']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_selectedIndex) {
      case 0: bodyContent = _buildHomeContent(); break;
      case 1: bodyContent = MyBookingsScreen(); break;
      case 2: bodyContent = SubscriptionPlansPage(); break;
      case 3: bodyContent = CustomerProfileScreen(controller: PageController()); break;
      default: bodyContent = _buildHomeContent();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.paid), label: "Plans"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
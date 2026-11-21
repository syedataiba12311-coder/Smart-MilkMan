import 'package:flutter/material.dart';
import 'package:milkman/payment_page.dart';
import 'order_milk_page.dart';
import 'app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // ---------------- CITY SELECTION ----------------
  final List<String> _cities = ['Gujrat', 'Sialkot'];
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -0.2, end: 1.2).animate(_controller);
    _loadCustomerCity();
  }

  Future<void> _loadCustomerCity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('customer')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('city')) {
        setState(() {
          _selectedCity = data['city'];
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔹 LOGOUT
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 USER NAME + GREETING
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                          .collection('customer')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .snapshots()
                    : null,
                builder: (context, snapshot) {
                  String userName = "Customer";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    userName = data['fullname'] ?? "Customer";
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $userName 👋",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Fresh milk delivered to your doorstep 🥛",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// 🔹 CITY DROPDOWN
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Your City",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        hint: const Text("Choose city"),
                        isExpanded: true,
                        items: _cities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCity = val;
                            _saveCustomerCity(val);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// 🔹 DELIVERY CARD
              _deliveryCard(),

              const SizedBox(height: 30),

              /// 🔹 QUICK ACTIONS
              Text("Quick Actions", style: AppTheme.heading2),
              const SizedBox(height: 15),
              Row(
                children: [
                  _quickButton(
                    context,
                    Icons.shopping_cart,
                    "Order Milk",
                    const OrderMilkPage(),
                  ),
                  const SizedBox(width: 12),
                  _quickButton(
                    context,
                    Icons.payment,
                    "Payment",
                    const PaymentPage(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// 🔹 DAIRIES NEAR YOU
              Text("Dairies Near You", style: AppTheme.heading2),
              const SizedBox(height: 15),
              _selectedCity == null
                  ? const Text("Please select a city to see dairies.")
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('owner')
                          .where('area', isEqualTo: _selectedCity)
                          .where('status', isEqualTo: 'Approved')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text("No dairies found in this city.");
                        }
                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final sellerId = doc.id;

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('feedback')
                                  .where('sellerId', isEqualTo: sellerId)
                                  .get(),
                              builder: (context, feedbackSnapshot) {
                                double avgRating = 0;

                                if (feedbackSnapshot.hasData &&
                                    feedbackSnapshot.data!.docs.isNotEmpty) {
                                  double total = 0;

                                  for (var f in feedbackSnapshot.data!.docs) {
                                    total += (f['rating'] ?? 0);
                                  }

                                  avgRating =
                                      total /
                                      feedbackSnapshot.data!.docs.length;
                                }

                                return _dairyCard(
                                  name: data['dairyName'] ?? '',
                                  milkType: data['milkType'] ?? '',
                                  rating: avgRating, // ⭐ dynamic rating
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 DELIVERY CARD
  Widget _deliveryCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Active Delivery",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text("On the way to you"),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * _animation.value,
                bottom: 20,
                child: const Icon(
                  Icons.moped,
                  size: 45,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🔹 QUICK BUTTON
  Widget _quickButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 DAIRY CARD WITH RATING
  Widget _dairyCard({
    required String name,
    required String milkType,
    required double rating,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: AppTheme.primaryColor),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(milkType, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          /// ⭐ DYNAMIC RATING
          Row(
            children: List.generate(5, (i) {
              if (i < rating.floor()) {
                return const Icon(Icons.star, color: Colors.amber, size: 16);
              } else if (i < rating) {
                return const Icon(
                  Icons.star_half,
                  color: Colors.amber,
                  size: 16,
                );
              } else {
                return const Icon(
                  Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  /// 🔹 SAVE SELECTED CITY TO CUSTOMER PROFILE
  Future<void> _saveCustomerCity(String? city) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || city == null) return;
    await FirebaseFirestore.instance.collection('customer').doc(uid).set({
      'city': city,
    }, SetOptions(merge: true));
  }
}

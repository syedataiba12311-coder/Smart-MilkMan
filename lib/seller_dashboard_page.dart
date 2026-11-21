import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milkman/seller_profile_page.dart';
import 'seller_sales_report.dart';
import 'managecustomerorder.dart';
import 'login_page.dart';
import 'seller_inventory_page.dart';
import 'seller_feedback_page.dart';
import 'seller_delivery_page.dart';
// import 'seller_order_milk_page.dart';

class SellerDashboardPage extends StatefulWidget {
  final String cnic;
  const SellerDashboardPage({super.key, required this.cnic});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  String dairyName = "Loading...";
  String city = "Loading...";
  String? sellerId;
  final _auth = FirebaseAuth.instance;

  int totalOrders = 0;
  double totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSellerData(widget.cnic);
  }

  Future<void> _loadSellerData(String cnic) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('owner')
          .where('cnic', isEqualTo: cnic)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          sellerId = doc.id;
          dairyName = data['dairyName'] ?? "Milkman Seller";
          city = data['area'] ?? "Area not set";
        });
        _loadDashboardStats();
      } else {
        setState(() {
          dairyName = "Dairy Not Found";
          city = "";
        });
      }
    } catch (e) {
      debugPrint("Error loading seller data: $e");
    }
  }

  Future<void> _loadDashboardStats() async {
    if (sellerId == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('orders')
          .where('dairyName', isEqualTo: dairyName)
          .get();

      int ordersCount = 0;
      double earnings = 0.0;

      for (var doc in query.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'Pending';

        if (status == 'Rejected') continue;

        ordersCount++;

        final price = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
        earnings += price;
      }

      if (mounted) {
        setState(() {
          totalOrders = ordersCount;
          totalEarnings = earnings;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard stats: $e");
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),

            // ---------- QUICK ACTIONS GRID ----------
            Text(
              "Management",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                _buildModernActionCard(
                  icon: Icons.list_alt,
                  title: "Manage Orders",
                  color: const Color(0xFF4A90E2),
                  onTap: () {
                    if (dairyName != "Loading..." &&
                        dairyName != "Dairy Not Found") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageCustomerOrdersPage(
                            sellerDairyName: dairyName,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildModernActionCard(
                  icon: Icons.inventory_2_outlined,
                  title: "Inventory",
                  color: const Color(0xFF50E3C2),
                  onTap: () {
                    if (sellerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerInventoryPage(sellerId: sellerId!),
                        ),
                      );
                    }
                  },
                ),
                _buildModernActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: "Sales & Revenue",
                  color: const Color(0xFF9013FE),
                  onTap: () {
                    if (dairyName != "Loading..." && dairyName != "Dairy Not Found") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SalesRevenuePage(dairyName: dairyName),
                        ),
                      );
                    }
                  },
                ),

                _buildModernActionCard(
                  icon: Icons.reviews_outlined,
                  title: "Feedback",
                  color: const Color(0xFFFF5252),
                  onTap: () {
                    if (sellerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SellerFeedbackPage(sellerId: sellerId!),
                        ),
                      );
                    }
                  },
                ),
                _buildModernActionCard(
                  icon: Icons.person_outline,
                  title: "Profile",
                  color: const Color(0xFF4A4A4A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerProfilePage(cnic: widget.cnic),
                      ),
                    );
                  },
                ),
                _buildModernActionCard(
                  icon: Icons.local_shipping_outlined,
                  title: "Active Deliveries",
                  color: const Color(0xFFE67E22),
                  onTap: () {
                    if (dairyName != "Loading..." &&
                        dairyName != "Dairy Not Found") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SellerDeliveryPage(sellerDairyName: dairyName),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3192).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFF5F7FA),
              child: Icon(
                Icons.store_rounded,
                size: 36,
                color: Color(0xFF2E3192),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dairyName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      city,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatBadge("Orders", "$totalOrders"),
                    const SizedBox(width: 12),
                    _buildStatBadge(
                      "Earnings",
                      "Rs. ${totalEarnings.toStringAsFixed(0)}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

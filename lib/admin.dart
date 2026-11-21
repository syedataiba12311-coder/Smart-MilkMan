import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milkman/adminloginpage.dart';
import 'app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kDeepBlue = Color(0xFF0D47A1);
const Color kSoftGrey = Color(0xFFF5F6FA);
const Color kLightBlue = Color(0xFFE3F2FD);
const Color kCardShadow = Color(0x22000000);
const String proposalPdfPath =
    '/mnt/data/milkman final.pdf'; // uploaded file path

/// ----------------- MAIN APPS -----------------
class SmartMilkManAdminApp extends StatelessWidget {
  const SmartMilkManAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart MilkMan - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kDeepBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kDeepBlue,
          primary: kDeepBlue,
        ),
        scaffoldBackgroundColor: kSoftGrey,
        appBarTheme: AppBarTheme(
          backgroundColor: kDeepBlue,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: AdminResponsiveHome(),
    );
  }
}

class SmartMilkManMobileApp extends StatelessWidget {
  const SmartMilkManMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart MilkMan - Mobile',
      debugShowCheckedModeBanner: false,
      home: CustomerHomePage(),
    );
  }
}

/// ----------------- RESPONSIVE HOME -----------------
class AdminResponsiveHome extends StatefulWidget {
  const AdminResponsiveHome({super.key});

  @override
  _AdminResponsiveHomeState createState() => _AdminResponsiveHomeState();
}

class _AdminResponsiveHomeState extends State<AdminResponsiveHome> {
  int _index = 0;

  final _titles = [
    'Dashboard',
    'Dairy Store',
    'Certifications',
    'Customers',
    'Delivery',
    'Payments',
    'Reviews',
    'Settings',
  ];

  final _pages = [
    DashboardPage(),
    DairyStorePage(),
    CertificationPage(),
    CustomersPage(),
    DeliveryPage(),
    PaymentsPage(),
    ReviewsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 6),
            Text(_titles[_index]),
            Spacer(),
            // Notification Icon
            IconButton(
              onPressed: () => _openNotifications(),
              icon: Icon(Icons.notifications_none, color: Colors.white),
            ),
            // Admin Avatar
            PopupMenuButton<int>(
              offset: Offset(0, 48),
              color: Colors.white,
              onSelected: (v) {
                if (v == 1) _showProfile();
                if (v == 2) _logout();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 1, child: Text('Profile')),
                PopupMenuItem(value: 2, child: Text('Logout')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        elevation: 2,
      ),
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildSideBar(),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: _pages[_index],
            ),
          ),
        ],
      ),
      // floatingActionButton:
      // (_index == 2) // example: in certifications page show add button
      //     ? FloatingActionButton.extended(
      //   onPressed: () => _showAddCertificationDialog(context),
      //   icon: Icon(Icons.upload_file),
      //   label: Text('Upload Certificate'),
      //   backgroundColor: kDeepBlue,
      // )
      // : null,
    );
  }

  Widget _buildSideBar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 120,
            color: kDeepBlue,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.local_drink, color: kDeepBlue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Smart MilkMan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Admin Panel',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _navTile(Icons.dashboard, 'Dashboard', 0),
                _navTile(Icons.storefront, 'Dairy Store', 1),
                _navTile(Icons.verified, 'Certifications', 2, badge: 3),
                _navTile(Icons.people, 'Customers', 3),
                _navTile(Icons.delivery_dining, 'Delivery', 4),
                _navTile(Icons.account_balance_wallet, 'Payments', 5),
                _navTile(Icons.rate_review, 'Reviews', 6),
                // _navTile(Icons.notifications, 'Notifications', 7),
                Divider(),
                _navTile(Icons.settings, 'Settings', 7),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile(IconData icon, String title, int idx, {int badge = 0}) {
    final selected = idx == _index;
    return ListTile(
      selected: selected,
      selectedTileColor: kLightBlue.withValues(alpha: 0.5),
      leading: Stack(
        children: [
          Icon(icon, color: selected ? kDeepBlue : Colors.grey[700]),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? kDeepBlue : Colors.grey[800],
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: () => setState(() => _index = idx),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: kDeepBlue),
            child: Center(
              child: Text(
                'Smart MilkMan Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _navTile(Icons.dashboard, 'Dashboard', 0),
          _navTile(Icons.storefront, 'Dairy Store', 1),
          _navTile(Icons.verified, 'Certifications', 2),
          _navTile(Icons.people, 'Customers', 3),
          _navTile(Icons.delivery_dining, 'Delivery', 4),
          _navTile(Icons.account_balance_wallet, 'Payments', 5),
          _navTile(Icons.rate_review, 'Reviews', 6),
          // _navTile(Icons.notifications, 'Notifications', 7),
          Spacer(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  void _openNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Notifications'),
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text('No new notifications'),
          ),
        ],
      ),
    );
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Admin Profile'),
        content: Text('Name: Admin\nEmail: admin@gmail.com'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Logout"),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AdminLoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // void _showAddCertificationDialog(BuildContext ctx) {
  //   showDialog(
  //     context: ctx,
  //     builder: (dCtx) {
  //       return AlertDialog(
  //         title: Text('Upload Certification (Demo)'),
  //         content: SizedBox(
  //           width: 400,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text('This is a placeholder for file upload flow.'),
  //               SizedBox(height: 12),
  //               Text('Uploaded file path (example):'),
  //               SizedBox(height: 8),
  //               SelectableText(
  //                 proposalPdfPath,
  //                 style: TextStyle(fontSize: 12, color: Colors.grey[700]),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(dCtx),
  //             child: Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.pop(dCtx);
  //               ScaffoldMessenger.of(ctx).showSnackBar(
  //                 SnackBar(content: Text('Certificate submitted (demo)')),
  //               );
  //             },
  //             child: Text('Submit'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}

/// ----------------- PAGES -----------------
// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Responsive grid
//     final width = MediaQuery.of(context).size.width;
//     final crossAxis = width < 900 ? 1 : 2;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Stat Row
//         Wrap(
//           spacing: 16,
//           runSpacing: 16,
//           children: [
//             StatCard(
//               title: 'Total Customers',
//               value: '1,200',
//               icon: Icons.people,
//             ),
//             StatCard(
//               title: 'Active Subscriptions',
//               value: '860',
//               icon: Icons.subscriptions,
//             ),
//             StatCard(
//               title: 'Pending Certifications',
//               value: '5',
//               icon: Icons.pending_actions,
//               highlight: Colors.orange,
//             ),
//             StatCard(
//               title: 'Active Deliveries',
//               value: '42',
//               icon: Icons.delivery_dining,
//             ),
//           ],
//         ),
//         SizedBox(height: 20),
//         // Analytics placeholder
//         Expanded(
//           child: Row(
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: Card(
//                   child: Container(
//                     padding: EdgeInsets.all(18),
//                     height: 360,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Revenue (Last 30 days)',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         SizedBox(height: 12),
//                         Expanded(
//                           child: Center(
//                             child: Text(
//                               'Chart placeholder\nAdd charts package (eg. charts_flutter) for real graphs',
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 flex: 2,
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: Card(
//                         child: Container(
//                           padding: EdgeInsets.all(18),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Recent Orders',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                               SizedBox(height: 8),
//                               Expanded(child: _recentOrdersList()),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     Expanded(
//                       child: Card(
//                         child: Container(
//                           padding: EdgeInsets.all(18),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Top Sellers',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                               SizedBox(height: 8),
//                               Expanded(child: _topSellersList()),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _recentOrdersList() {
//     final List<Map<String, dynamic>> entries = List.generate(
//       6,
//       (i) => {
//         'id': 1000 + i,
//         'customer': 'Customer ${i + 1}',
//         'status': i % 3 == 0 ? 'Delivered' : 'In Transit',
//       },
//     );
//     return ListView.separated(
//       itemCount: entries.length,
//       separatorBuilder: (_, __) => Divider(),
//       itemBuilder: (ctx, i) {
//         final Map<String, dynamic> e = entries[i];
//         return ListTile(
//           contentPadding: EdgeInsets.zero,
//           title: Text('Order #${e['id']}'),
//           subtitle: Text('${e['customer']} • ${e['status']}'),
//           trailing: Icon(Icons.keyboard_arrow_right),
//         );
//       },
//     );
//   }
//
//   Widget _topSellersList() {
//     final sellers = ['Dairy One', 'Farm Fresh', 'Green Valley'];
//     return ListView.builder(
//       itemCount: sellers.length,
//       itemBuilder: (ctx, i) => ListTile(
//         contentPadding: EdgeInsets.zero,
//         leading: CircleAvatar(child: Text(sellers[i][0])),
//         title: Text(sellers[i]),
//         subtitle: Text('${100 + i * 40} orders'),
//       ),
//     );
//   }
// }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalCustomers = 0;
  int activeSubscriptions = 0;
  int registeredDairies = 0;
  List<Map<String, dynamic>> topSellers = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    loadTopSellers();
  }

  Future<void> _loadStats() async {
    try {
      // Fetch data from Firestore
      final customerSnapshot = await FirebaseFirestore.instance
          .collection('customer')
          .get();
      final subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      final sellerSnapshot = await FirebaseFirestore.instance
          .collection('owner')
          .get();

      final List<Map<String, dynamic>> sellersData = [];

      for (var doc in sellerSnapshot.docs) {
        final data = doc.data();
        double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        sellersData.add({
          'dairyName': data['dairyName'] ?? 'Unknown Dairy',
          'ownerName': data['ownerName'] ?? 'Unknown Owner',
          'rating': rating,
        });
      }

      // Sort sellers by rating descending
      sellersData.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );

      setState(() {
        totalCustomers = customerSnapshot.docs.length;
        activeSubscriptions = subscriptionSnapshot.docs.length;
        registeredDairies = sellerSnapshot.docs.length;
        topSellers = sellersData.take(5).toList();
      });
    } catch (e) {
      debugPrint("Error loading dashboard stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Customers', totalCustomers, Icons.people),
              _buildStatCard(
                'Active Subscriptions',
                activeSubscriptions,
                Icons.subscriptions,
              ),
              _buildStatCard(
                'Registered Dairies',
                registeredDairies,
                Icons.store,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top Sellers
          Card(
            child: Container(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Sellers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300, // fix height for the list
                    child: _topSellersList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon, {
    Color? highlight,
  }) {
    return Container(
      width: 220, // keep same width for all cards
      height: 100, // same height for all cards
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown, // shrink long text if needed
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadTopSellers() async {
    try {
      final feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .get();

      Map<String, List<int>> ratings = {};

      for (var doc in feedbackSnapshot.docs) {
        final data = doc.data();
        final sellerId = data['sellerId'];
        final rating = (data['rating'] as num?)?.toInt() ?? 0;

        if (!ratings.containsKey(sellerId)) {
          ratings[sellerId] = [];
        }

        ratings[sellerId]!.add(rating);
      }

      List<Map<String, dynamic>> sellers = [];

      for (var entry in ratings.entries) {
        final sellerId = entry.key;
        final ratingList = entry.value;

        double avgRating =
            ratingList.reduce((a, b) => a + b) / ratingList.length;

        final sellerDoc = await FirebaseFirestore.instance
            .collection('owner')
            .doc(sellerId)
            .get();

        if (sellerDoc.exists) {
          final sellerData = sellerDoc.data()!;

          sellers.add({
            "sellerId": sellerId,
            "dairyName": sellerData['dairyName'],
            "ownerName": sellerData['ownerName'],
            "rating": avgRating.toStringAsFixed(1),
          });
        }
      }

      sellers.sort(
        (a, b) =>
            double.parse(b['rating']).compareTo(double.parse(a['rating'])),
      );

      if (!mounted) return;

      setState(() {
        topSellers = sellers.take(5).toList(); // top 5 sellers
      });
    } catch (e) {
      print("Error loading sellers: $e");
    }
  }

  Widget _topSellersList() {
    if (topSellers.isEmpty) {
      return const Center(child: Text("No sellers yet"));
    }

    return ListView.builder(
      itemCount: topSellers.length,
      itemBuilder: (ctx, i) {
        final seller = topSellers[i];

        final dairyName = seller['dairyName'] ?? 'Unknown Dairy';
        final ownerName = seller['ownerName'] ?? 'Unknown Owner';
        final rating = seller['rating'] ?? '0';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                (dairyName.isNotEmpty ? dairyName[0] : '?').toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            /// DAIRY NAME
            title: Text(
              dairyName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),

            /// OWNER NAME
            subtitle: Text(
              "Owner: $ownerName",
              style: const TextStyle(fontSize: 13),
            ),

            /// RATING
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  rating.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );

    return ListView.builder(
      itemCount: topSellers.length,
      itemBuilder: (ctx, i) {
        final seller = topSellers[i];
        final dairyName = seller['dairyName'] ?? 'Unknown Dairy';
        final ownerName = seller['ownerName'] ?? 'Unknown Owner';
        final rating = seller['rating'] ?? 0;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(dairyName[0])),
          title: Text(dairyName),
          subtitle: Text('$ownerName • Rating: $rating'),
        );
      },
    );
  }
}

class DairyStorePage extends StatelessWidget {
  const DairyStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registered Dairy Stores',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          /// ✅ FIX: Use Expanded + GridView (NO extra Column)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('owner')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading dairies"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sellers = snapshot.data!.docs;

                if (sellers.isEmpty) {
                  return const Center(child: Text("No dairy registered yet"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: sellers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900
                        ? 3
                        : 1,
                    mainAxisExtent: 190,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final data = sellers[index].data() as Map<String, dynamic>;

                    return _dairyCard(
                      context,
                      sellerId: sellers[index].id,
                      data: data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dairyCard(
    BuildContext context, {
    required String sellerId,
    required Map<String, dynamic> data,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: kDeepBlue,
                  child: Icon(Icons.store, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data['dairyName'] ?? "Unknown Dairy",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text("Owner: ${data['ownerName'] ?? 'N/A'}"),
            Text("Area: ${data['area'] ?? 'N/A'}"),
            Text("Phone: ${data['phone'] ?? 'N/A'}"),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    "${(data['ridersList'] as List?)?.length ?? 0} Riders",
                  ),
                ),
                // ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: kDeepBlue,
                //   ),
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => SellerDetailsPage(
                //           sellerId: sellerId,
                //           sellerData: data,
                //         ),
                //       ),
                //     );
                //   },
                //   child: const Text("View"),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// class CertificationPage extends StatelessWidget {
//   const CertificationPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Milk Quality Certifications'),
//         actions: [
//           ElevatedButton.icon(
//             onPressed: () => _bulkApprove(context),
//             icon: const Icon(Icons.check),
//             label: const Text('Bulk Approve'),
//             style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
//           ),
//           const SizedBox(width: 12),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('owner').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No certifications found.'));
//           }
//
//           final certs = snapshot.data!.docs
//               .map((doc) => CertificationItem.fromDoc(doc))
//               .toList();
//
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columns: const [
//                 DataColumn(label: Text('Seller')),
//                 DataColumn(label: Text('Certificate')),
//                 DataColumn(label: Text('Status')),
//                 DataColumn(label: Text('Actions')),
//               ],
//               rows: certs.map((c) {
//                 return DataRow(cells: [
//                   DataCell(Text(c.seller)),
//                   DataCell(Row(
//                     children: const [
//                       Icon(Icons.picture_as_pdf, color: Colors.red),
//                       SizedBox(width: 8),
//                       Text('PDF Document'),
//                     ],
//                   )),
//                   DataCell(_statusChip(c.status)),
//                   DataCell(Row(
//                     children: [
//                       TextButton(
//                         onPressed: () => _viewCertificate(context, c),
//                         child: const Text('View'),
//                       ),
//                       ElevatedButton(
//                         onPressed: () => _approve(context, c),
//                         child: const Text('Approve'),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                       ),
//                       const SizedBox(width: 6),
//                       OutlinedButton(
//                         onPressed: () => _reject(context, c),
//                         child: const Text('Reject'),
//                       ),
//                     ],
//                   )),
//                 ]);
//               }).toList(),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   static Widget _statusChip(String status) {
//     Color bg;
//     if (status == 'Approved') {
//       bg = Colors.green[50]!;
//     } else if (status == 'Pending') {
//       bg = Colors.orange[50]!;
//     } else {
//       bg = Colors.red[50]!;
//     }
//     return Chip(label: Text(status), backgroundColor: bg);
//   }
class CertificationPage extends StatelessWidget {
  const CertificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Quality Certifications'),
        backgroundColor: kDeepBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _bulkApprove(context),
            icon: const Icon(Icons.check),
            label: const Text('Bulk Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('owner').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No certifications found.'));
          }

          final certs = snapshot.data!.docs
              .map((doc) => CertificationItem.fromDoc(doc))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: certs
                  .map((c) => _buildCertificateRow(context, c))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertificateRow(BuildContext ctx, CertificationItem c) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                c.seller,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: const [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('PDF Document'),
                ],
              ),
            ),
            Expanded(flex: 2, child: _statusChip(c.status)),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _viewCertificate(ctx, c),
                    child: const Text('View'),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _approve(ctx, c),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => _reject(ctx, c),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statusChip(String status) {
    Color bg;
    if (status == 'Approved') {
      bg = Colors.green[50]!;
    } else if (status == 'Pending') {
      bg = Colors.orange[50]!;
    } else {
      bg = Colors.red[50]!;
    }
    return Chip(label: Text(status), backgroundColor: bg);
  }

  // static void _viewCertificate(BuildContext ctx, CertificationItem c) {
  //   if (c.certificateBase64.isEmpty) {
  //     ScaffoldMessenger.of(ctx).showSnackBar(
  //       const SnackBar(content: Text('Certificate not available')),
  //     );
  //     return;
  //   }
  //
  //   final bytes = base64Decode(c.certificateBase64);
  //   showDialog(
  //     context: ctx,
  //     builder: (dCtx) => Dialog(
  //       insetPadding: const EdgeInsets.all(16),
  //       child: Container(
  //         width: MediaQuery.of(ctx).size.width * 0.8,
  //         height: MediaQuery.of(ctx).size.height * 0.8,
  //         padding: const EdgeInsets.all(12),
  //         child: Column(
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(c.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 IconButton(
  //                   onPressed: () => Navigator.pop(dCtx),
  //                   icon: const Icon(Icons.close),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             Expanded(
  //               child: SfPdfViewer.memory(
  //                 bytes,
  //                 canShowScrollHead: true,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  // static void _viewCertificateWeb(BuildContext ctx, CertificationItem c) {
  //   if (c.certificateUrl
  //       .trim()
  //       .isEmpty) return;
  //
  //   html.window.open(c.certificateUrl, '_blank');
  // }
  // //
  // //   showDialog(
  // //     context: ctx,
  // //     builder: (dCtx) => Dialog(
  // //       insetPadding: const EdgeInsets.all(16),
  // //       child: Container(
  // //         width: MediaQuery.of(ctx).size.width * 0.8,
  // //         height: MediaQuery.of(ctx).size.height * 0.8,
  // //         padding: const EdgeInsets.all(12),
  // //         child: Column(
  // //           children: [
  // //             Row(
  // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  // //               children: [
  // //                 Text(c.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
  // //                 IconButton(
  // //                   onPressed: () => Navigator.pop(dCtx),
  // //                   icon: const Icon(Icons.close),
  // //                 ),
  // //               ],
  // //             ),
  // //             const SizedBox(height: 8),
  // //             Expanded(
  // //               child: SfPdfViewer.network(
  // //                 c.certificateUrl,
  // //                 canShowScrollHead: true,
  // //               ),
  // //             ),
  // //           ],
  // //         ),
  // //       ),
  // //     ),
  // //   );
  // // }
  // static void _viewCertificateWeb(BuildContext ctx, CertificationItem c) {
  //   if (c.certificateUrl.trim().isEmpty) {
  //     ScaffoldMessenger.of(ctx).showSnackBar(
  //       const SnackBar(content: Text('Certificate not available')),
  //     );
  //     return;
  //   }
  //
  //   // Open PDF in a new tab (works for all PDFs, even if Cloudinary forces download)
  //   html.window.open(c.certificateUrl, '_blank');
  //
  //   // Optional: Show inline viewer if URL supports inline PDF
  //   showDialog(
  //     context: ctx,
  //     builder: (dCtx) => Dialog(
  //       insetPadding: const EdgeInsets.all(16),
  //       child: Container(
  //         width: MediaQuery.of(ctx).size.width * 0.8,
  //         height: MediaQuery.of(ctx).size.height * 0.8,
  //         padding: const EdgeInsets.all(12),
  //         child: Column(
  //           children: [
  //             // Header with filename and close button
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(c.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 IconButton(
  //                   onPressed: () => Navigator.pop(dCtx),
  //                   icon: const Icon(Icons.close),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             // PDF Viewer
  //             Expanded(
  //               child: SfPdfViewer.network(
  //                 // Add fl_attachment:false to force inline PDF if hosted on Cloudinary
  //                 c.certificateUrl.contains('cloudinary')
  //                     ? c.certificateUrl.replaceFirst('/upload/', '/upload/fl_attachment:false/')
  //                     : c.certificateUrl,
  //                 canShowScrollHead: true,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  void _viewCertificate(BuildContext ctx, CertificationItem c) async {
    if (c.certificateUrl.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Certificate not available')),
      );
      return;
    }

    // ✅ Cloudinary raw PDF URL (force inline in browser optional)
    String url = c.certificateUrl;
    if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
      url = url.replaceFirst('/upload/', '/upload/fl_attachment:Certificate/');
    }

    final Uri uri = Uri.parse(url);

    // Open in default browser (web or mobile)
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Could not open certificate')),
      );
    }
  }

  static void _approve(BuildContext ctx, CertificationItem c) async {
    await FirebaseFirestore.instance.collection('owner').doc(c.id).update({
      'status': 'Approved',
    });
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text('Approved ${c.seller}')));
  }

  static void _reject(BuildContext ctx, CertificationItem c) async {
    await FirebaseFirestore.instance.collection('owner').doc(c.id).update({
      'status': 'Rejected',
    });
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text('Rejected ${c.seller}')));
  }

  static void _bulkApprove(BuildContext ctx) async {
    final snapshot = await FirebaseFirestore.instance.collection('owner').get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'status': 'Approved'});
    }
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(const SnackBar(content: Text('All certificates approved')));
  }
}

class CertificationItem {
  final String id;
  final String seller;
  final String fileName;
  final String status;
  final String certificateUrl;

  CertificationItem({
    required this.id,
    required this.seller,
    required this.fileName,
    required this.status,
    required this.certificateUrl,
  });

  factory CertificationItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CertificationItem(
      id: doc.id,
      seller: data['ownerName'] ?? 'Unknown',
      fileName: 'certificate.pdf',
      status: data['status'] ?? 'Pending',
      certificateUrl: data['certificateUrl'] ?? '',
    );
  }
}
//   static void _viewCertificate(BuildContext ctx, CertificationItem c) {
//     if (c.certificateUrl.trim().isEmpty) {
//       ScaffoldMessenger.of(ctx).showSnackBar(
//         const SnackBar(content: Text('Certificate not available')),
//       );
//       return;
//     }
//
//     showDialog(
//       context: ctx,
//       builder: (dCtx) => Dialog(
//         insetPadding: const EdgeInsets.all(16),
//         child: Container(
//           width: MediaQuery.of(ctx).size.width * 0.8,
//           height: MediaQuery.of(ctx).size.height * 0.8,
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     c.fileName,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.pop(dCtx),
//                     icon: const Icon(Icons.close),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: SfPdfViewer.network(
//                   c.certificateUrl, // ✅ load from URL
//                   canShowScrollHead: true,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   // static void _viewCertificate(BuildContext ctx, CertificationItem c) {
//   //   if (c.certificateBase64.trim().isEmpty) {
//   //     ScaffoldMessenger.of(ctx).showSnackBar(
//   //       const SnackBar(content: Text('Certificate not available')),
//   //     );
//   //     return;
//   //   }
//   //
//   //   try {
//   //     // Remove all whitespace/newlines before decoding
//   //     final base64String = c.certificateBase64.replaceAll(RegExp(r'\s+'), '');
//   //     final bytes = base64Decode(base64String);
//   //
//   //     showDialog(
//   //       context: ctx,
//   //       builder: (dCtx) => Dialog(
//   //         insetPadding: const EdgeInsets.all(16),
//   //         child: Container(
//   //           width: MediaQuery.of(ctx).size.width * 0.8,
//   //           height: MediaQuery.of(ctx).size.height * 0.8,
//   //           padding: const EdgeInsets.all(12),
//   //           child: Column(
//   //             children: [
//   //               Row(
//   //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //                 children: [
//   //                   Text(c.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
//   //                   IconButton(
//   //                     onPressed: () => Navigator.pop(dCtx),
//   //                     icon: const Icon(Icons.close),
//   //                   ),
//   //                 ],
//   //               ),
//   //               const SizedBox(height: 8),
//   //               Expanded(
//   //                 child: SfPdfViewer.memory(
//   //                   bytes,
//   //                   canShowScrollHead: true,
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(ctx).showSnackBar(
//   //       const SnackBar(content: Text('Failed to load certificate')),
//   //     );
//   //     debugPrint('PDF decode error: $e');
//   //   }
//   // }
//
//   static void _approve(BuildContext ctx, CertificationItem c) async {
//     await FirebaseFirestore.instance.collection('owner').doc(c.id).update({'status': 'Approved'});
//     ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Approved ${c.seller}')));
//   }
//
//   static void _reject(BuildContext ctx, CertificationItem c) async {
//     await FirebaseFirestore.instance.collection('owner').doc(c.id).update({'status': 'Rejected'});
//     ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Rejected ${c.seller}')));
//   }
//
//   static void _bulkApprove(BuildContext ctx) async {
//     final snapshot = await FirebaseFirestore.instance.collection('owner').get();
//     for (var doc in snapshot.docs) {
//       await doc.reference.update({'status': 'Approved'});
//     }
//     ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('All certificates approved')));
//   }
//
// }
// // class CertificationPage extends StatelessWidget {
// //   const CertificationPage({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final List<CertificationItem> certs = List.generate(
// //       6,
// //           (i) => CertificationItem(
// //         id: i + 1,
// //         seller: 'Seller ${i + 1}',
// //         fileName: 'certificate_${i + 1}.pdf',
// //         status: i % 3 == 0 ? 'Pending' : 'Approved',
// //       ),
// //     );
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text(
// //               'Milk Quality Certifications',
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             ElevatedButton.icon(
// //               onPressed: () => _bulkApprove(context),
// //               icon: Icon(Icons.check),
// //               label: Text('Bulk Approve'),
// //               style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 12),
// //         Expanded(
// //           child: Card(
// //             child: Container(
// //               padding: EdgeInsets.all(16),
// //               child: SingleChildScrollView(
// //                 child: DataTable(
// //                   columns: [
// //                     DataColumn(label: Text('Seller')),
// //                     DataColumn(label: Text('Certificate')),
// //                     DataColumn(label: Text('Status')),
// //                     DataColumn(label: Text('Actions')),
// //                   ],
// //                   rows: certs
// //                       .map(
// //                         (c) => DataRow(
// //                       cells: [
// //                         DataCell(Text(c.seller)),
// //                         DataCell(
// //                           Row(
// //                             children: [
// //                               Icon(Icons.picture_as_pdf, color: Colors.red),
// //                               SizedBox(width: 8),
// //                               Text(c.fileName),
// //                             ],
// //                           ),
// //                         ),
// //                         DataCell(_statusChip(c.status)),
// //                         DataCell(
// //                           Row(
// //                             children: [
// //                               TextButton(
// //                                 onPressed: () =>
// //                                     _viewCertification(context, c),
// //                                 child: Text('View'),
// //                               ),
// //                               ElevatedButton(
// //                                 onPressed: () => _approve(context, c),
// //                                 child: Text('Approve'),
// //                                 style: ElevatedButton.styleFrom(
// //                                   backgroundColor: Colors.green,
// //                                 ),
// //                               ),
// //                               SizedBox(width: 6),
// //                               OutlinedButton(
// //                                 onPressed: () => _reject(context, c),
// //                                 child: Text('Reject'),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   )
// //                       .toList(),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _statusChip(String status) {
// //     Color bg;
// //     if (status == 'Approved') {
// //       bg = Colors.green[50]!;
// //     } else if (status == 'Pending')
// //       bg = Colors.orange[50]!;
// //     else
// //       bg = Colors.red[50]!;
// //     return Chip(label: Text(status), backgroundColor: bg);
// //   }
// //
// //   void _viewCertification(BuildContext ctx, CertificationItem c) {
// //     showDialog(
// //       context: ctx,
// //       builder: (dCtx) => Dialog(
// //         child: Container(
// //           width: 800,
// //           height: 600,
// //           padding: EdgeInsets.all(16),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Text(
// //                     'View Certificate',
// //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                   ),
// //                   IconButton(
// //                     onPressed: () => Navigator.pop(dCtx),
// //                     icon: Icon(Icons.close),
// //                   ),
// //                 ],
// //               ),
// //               SizedBox(height: 12),
// //               Expanded(
// //                 child: Center(
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Icon(Icons.picture_as_pdf, size: 72, color: Colors.red),
// //                       SizedBox(height: 12),
// //                       Text(
// //                         'PDF Viewer Placeholder',
// //                         style: TextStyle(fontWeight: FontWeight.bold),
// //                       ),
// //                       SizedBox(height: 8),
// //                       Text('File: ${c.fileName}'),
// //                       SizedBox(height: 16),
// //                       Text(
// //                         'To view the actual PDF, use a PDF viewer plugin and provide the file URL or bytes.',
// //                       ),
// //                       SizedBox(height: 16),
// //                       ElevatedButton.icon(
// //                         onPressed: () => _openProposalPdf(),
// //                         icon: Icon(Icons.open_in_new),
// //                         label: Text('Open Proposal PDF (uploaded)'),
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: kDeepBlue,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _approve(BuildContext ctx, CertificationItem c) {
// //     ScaffoldMessenger.of(
// //       ctx,
// //     ).showSnackBar(SnackBar(content: Text('Approved ${c.seller} (demo)')));
// //   }
// //
// //   void _reject(BuildContext ctx, CertificationItem c) {
// //     ScaffoldMessenger.of(
// //       ctx,
// //     ).showSnackBar(SnackBar(content: Text('Rejected ${c.seller} (demo)')));
// //   }
// //
// //   void _bulkApprove(BuildContext ctx) {
// //     ScaffoldMessenger.of(
// //       ctx,
// //     ).showSnackBar(SnackBar(content: Text('Bulk approved (demo)')));
// //   }
// //
// //   void _openProposalPdf() {
// //     // For demo: show path. In production, open actual viewer or route.
// //     debugPrint('Open PDF at: $proposalPdfPath');
// //   }
// // }
//
// // class CertificationItem {
// //   final int id;
// //   final String seller;
// //   final String fileName;
// //   final String status;
// //   CertificationItem({
// //     required this.id,
// //     required this.seller,
// //     required this.fileName,
// //     required this.status,
// //   });
// // }
// class CertificationItem {
//   final String id;
//   final String seller;
//   final String fileName;
//   final String status;
//   final String certificateUrl; // ✅ changed
//
//   CertificationItem({
//     required this.id,
//     required this.seller,
//     required this.fileName,
//     required this.status,
//     required this.certificateUrl,
//   });
//
//   factory CertificationItem.fromDoc(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//
//     return CertificationItem(
//       id: doc.id,
//       seller: data['ownerName'] ?? 'Unknown',
//       fileName: 'certificate.pdf',
//       status: data['status'] ?? 'Pending',
//       certificateUrl: data['certificateUrl'] ?? '', // ✅ from Firestore
//     );
//   }
// }
// // class CertificationItem {
// //   final String id;
// //   final String seller;
// //   final String fileName;
// //   final String status;
// //   final String certificateBase64;
// //
// //   CertificationItem({
// //     required this.id,
// //     required this.seller,
// //     required this.fileName,
// //     required this.status,
// //     required this.certificateBase64,
// //   });
// //
// //   factory CertificationItem.fromDoc(DocumentSnapshot doc) {
// //     final data = doc.data() as Map<String, dynamic>;
// //     return CertificationItem(
// //       id: doc.id,
// //       seller: data['ownerName'] ?? 'Unknown',
// //       fileName: data['fileName'] ?? 'certificate.pdf',
// //       status: data['status'] ?? 'Pending',
// //       certificateBase64: data['certificateBase64'] ?? '',
// //     );
// //   }
// // }

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('customer').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading customers"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final customers = snapshot.data!.docs;

            if (customers.isEmpty) {
              return const Center(child: Text("No customer registered yet"));
            }

            return ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, index) {
                final data = customers[index].data() as Map<String, dynamic>;
                final name = data['fullname'] ?? 'Unnamed';
                final email = data['email'] ?? 'N/A';
                final number = data['number'] ?? 'N/A';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    "Email: $email\nPhone: $number\nJoined: ${createdAt != null ? "${createdAt.day}/${createdAt.month}/${createdAt.year}" : "N/A"}",
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// class DeliveryPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> drivers = List.generate(
//       8,
//       (i) => {
//         'name': 'Driver ${i + 1}',
//         'status': i % 2 == 0 ? 'Online' : 'Offline',
//         'active': Random().nextInt(6),
//       },
//     );
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Delivery Partners',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             ElevatedButton.icon(
//               onPressed: () {},
//               icon: Icon(Icons.map),
//               label: Text('Show Routes'),
//               style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
//             ),
//           ],
//         ),
//         SizedBox(height: 12),
//         Expanded(
//           child: Row(
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: Card(
//                   child: Container(
//                     padding: EdgeInsets.all(12),
//                     child: ListView.separated(
//                       itemCount: drivers.length,
//                       separatorBuilder: (_, __) => Divider(),
//                       itemBuilder: (ctx, i) {
//                         final Map<String, dynamic> d = drivers[i];
//                         final String name = d['name'] as String;
//                         final String status = d['status'] as String;
//                         final int active = d['active'] as int;
//                         return ListTile(
//                           leading: CircleAvatar(child: Text(name[0])),
//                           title: Text(name),
//                           subtitle: Text('$status • Active: $active'),
//                           trailing: ElevatedButton(
//                             onPressed: () =>
//                                 ScaffoldMessenger.of(ctx).showSnackBar(
//                                   SnackBar(
//                                     content: Text('Assign Route (demo)'),
//                                   ),
//                                 ),
//                             child: Text('Assign'),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 flex: 3,
//                 child: Card(
//                   child: Container(
//                     height: double.infinity,
//                     padding: EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Route Map',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         SizedBox(height: 12),
//                         Expanded(
//                           child: Center(
//                             child: Text(
//                               'Map placeholder\nIntegrate Google Maps or MapBox here',
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 12),
//                         Align(
//                           alignment: Alignment.bottomRight,
//                           child: ElevatedButton.icon(
//                             onPressed: () {},
//                             icon: Icon(Icons.refresh),
//                             label: Text('Refresh'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: kDeepBlue,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Delivery Boys'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('owner').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sellers = snapshot.data!.docs;
          List<Map<String, dynamic>> allRiders = [];

          // Collect all riders from all sellers
          for (var seller in sellers) {
            Map<String, dynamic> sellerData =
                seller.data() as Map<String, dynamic>;
            String ownerName = sellerData['ownerName'] ?? 'Unknown Owner';
            String ownerArea = sellerData['area'] ?? 'Unknown Area';
            String dairyName = sellerData['dairyName'] ?? 'Unknown Dairy';

            if (sellerData['ridersList'] != null) {
              List<Map<String, dynamic>> riders =
                  List<Map<String, dynamic>>.from(sellerData['ridersList']);
              for (var rider in riders) {
                allRiders.add({
                  'riderName': rider['name'] ?? 'Unknown',
                  'riderPhone': rider['phone'] ?? 'N/A',
                  'ownerName': ownerName,
                  'ownerArea': ownerArea,
                  'dairyName': dairyName,
                });
              }
            }
          }

          if (allRiders.isEmpty) {
            return const Center(
              child: Text('No delivery boys registered yet.'),
            );
          }

          return ListView.separated(
            itemCount: allRiders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final rider = allRiders[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor,
                  child: Icon(Icons.delivery_dining, color: Colors.white),
                ),
                title: Text(rider['riderName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone: ${rider['riderPhone']}"),
                    Text("Owner: ${rider['ownerName']}"),
                    Text("Owner Area: ${rider['ownerArea']}"),
                    Text("Dairy Name: ${rider['dairyName']}"),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payments & Revenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
              style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error fetching records"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data?.docs ?? [];
              
              double totalRevenue = 0;
              double thisMonthRevenue = 0;
              double pendingRevenue = 0;

              final now = DateTime.now();

              List<Map<String, dynamic>> orderList = [];

              for (var doc in orders) {
                final data = doc.data() as Map<String, dynamic>;
                
                double price = 0.0;
                try {
                  final priceVal = data['totalPrice'];
                  if (priceVal is num) price = priceVal.toDouble();
                  else if (priceVal is String) price = double.tryParse(priceVal) ?? 0.0;
                } catch (_) {}

                final status = data['status'] ?? 'Pending';
                final paymentStatus = data['paymentStatus'] ?? 'Unpaid';
                final isPaid = paymentStatus == 'Paid' || status == 'Paid' || status == 'Completed' || status == 'Delivered';

                if (isPaid) {
                  totalRevenue += price;
                  final timestamp = data['orderDate'] as Timestamp?;
                  if (timestamp != null) {
                    final date = timestamp.toDate();
                    if (date.year == now.year && date.month == now.month) {
                      thisMonthRevenue += price;
                    }
                  }
                } else if (status != 'Rejected' && status != 'Cancelled') {
                  pendingRevenue += price;
                }

                orderList.add({'id': doc.id, ...data});
              }

              return Card(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _revenueCard('Total', 'PKR ${totalRevenue.toStringAsFixed(0)}'),
                          const SizedBox(width: 12),
                          _revenueCard('This Month', 'PKR ${thisMonthRevenue.toStringAsFixed(0)}'),
                          const SizedBox(width: 12),
                          _revenueCard('Pending', 'PKR ${pendingRevenue.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: orderList.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, i) {
                            final o = orderList[i];
                            final status = o['status'] ?? 'Pending';
                            final paymentMethod = o['paymentMethod'] ?? 'COD';
                            final customerId = o['customerId'];
                            final dairyName = o['dairyName'] ?? 'Unknown Seller';
                            final date = (o['orderDate'] as Timestamp?)?.toDate();
                            final dateStr = date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : 'N/A';
                            
                            double price = 0.0;
                            try {
                              final priceVal = o['totalPrice'];
                              if (priceVal is num) price = priceVal.toDouble();
                              else if (priceVal is String) price = double.tryParse(priceVal) ?? 0.0;
                            } catch (_) {}

                            return FutureBuilder<DocumentSnapshot>(
                              future: customerId != null 
                                  ? FirebaseFirestore.instance.collection('customer').doc(customerId).get()
                                  : null,
                              builder: (context, custSnapshot) {
                                String custName = "Unknown Customer";
                                if (custSnapshot.hasData && custSnapshot.data != null && custSnapshot.data!.exists) {
                                  final cData = custSnapshot.data!.data() as Map<String, dynamic>?;
                                  if (cData != null) {
                                    custName = cData['fullname'] ?? "Unknown Customer";
                                  }
                                }

                                final isFailed = (status == 'Rejected' || status == 'Cancelled');

                                return ListTile(
                                  leading: Icon(
                                    Icons.receipt,
                                    color: isFailed ? Colors.red : Colors.green,
                                  ),
                                  title: Text('$custName → $dairyName • PKR $price'),
                                  subtitle: Text('$paymentMethod • $dateStr'),
                                  trailing: Text(
                                    status,
                                    style: TextStyle(
                                      color: isFailed ? Colors.red : Colors.green,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _revenueCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kDeepBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class ReviewsPage extends StatefulWidget {
//   const ReviewsPage({super.key});
//
//   @override
//   State<ReviewsPage> createState() => _ReviewsPageState();
// }
//
// class _ReviewsPageState extends State<ReviewsPage> {
//   final TextEditingController _replyController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F8),
//       appBar: AppBar(
//         title: const Text(
//           "Customer Reviews",
//           style: TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 1,
//         iconTheme: const IconThemeData(color: Colors.black87),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('feedback')
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.feedback_outlined,
//                     size: 64,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     "No reviews available",
//                     style: TextStyle(fontSize: 16, color: Colors.grey[500]),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data() as Map<String, dynamic>;
//               return _buildReviewCard(data, doc.id);
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildReviewCard(Map<String, dynamic> data, String docId) {
//     final customerId = data['customerId'];
//     final sellerId = data['sellerId'];
//     final rating = (data['rating'] as num?)?.toInt() ?? 0;
//     final comment = data['comment'] ?? "";
//     final adminReply = data['adminReply'] ?? "";
//     final timestamp = data['timestamp'] as Timestamp?;
//     final date = timestamp != null
//         ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
//         : "Unknown Date";
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 3,
//       shadowColor: Colors.grey.withOpacity(0.2),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Top row: Rating & Date
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: List.generate(5, (i) {
//                     return Icon(
//                       i < rating ? Icons.star : Icons.star_border,
//                       color: Colors.amber,
//                       size: 20,
//                     );
//                   }),
//                 ),
//                 Text(
//                   date,
//                   style: TextStyle(color: Colors.grey[500], fontSize: 12),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             // Comment
//             if (comment.isNotEmpty) ...[
//               Text(
//                 comment,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.black87,
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],
//
//             // Customer + Seller Info
//             FutureBuilder(
//               future: Future.wait([
//                 FirebaseFirestore.instance
//                     .collection('customer')
//                     .doc(customerId)
//                     .get(),
//                 FirebaseFirestore.instance
//                     .collection('owner')
//                     .doc(sellerId)
//                     .get(),
//               ]),
//               builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
//                 String customerName = "Loading...";
//                 String customerAddress = "Loading...";
//                 String sellerName = "Loading...";
//                 String dairyName = "Loading...";
//
//                 if (snapshot.hasData) {
//                   final customerDoc = snapshot.data![0];
//                   final sellerDoc = snapshot.data![1];
//
//                   if (customerDoc.exists) {
//                     final cData = customerDoc.data() as Map<String, dynamic>;
//                     customerName = cData['fullname'] ?? "Unknown Customer";
//                     customerAddress = cData['address'] ?? "Address not available";
//                   }
//
//                   if (sellerDoc.exists) {
//                     final sData = sellerDoc.data() as Map<String, dynamic>;
//                     sellerName = sData['ownerName'] ?? "Unknown Seller";
//                     dairyName = sData['dairyName'] ?? "Unknown Dairy";
//                   }
//                 }
//
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           backgroundColor: Colors.blueGrey[50],
//                           radius: 18,
//                           child: Icon(Icons.person, size: 18, color: Colors.grey),
//                         ),
//                         const SizedBox(width: 12),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               customerName,
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 14),
//                             ),
//                             Text(
//                               customerAddress,
//                               style: TextStyle(
//                                   color: Colors.grey[600], fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Icon(Icons.store, size: 16, color: Colors.grey[700]),
//                         const SizedBox(width: 6),
//                         Text(
//                           "$dairyName (Owner: $sellerName)",
//                           style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800]),
//                         ),
//                       ],
//                     ),
//                   ],
//                 );
//               },
//             ),
//
//             const SizedBox(height: 16),
//
//             // Admin Reply Section
//             if (adminReply.isNotEmpty) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blueGrey[50],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Admin Reply",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blueGrey[800]),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       adminReply,
//                       style: const TextStyle(color: Colors.black87),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//
//             // Reply Button
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton(
//                 onPressed: () {
//                   _replyController.text = adminReply;
//                   _showReplyDialog(docId);
//                 },
//                 style: TextButton.styleFrom(
//                   foregroundColor: Colors.blue[700],
//                 ),
//                 child: const Text(
//                   "Reply",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showReplyDialog(String docId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Admin Reply"),
//         content: TextField(
//           controller: _replyController,
//           maxLines: 3,
//           decoration: const InputDecoration(
//             hintText: "Write your reply here...",
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               await FirebaseFirestore.instance
//                   .collection('feedback')
//                   .doc(docId)
//                   .update({'adminReply': _replyController.text.trim()});
//
//               Navigator.pop(context);
//             },
//             child: const Text("Send"),
//           ),
//         ],
//       ),
//     );
//   }
// }

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Customer Reviews",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No reviews available",
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildReviewCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data, String docId) {
    final customerId = data['customerId'];
    final sellerId = data['sellerId'];
    final rating = (data['rating'] as num?)?.toInt() ?? 0;
    final comment = data['comment'] ?? "";
    // final adminReply = data['adminReply'] ?? "";
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
        : "Unknown Date";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection('customer')
                .doc(customerId)
                .get(),
            FirebaseFirestore.instance.collection('owner').doc(sellerId).get(),
          ]),
          builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            String customerName = "Loading...";
            String customerAddress = "Loading...";
            String sellerName = "Loading...";
            String dairyName = "Loading...";

            if (snapshot.hasData) {
              final customerDoc = snapshot.data![0];
              final sellerDoc = snapshot.data![1];

              if (customerDoc.exists) {
                final cData = customerDoc.data() as Map<String, dynamic>;
                customerName = cData['fullname'] ?? "Unknown Customer";
                customerAddress = cData['address'] ?? "Address not available";
              }

              if (sellerDoc.exists) {
                final sData = sellerDoc.data() as Map<String, dynamic>;
                sellerName = sData['ownerName'] ?? "Unknown Owner";
                dairyName = sData['dairyName'] ?? "Unknown Dairy";
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Comment
                if (comment.isNotEmpty) ...[
                  Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Customer info
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "$customerName, $customerAddress",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Dairy info
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.grey, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "$dairyName (Owner: $sellerName)",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Admin Reply
                // if (adminReply.isNotEmpty) ...[
                //   Container(
                //     width: double.infinity,
                //     padding: const EdgeInsets.all(12),
                //     decoration: BoxDecoration(
                //       color: Colors.blueGrey[50],
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           "Admin Reply",
                //           style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               color: Colors.blueGrey[800]),
                //         ),
                //         const SizedBox(height: 6),
                //         Text(
                //           adminReply,
                //           style: const TextStyle(color: Colors.black87),
                //         ),
                //       ],
                //     ),
                //   ),
                //   const SizedBox(height: 12),
                // ],
                //
                // // Reply Button
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: () {
                //       _replyController.text = adminReply;
                //       _showReplyDialog(docId);
                //     },
                //     style: TextButton.styleFrom(
                //       foregroundColor: Colors.blue[700],
                //     ),
                //     child: const Text(
                //       "Reply",
                //       style: TextStyle(fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }

  // void _showReplyDialog(String docId) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Admin Reply"),
  //       content: TextField(
  //         controller: _replyController,
  //         maxLines: 3,
  //         decoration: const InputDecoration(
  //           hintText: "Write your reply here...",
  //           border: OutlineInputBorder(),
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Cancel"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             await FirebaseFirestore.instance
  //                 .collection('feedback')
  //                 .doc(docId)
  //                 .update({'adminReply': _replyController.text.trim()});
  //             Navigator.pop(context);
  //           },
  //           child: const Text("Send"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> history = List.generate(
      6,
      (i) => {
        'title': 'Promo ${i + 1}',
        'target': i % 2 == 0 ? 'All Buyers' : 'Sellers',
        'date': '2025-11-${(i % 28) + 1}',
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _composeNotification(context),
              icon: Icon(Icons.add),
              label: Text('Compose'),
              style: ElevatedButton.styleFrom(backgroundColor: kDeepBlue),
            ),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: Card(
            child: Container(
              padding: EdgeInsets.all(12),
              child: ListView.separated(
                itemCount: history.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (ctx, i) {
                  final Map<String, dynamic> h = history[i];
                  final String title = h['title'] as String;
                  final String target = h['target'] as String;
                  final String date = h['date'] as String;
                  return ListTile(
                    title: Text(title),
                    subtitle: Text('$target • $date'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () => ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text('Deleted (demo)'))),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _composeNotification(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text('Compose Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Title')),
            TextField(decoration: InputDecoration(labelText: 'Message')),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              items: [
                'All Buyers',
                'Sellers',
                'Delivery Partners',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController(
    text: "admin@gmail.com",
  );

  TextEditingController passwordController = TextEditingController(
    text: "admin123",
  );

  bool obscurePassword = true;

  void saveSettings() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings Updated Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Settings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// ADMIN EMAIL
              TextFormField(
                controller: emailController,

                decoration: const InputDecoration(
                  labelText: "Admin Email",
                  prefixIcon: Icon(Icons.person),
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email cannot be empty";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,

                decoration: InputDecoration(
                  labelText: "Admin Password",
                  prefixIcon: const Icon(Icons.lock),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password cannot be empty";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),



              const Spacer(),

              /// SAVE BUTTON
              // Align(
              //   alignment: Alignment.bottomRight,
              //   child: ElevatedButton(
              //     onPressed: saveSettings,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: kDeepBlue,
              //     ),
              //     child: const Text("Save"),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- REUSABLE WIDGETS -----------------
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? highlight;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.bar_chart,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ?? kDeepBlue;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: kCardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[700])),
                SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart MilkMan - Mobile')),
      body: Center(child: Text('Customer / Seller / Delivery Panel')),
    );
  }
}

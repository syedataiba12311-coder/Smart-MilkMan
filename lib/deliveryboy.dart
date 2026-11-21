import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

const Color kPrimary = Color(0xFF0D47A1);
const Color kAccent = Color(0xFF1976D2);
const Color kBackground = Color(0xFFF4F6FA);
const Color kCard = Colors.white;
const Color kMuted = Colors.black54;

class DeliveryMasterApp extends StatefulWidget {
  const DeliveryMasterApp({super.key});

  @override
  State<DeliveryMasterApp> createState() => _DeliveryMasterAppState();
}

class _DeliveryMasterAppState extends State<DeliveryMasterApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData light = ThemeData(
      brightness: Brightness.light,
      primaryColor: kPrimary,
      scaffoldBackgroundColor: kBackground,
      textTheme: GoogleFonts.montserratTextTheme(),
      appBarTheme: const AppBarTheme(backgroundColor: kPrimary, elevation: 0),
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: kAccent),
    );

    final ThemeData dark = ThemeData(
      brightness: Brightness.dark,
      primaryColor: kPrimary,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF071029),
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
      ).copyWith(secondary: kAccent),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Master',
      theme: _darkMode ? dark : light,
      home: MainShell(
        onToggleDark: () => setState(() => _darkMode = !_darkMode),
        darkMode: _darkMode,
      ),
    );
  }
}

// -----------------------------
// MAIN NAV SHELL
// -----------------------------
class MainShell extends StatefulWidget {
  final VoidCallback onToggleDark;
  final bool darkMode;
  const MainShell({
    super.key,
    required this.onToggleDark,
    required this.darkMode,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final _pages = [
    const DeliveryDashboardPage(),
    const AssignedDeliveriesPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  void _onTapIndex(int i) {
    setState(() => _selectedIndex = i);
    _pageController.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is inside pages for more control
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages.map((p) {
            if (p is DeliveryDashboardPage) {
              return DeliveryDashboardPage(
                onToggleDark: widget.onToggleDark,
                darkMode: widget.darkMode,
              );
            }
            return p;
          }).toList(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTapIndex,
        selectedItemColor: kPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// -----------------------------
// DASHBOARD PAGE
// -----------------------------
class DeliveryDashboardPage extends StatelessWidget {
  final VoidCallback? onToggleDark;
  final bool? darkMode;
  const DeliveryDashboardPage({super.key, this.onToggleDark, this.darkMode});

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;
    final todayDate = DateTime.now().toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            12,
          ), // slightly reduced
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kPrimary.withOpacity(0.9)],
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // centers vertically
                    children: [
                      const Text(
                        'Hello Rider 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        // prevents overflow
                        child: Text(
                          'Today: $todayDate',
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleDark,
                  icon: Icon(
                    darkMode == true
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: '18',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: '6',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _PrimaryActionButton(
              text: 'View Assigned Deliveries',
              icon: Icons.list_alt_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AssignedDeliveriesPage(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nearby Deliveries',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(3, (i) => _NearbyDeliveryTile(index: i)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: kMuted)),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyDeliveryTile extends StatelessWidget {
  final int index;
  const _NearbyDeliveryTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final sample = {
      'name': 'Customer ${index + 1}',
      'address': 'Street ${index + 3}, Main Town',
      'distance': '${(index + 1) * 1.2} km',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: kPrimary),
        title: Text(
          sample['name']!,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${sample['address']} • ${sample['distance']}'),
        trailing: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsPage(
                orderData: {
                  'orderId': 'ORD20$index',
                  'name': sample['name'],
                  'address': sample['address'],
                },
              ),
            ),
          ),
          child: const Text('Go'),
        ),
      ),
    );
  }
}

// -----------------------------
// ASSIGNED DELIVERIES (list)
// -----------------------------
class AssignedDeliveriesPage extends StatelessWidget {
  const AssignedDeliveriesPage({super.key});

  final List<Map<String, dynamic>> orders = const [
    {
      "orderId": "ORD100",
      "name": "Customer 1",
      "address": "Street No. 3, Main Town",
      "status": "Delivered",
    },
    {
      "orderId": "ORD101",
      "name": "Customer 2",
      "address": "Street No. 4, Main Town",
      "status": "Pending",
    },
    {
      "orderId": "ORD102",
      "name": "Customer 3",
      "address": "Street No. 5, Main Town",
      "status": "Pending",
    },
    {
      "orderId": "ORD103",
      "name": "Customer 4",
      "address": "Street No. 6, Main Town",
      "status": "Delivered",
    },
    {
      "orderId": "ORD104",
      "name": "Customer 5",
      "address": "Street No. 7, Main Town",
      "status": "Pending",
    },
    {
      "orderId": "ORD105",
      "name": "Customer 6",
      "address": "Street No. 8, Main Town",
      "status": "Pending",
    },
    {
      "orderId": "ORD106",
      "name": "Customer 7",
      "address": "Street No. 9, Main Town",
      "status": "Delivered",
    },
    {
      "orderId": "ORD107",
      "name": "Customer 8",
      "address": "Street No. 10, Main Town",
      "status": "Pending",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Deliveries')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: kPrimary.withOpacity(.12),
                child: const Icon(Icons.person, color: kPrimary),
              ),
              title: Text(
                order['name'],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(order['address']),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: order['status'] == 'Delivered'
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(
                    color: order['status'] == 'Delivered'
                        ? Colors.green
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsPage(orderData: order),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------
// ORDER DETAILS + OPENSTREETMAP + ROUTE
// -----------------------------
class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailsPage({super.key, required this.orderData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final GeoPoint shopLocation = GeoPoint(latitude: 24.8607, longitude: 67.0011);
  GeoPoint? customerLocation;
  late MapController mapController;
  bool _loadingRoute = true;
  final String _routeErrorMsg = '';

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initMapWithUserPosition: UserTrackingOption(enableTracking: false),
      initPosition: shopLocation,
    );
    // Example: static coord for customer (replace with real parsing if available)
    customerLocation = GeoPoint(latitude: 24.8678, longitude: 67.0500);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoCard('Order ID', widget.orderData['orderId'] ?? 'N/A'),
            _infoCard('Customer', widget.orderData['name'] ?? 'N/A'),
            _infoCard('Address', widget.orderData['address'] ?? 'N/A'),
            const SizedBox(height: 10),
            const Text('Route', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OSMFlutter(
                  controller: mapController,
                  osmOption: OSMOption(
                    zoomOption: ZoomOption(
                      initZoom: 13,
                      minZoomLevel: 3,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
                    ),
                    userLocationMarker: UserLocationMaker(
                      personMarker: MarkerIcon(
                        icon: Icon(
                          Icons.location_history_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      directionArrowMarker: MarkerIcon(
                        icon: Icon(Icons.double_arrow, size: 48),
                      ),
                    ),
                    roadConfiguration: RoadOption(roadColor: Colors.blue),
                  ),
                  onMapIsReady: (isReady) async {
                    if (isReady) {
                      await mapController.addMarker(
                        shopLocation,
                        markerIcon: MarkerIcon(
                          icon: Icon(Icons.store, color: Colors.blue, size: 48),
                        ),
                      );
                      if (customerLocation != null) {
                        await mapController.addMarker(
                          customerLocation!,
                          markerIcon: MarkerIcon(
                            icon: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 48,
                            ),
                          ),
                        );
                        // Stop loading indicator
                        if (mounted) setState(() => _loadingRoute = false);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingRoute) const LinearProgressIndicator(),
            if (_routeErrorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _routeErrorMsg,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openUpdateStatus(context),
              icon: const Icon(Icons.edit),
              label: const Text('Update Delivery Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _openUpdateStatus(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            UpdateStatusPage(orderId: widget.orderData['orderId'] ?? ''),
      ),
    );
  }
}

// -----------------------------
// UPDATE STATUS PAGE
// -----------------------------
class UpdateStatusPage extends StatelessWidget {
  final String orderId;
  UpdateStatusPage({super.key, required this.orderId});

  final List<String> statuses = [
    'Out for Delivery',
    'Delivered',
    'Failed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Status')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = statuses[i];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: s == 'Delivered' ? Colors.green : kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // TODO: call your backend to update status
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Status set to "$s" for $orderId')),
              );
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 12),
                Text(s, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------
// NOTIFICATIONS PAGE
// -----------------------------
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  final List<String> notifs = const [
    '3 new assignments',
    'ORD103 urgent',
    'Address updated for ORD107',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: kPrimary),
                const SizedBox(width: 12),
                Expanded(child: Text(notifs[i])),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------
// PROFILE PAGE
// -----------------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: kPrimary,
              child: Icon(Icons.person, color: Colors.white, size: 46),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delivery Partner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('+92 300 1234567', style: TextStyle(color: kMuted)),
            const SizedBox(height: 18),
            _profileRow('Vehicle', 'Bike'),
            const SizedBox(height: 12),
            _profileRow('Active Since', '2023'),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}

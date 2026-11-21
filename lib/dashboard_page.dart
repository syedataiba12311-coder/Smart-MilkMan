import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:milkman/deliverytracking_page.dart';
import 'package:milkman/notifications_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'orders_page.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String userName = "User"; // default

  final List<Widget> _pages = [
    HomePage(),
    OrdersPage(),
    DeliveryTrackingPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  void fetchUserName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      setState(() {
        userName = user.displayName!;
      });
    }
  }
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
      appBar: AppBar(
        elevation: 0,
        title: const Text("Smart Milkman"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(

        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(18.0),
            //
            //   //child: Text("Hi $userName 👋", style: AppTheme.heading1),
            // ),

            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: AppTheme.backgroundColor,
        color: AppTheme.primaryColor,
        buttonBackgroundColor: AppTheme.secondaryColor,
        height: 60,
        index: _selectedIndex,
        items: const [
          Icon(Icons.home, size: 28, color: Colors.white),
          Icon(Icons.list_alt, size: 28, color: Colors.white),
          Icon(Icons.local_shipping, size: 36, color: Colors.white),
          Icon(Icons.notifications, size: 28, color: Colors.white),
          Icon(Icons.person, size: 28, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'app_theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPortalPage extends StatelessWidget {
  const CustomerPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customer Portal'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance
                  .collection('customer')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots()
            : null,
        builder: (context, snapshot) {
          String name = "Loading...";
          String address = "Loading...";
          String phone = "Loading...";

          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['fullname'] ?? "N/A";
            address = data['address'] ?? "N/A";
            phone = data['phone'] ?? "N/A";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome to the Smart MilkMan Customer Portal',
                  textAlign: TextAlign.center,
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: 30),

                // 🧾 Customer Info Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                          title: const Text('Customer Name'),
                          subtitle: Text(name),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                          ),
                          title: const Text('Address'),
                          subtitle: Text(address),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: AppTheme.primaryColor,
                          ),
                          title: const Text('Contact'),
                          subtitle: Text(phone),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🥛 Options Section
                Text('Quick Actions', style: AppTheme.heading2),
                const SizedBox(height: 15),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  children: [
                    _buildPortalCard(
                      icon: Icons.shopping_cart,
                      title: 'Place Order',
                      onTap: () {
                        // TODO: Navigate to Place Order Page
                      },
                    ),
                    _buildPortalCard(
                      icon: Icons.history,
                      title: 'Order History',
                      onTap: () {
                        // TODO: Navigate to Order History Page
                      },
                    ),
                    _buildPortalCard(
                      icon: Icons.account_circle,
                      title: 'Profile',
                      onTap: () {
                        // TODO: Navigate to Profile Page
                      },
                    ),
                    _buildPortalCard(
                      icon: Icons.help_outline,
                      title: 'Support',
                      onTap: () {
                        // TODO: Navigate to Support Page
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortalCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.blue.shade50),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

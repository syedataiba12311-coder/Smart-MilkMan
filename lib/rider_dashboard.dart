import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'rider_login_page.dart';
import 'rider_map_page.dart';

class RiderDashboardPage extends StatefulWidget {
  final String riderName;
  final String riderPhone;
  final String sellerId;
  final String sellerName;

  const RiderDashboardPage({
    super.key,
    required this.riderName,
    required this.riderPhone,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<RiderDashboardPage> createState() => _RiderDashboardPageState();
}

class _RiderDashboardPageState extends State<RiderDashboardPage> {
  Future<void> _logout() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RiderLoginPage()),
      (route) => false,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Could not launch dialer for $phoneNumber");
    }
  }

  Future<void> _markAsDelivered(String orderId, String customerId) async {
    try {
      // 1. Update Order Status
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'Completed', 'paymentStatus': 'Paid'},
      );

      // 2. Notify Customer
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'title': 'Order Delivered ✅',
        'message': 'Your order has been delivered by ${widget.riderName}.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'orderId': orderId,
        'type': 'customer_order',
      });

      // 3. Notify Seller
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.sellerId,
        'title': 'Delivery Completed 🏁',
        'message':
            'Rider ${widget.riderName} delivered order for Customer ID: $customerId',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'orderId': orderId,
        'type': 'seller_order',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order Marked as Completed!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rider Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Welcome, ${widget.riderName}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            //.where('dairyName', isEqualTo: widget.sellerName) // Optional specific check
            .where('riderAssigned', isEqualTo: widget.riderName)
            .where('riderPhone', isEqualTo: widget.riderPhone)
            .where('status', isEqualTo: 'Out for Delivery')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Fallback: sometimes riderPhone might not be in the order if it's old data, try just name
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('riderAssigned', isEqualTo: widget.riderName)
                  .where('status', isEqualTo: 'Out for Delivery')
                  .snapshots(),
              builder: (context, retrySnapshot) {
                if (retrySnapshot.hasError) {
                  return Center(child: Text("Error: ${retrySnapshot.error}"));
                }
                if (!retrySnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildList(retrySnapshot.data!.docs);
              },
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildList(snapshot.data!.docs);
        },
      ),
    );
  }

  Widget _buildList(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bike, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No Active Deliveries",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Wait for the seller to assign deliveries",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return _buildDeliveryCard(docs[index].id, data);
      },
    );
  }

  Widget _buildDeliveryCard(String orderId, Map<String, dynamic> data) {
    // Prefer using cached delivery details from the order document
    if (data.containsKey('deliveryDetails') &&
        data['deliveryDetails'] != null) {
      final details = data['deliveryDetails'] as Map<String, dynamic>;
      return _buildCardUI(
        orderId,
        data,
        details['customerName'] ?? "Unknown",
        details['customerPhone'] ?? "N/A",
        details['customerAddress'] ?? "Unknown Address",
      );
    }

    final customerId = data['customerId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('customer')
          .doc(customerId)
          .get(),
      builder: (context, snapshot) {
        String customerName = "Loading...";
        String customerPhone = "Loading...";
        String customerAddress = data['address'] ?? "Unknown Address";

        if (snapshot.hasData && snapshot.data!.exists) {
          final cData = snapshot.data!.data() as Map<String, dynamic>;
          customerName = cData['fullname'] ?? "Unknown";
          customerPhone = cData['number'] ?? "N/A";
        }

        return _buildCardUI(
          orderId,
          data,
          customerName,
          customerPhone,
          customerAddress,
        );
      },
    );
  }

  Widget _buildCardUI(
    String orderId,
    Map<String, dynamic> data,
    String customerName,
    String customerPhone,
    String customerAddress,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Incoming Delivery",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Customer Details
            const Text(
              "Deliver To:",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              customerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              customerAddress,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            if (customerPhone != "N/A" && customerPhone != "Loading...") ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    customerPhone,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Contact Button
            if (customerPhone != "N/A" && customerPhone != "Loading...")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(customerPhone),
                  icon: const Icon(Icons.call),
                  label: Text("Call $customerPhone"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Milk: ${data['milkType'] ?? 'N/A'}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "Qty: ${data['quantity'] ?? '0'} L",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // View Route on Map Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RiderMapPage(
                        orderId: orderId,
                        customerName: customerName,
                        customerAddress: customerAddress,
                        customerPhone: customerPhone,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text("View Route on Map"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            // Mark as Completed Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markAsDelivered(orderId, data['customerId']),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Mark as Completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

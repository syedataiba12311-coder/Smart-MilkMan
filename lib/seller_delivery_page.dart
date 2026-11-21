import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class SellerDeliveryPage extends StatefulWidget {
  final String sellerDairyName;

  const SellerDeliveryPage({super.key, required this.sellerDairyName});

  @override
  State<SellerDeliveryPage> createState() => _SellerDeliveryPageState();
}

class _SellerDeliveryPageState extends State<SellerDeliveryPage> {
  Future<void> _markAsOutForDelivery(String orderId, String customerId) async {
    try {
      // 1. Fetch customer details first
      final customerDoc = await FirebaseFirestore.instance
          .collection('customer')
          .doc(customerId)
          .get();

      String cName = 'Unknown';
      String cPhone = 'N/A';
      String cAddress = 'Unknown Address';

      if (customerDoc.exists) {
        final cData = customerDoc.data() as Map<String, dynamic>;
        cName = cData['fullname'] ?? 'Unknown';
        cPhone = cData['phone'] ?? 'N/A';
        cAddress = cData['address'] ?? 'Unknown Address';
      }

      // 2. Update order status AND snapshot key delivery details
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {
          'status': 'Out for Delivery',
          'deliveryDetails': {
            'customerName': cName,
            'customerPhone': cPhone,
            'customerAddress': cAddress,
          },
        },
      );

      // Send Notification to Customer
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'title': 'Out for Delivery',
        'message': 'Your order is out for delivery! Get ready to receive it.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'orderId': orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order marked as Out for Delivery 🚚"),
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

  Future<void> _markAsDelivered(String orderId, String customerId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'Completed', 'paymentStatus': 'Paid'},
      );

      // Send Notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'title': 'Order Delivered ✅',
        'message': 'Your order has been successfully delivered. Enjoy!',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'orderId': orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order Marked as Delivered ✅"),
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

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Could not launch dialer for $phoneNumber");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Active Deliveries",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('dairyName', isEqualTo: widget.sellerDairyName)
            .where('status', whereIn: ['Accepted', 'Paid', 'Out for Delivery'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Filter out orders with no rider assigned
            return data['riderAssigned'] != null &&
                data['riderAssigned'] != 'No rider registered';
          }).toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No pending deliveries",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Assign riders in Manage Orders first",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              return _buildDeliveryCard(order.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(String orderId, Map<String, dynamic> data) {
    final customerId = data['customerId'];
    final riderName = data['riderAssigned'] ?? 'Unknown';
    final riderPhone = data['riderPhone'] ?? 'N/A';
    final milkType = data['milkType'] ?? 'N/A';
    final quantity = data['quantity'] ?? '0';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('customer')
          .doc(customerId)
          .get(),
      builder: (context, snapshot) {
        String customerName = "Loading...";
        String customerAddress = "Loading...";
        String customerPhone = "N/A";

        if (snapshot.hasData && snapshot.data!.exists) {
          final cData = snapshot.data!.data() as Map<String, dynamic>;
          customerName = cData['fullname'] ?? "Unknown";
          customerAddress = cData['address'] ?? "Unknown Address";
          customerPhone = cData['phone'] ?? "N/A";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with Rider Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.motorcycle,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            riderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          InkWell(
                            onTap: () => _launchDialer(riderPhone),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  riderPhone,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person_outline, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                customerAddress,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              if (customerPhone != "N/A") ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _launchDialer(customerPhone),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        customerPhone,
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Order Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(Icons.water_drop, milkType, "Milk Type"),
                        _buildInfoItem(Icons.scale, "$quantity L", "Quantity"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: data['status'] == 'Out for Delivery'
                          ? ElevatedButton.icon(
                              onPressed: () =>
                                  _markAsDelivered(orderId, customerId),
                              icon: const Icon(Icons.check_circle),
                              label: const Text("Mark as Delivered"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: (data['paymentStatus'] == 'Paid' || data['status'] == 'Paid')
                                  ? () => _markAsOutForDelivery(orderId, customerId)
                                  : () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Payment pending! Customer must pay before delivery can start."),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                              icon: Icon(
                                (data['paymentStatus'] == 'Paid' || data['status'] == 'Paid')
                                    ? Icons.send_rounded
                                    : Icons.hourglass_empty,
                              ),
                              label: Text(
                                (data['paymentStatus'] == 'Paid' || data['status'] == 'Paid')
                                    ? "Delivery on Route"
                                    : "Waiting for Payment...",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (data['paymentStatus'] == 'Paid' || data['status'] == 'Paid')
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class ManageCustomerOrdersPage extends StatefulWidget {
  final String sellerDairyName;

  const ManageCustomerOrdersPage({super.key, required this.sellerDairyName});

  @override
  State<ManageCustomerOrdersPage> createState() =>
      _ManageCustomerOrdersPageState();
}

class _ManageCustomerOrdersPageState extends State<ManageCustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? sellerId;
  List<Map<String, dynamic>> ridersList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSellerRiders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerRiders() async {
    final query = await FirebaseFirestore.instance
        .collection('owner')
        .where('dairyName', isEqualTo: widget.sellerDairyName)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      sellerId = doc.id;
      final data = doc.data();

      if (data['ridersList'] != null) {
        ridersList = List<Map<String, dynamic>>.from(
          data['ridersList'].map((r) {
            return {
              'name': r['name'] ?? 'Unknown',
              'phone': r['phone'] ?? 'N/A',
            };
          }),
        );
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _acceptOrder(
    String orderId,
    String customerId,
    Map<String, dynamic> data,
  ) async {
    // 1. DEDUCT FROM INVENTORY
    final orderQtyString = data['quantity']?.toString() ?? "0";
    final double orderQty = double.tryParse(orderQtyString.split(" ")[0]) ?? 0;

    if (sellerId != null) {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('owner')
          .doc(sellerId!)
          .get();
      final currentStock = (sellerDoc.data()?['availableMilk'] ?? 0).toDouble();

      await FirebaseFirestore.instance
          .collection('owner')
          .doc(sellerId!)
          .update({
            'availableMilk': (currentStock >= orderQty)
                ? (currentStock - orderQty)
                : 0,
          });
    }

    if (ridersList.isEmpty) {
      // 2. UPDATE ORDER STATUS (No Rider)
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'Accepted',
            'riderAssigned': 'No rider registered',
            'riderPhone': 'N/A',
          });

      // Send Notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'title': 'Order Accepted',
        'message': 'Your order has been accepted. No rider assigned yet.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'orderId': orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order Accepted (No riders available)")),
        );
      }
      return;
    }

    Map<String, String>? selectedRider;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assign Rider"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ridersList.length,
            itemBuilder: (context, index) {
              final rider = ridersList[index];
              final riderName = rider['name'] ?? 'Unknown';
              final riderPhone = rider['phone'] ?? 'N/A';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.motorcycle)),
                title: Text(riderName),
                subtitle: Text(riderPhone),
                onTap: () {
                  selectedRider = {'name': riderName, 'phone': riderPhone};
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );

    if (selectedRider != null) {
      // 2. UPDATE ORDER STATUS (With Rider)
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'Accepted',
            'riderAssigned': selectedRider!['name'],
            'riderPhone': selectedRider!['phone'],
          });

      // Send Notification with Rider Details
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'title': 'Order Accepted',
        'message':
            'Your order has been accepted.\nRider: ${selectedRider!['name']}\nPhone: ${selectedRider!['phone']}',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'orderId': orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Order Accepted & Assigned to ${selectedRider!['name']}",
            ),
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId, String customerId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'Rejected',
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': customerId,
      'title': 'Order Rejected',
      'message': 'Your order has been rejected by the seller.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'orderId': orderId,
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order Rejected")));
    }
  }

  Future<void> _completeOrder(String orderId, String customerId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'Completed',
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': customerId,
      'title': 'Order Completed',
      'message': 'Your order has been marked as completed.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'orderId': orderId,
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order Marked Completed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Manage Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Active"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("Pending"),
          _buildOrderList("Accepted"),
          _buildOrderList("History"),
        ],
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('dairyName', isEqualTo: widget.sellerDairyName);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';

          if (statusFilter == "History") {
            return status == 'Accepted' ||
                status == 'Paid' ||
                status == 'Completed' ||
                status == 'Rejected';
          } else if (statusFilter == "Accepted") {
            return (status == 'Accepted' || status == 'Paid');
          } else {
            return status == statusFilter;
          }
        }).toList();

        // Sort by date descending
        filteredDocs.sort((a, b) {
          final aDate =
              (a.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
          final bDate =
              (b.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No $statusFilter orders",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final orderData =
                filteredDocs[index].data() as Map<String, dynamic>;
            final orderId = filteredDocs[index].id;
            return _buildOrderCard(orderData, orderId, statusFilter, orderData);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> data,
    String orderId,
    String currentTab,
    Map<String, dynamic> fullOrderData,
  ) {
    final customerId = data['customerId'];
    final milkType = data['milkType'] ?? "N/A";
    final quantity = data['quantity'] ?? "N/A";
    final status = data['status'] ?? "Pending";
    final riderAssigned = data['riderAssigned'];
    final timestamp = data['orderDate'] as Timestamp?;
    final dateStr = timestamp != null
        ? "${timestamp.toDate().day}/${timestamp.toDate().month} ${timestamp.toDate().hour}:${timestamp.toDate().minute}"
        : "No Date";

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('customer')
          .doc(customerId)
          .get(),
      builder: (context, customerSnap) {
        String customerName = "Unknown Customer";
        String customerAddress = data['address'] ?? "Address not available";

        if (customerSnap.hasData && customerSnap.data!.exists) {
          final cData = customerSnap.data!.data() as Map<String, dynamic>;
          customerName = cData['fullname'] ?? "Unknown";
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                customerAddress,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(Icons.water_drop, milkType, "Type"),
                        _buildInfoItem(Icons.scale, "$quantity L", "Quantity"),
                        if (riderAssigned != null)
                          _buildInfoItem(
                            Icons.motorcycle,
                            riderAssigned,
                            "Rider",
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (currentTab == "Pending")
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectOrder(orderId, customerId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Reject"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _acceptOrder(orderId, customerId, fullOrderData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Accept"),
                        ),
                      ),
                    ],
                  ),
                ),
              if (currentTab == "Accepted")
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeOrder(orderId, customerId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Mark as Completed"),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Out for Delivery':
        return Colors.cyan;
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

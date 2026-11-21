import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Future<void> _showPaymentDialog(
    String orderId,
    double amount,
    Map<String, dynamic> orderData,
  ) async {
    String selectedPayment = "PayFast";
    final accountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Complete Payment"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Amount: Rs. ${amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPayment,
                    items: ["PayFast"]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedPayment = val!);
                    },
                    decoration: const InputDecoration(
                      labelText: "Payment Method",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Account Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (accountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter account number"),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    await _processPayment(
                      orderId,
                      orderData,
                      selectedPayment,
                      accountController.text,
                    );
                  },
                  child: const Text("Pay Now"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processPayment(
    String orderId,
    Map<String, dynamic> orderData,
    String method,
    String account,
  ) async {
    try {
      if (method == 'PayFast') {
        // If dummy keys are used, simulate a successful transaction for testing the system!
        if ('YOUR_MERCHANT_ID' == 'YOUR_MERCHANT_ID' || 'YOUR_SECURED_KEY' == 'YOUR_SECURED_KEY') {
          // Simulate network delay
          await Future.delayed(const Duration(seconds: 2));
          debugPrint("PayFast Dummy Mode: Skipping real HTTP request and simulating success.");
        } else {
          // 1. Get Access Token from PayFast
          final tokenResponse = await http.post(
            Uri.parse("https://ipg.gopayfast.com/api/v1/OAuth/token"),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'merchant_id': 'YOUR_MERCHANT_ID', // Replace with valid Merchant ID
              'grant_type': 'client_credentials',
              'secured_key': 'YOUR_SECURED_KEY', // Replace with valid Secured Key
            },
          );

          if (tokenResponse.statusCode == 200) {
            final tokenBody = jsonDecode(tokenResponse.body);
            if (!tokenBody.containsKey('token')) {
              throw Exception("Failed to retrieve token from PayFast: ${tokenResponse.body}");
            }
            final accessToken = tokenBody['token'];

            // 2. Initiate Transaction
            final txResponse = await http.post(
              Uri.parse("https://ipg.gopayfast.com/api/v1/transaction"),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                "basket_id": orderId,
                "transaction_amount": orderData['totalPrice'].toString(),
                "customer_mobile_no": account,
                "CURRENCY_CODE": "PKR",
                "txnamt": orderData['totalPrice'].toString(),
              }),
            );

            if (txResponse.statusCode != 200) {
              throw Exception("PayFast transaction API failed: ${txResponse.statusCode} - ${txResponse.body}");
            }
          } else {
             throw Exception("Failed to authenticate with PayFast: ${tokenResponse.statusCode} - ${tokenResponse.body}");
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'Paid',
            'paymentStatus': 'Paid',
            'paymentMethod': method,
            'accountNumber': account,
            'paidAt': FieldValue.serverTimestamp(),
          });

      if (orderData['sellerId'] != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': orderData['sellerId'],
          'title': 'Payment Received 💰',
          'message': 'Order #$orderId has been paid via $method.',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'orderId': orderId,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Payment Successful! ✅")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("Payments", style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Pending", icon: Icon(Icons.timer_outlined)),
              Tab(text: "History", icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildPaymentList(user, isHistory: false),
              _buildPaymentList(user, isHistory: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList(User? user, {required bool isHistory}) {
    if (user == null) {
      return const Center(child: Text("Please login to view payments"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              final status = data['status'];
              final pStatus = data['paymentStatus'];

              if (isHistory) {
                return pStatus == 'Paid' || status == 'Paid';
              } else {
                return status == 'Accepted' && pStatus != 'Paid';
              }
            }).toList() ??
            [];

        // Sort dynamically: descending by orderDate (or paidAt if history)
        docs.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          
          Timestamp? aTime = isHistory
              ? (aData['paidAt'] ?? aData['orderDate'])
              : aData['orderDate'];
          Timestamp? bTime = isHistory
              ? (bData['paidAt'] ?? bData['orderDate'])
              : bData['orderDate'];

          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHistory ? Icons.history : Icons.check_circle_outline,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isHistory ? "No payment history" : "No pending payments",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _paymentCard(data, doc.id, isHistory: isHistory);
          },
        );
      },
    );
  }

  Widget _paymentCard(
    Map<String, dynamic> data,
    String docId, {
    required bool isHistory,
  }) {
    Timestamp? timestamp = isHistory ? (data['paidAt'] ?? data['orderDate']) : data['orderDate'];
    String dateLabel = isHistory && data['paidAt'] != null ? "Paid On:" : "Date:";
    String date = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : "Unknown Date";
    String qty = "${data['quantity'] ?? 0} ";
    double totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
    String method = data['paymentMethod'] ?? "Unknown";

    // Resolve seller name
    String sellerName = data['dairyName'] ?? "Unknown Seller";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seller: $sellerName",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$dateLabel $date",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Quantity: $qty",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (isHistory) ...[
                        Text(
                          "Method: $method",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        "Total Amount: Rs. ${totalPrice.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: isHistory ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isHistory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      "PAID",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isHistory) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(docId, totalPrice, data),
                  icon: const Icon(Icons.payment),
                  label: const Text("Pay Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

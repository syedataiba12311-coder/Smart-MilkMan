import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class MilkSubscriptionPage extends StatefulWidget {
  final String? sellerName;
  final String? milkType;
  final double? pricePerLiter;
  final String? sellerId;

  const MilkSubscriptionPage({
    super.key,
    this.sellerName,
    this.milkType,
    this.pricePerLiter,
    this.sellerId,
  });

  @override
  State<MilkSubscriptionPage> createState() => _MilkSubscriptionPageState();
}

class _MilkSubscriptionPageState extends State<MilkSubscriptionPage> {
  String selectedQuantity = "1 Liter";
  String selectedDays = "30 Days";
  String selectedPayment = "PayFast";
  TextEditingController addressController = TextEditingController();
  late double pricePerLiter;
  double totalPrice = 0;
  TextEditingController accountController = TextEditingController();
  bool isLoading = false;

  // Price Calculation
  void calculatePrice() {
    double qty = double.parse(selectedQuantity.split(" ")[0]);
    int days = int.parse(selectedDays.split(" ")[0]);

    totalPrice = qty * days * pricePerLiter;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    pricePerLiter = widget.pricePerLiter ?? 250;
    calculatePrice();
  }


  Future<void> _subscribe() async {
    if (widget.sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Seller information missing")),
      );
      return;
    }
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter delivery address")),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // -----------------------------------------------
      // SAVE SUBSCRIPTION INSIDE OWNER → SUBSCRIPTIONS
      // -----------------------------------------------

      final subscriptionData = {
        'customerId': user.uid,
        'customerEmail': user.email,
        'customerPhone': user.phoneNumber, // Use auth phone or update later
        'quantity': selectedQuantity,
        'duration': selectedDays,
        'totalPrice': totalPrice,
        'paymentMethod': 'Pending',
        'accountNumber': 'Pending',
        'startDate': FieldValue.serverTimestamp(),
        'status': 'Requested',
        'milkType': widget.milkType ?? 'Fresh Milk',
        'address': addressController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('owner')
          .doc(widget.sellerId)
          .collection('subscriptions')
          .add(subscriptionData);

      // -----------------------------------------------
      // ⭐ IMPORTANT: SAVE AS ORDER FOR SELLER DASHBOARD
      // -----------------------------------------------

      await FirebaseFirestore.instance.collection('orders').add({
        'sellerId': widget.sellerId,
        'dairyName': widget.sellerName ?? "Unknown Dairy",

        'customerId': user.uid,
        'customerEmail': user.email,
        'milkType': widget.milkType,
        'quantity': selectedQuantity,
        'totalPrice': totalPrice,

        'status': 'Pending', // For Manage Orders Page
        'orderDate': FieldValue.serverTimestamp(),
        'paymentStatus': 'Pending',
        'address': addressController.text.trim(),
      });

      // -----------------------------------------------
      // SUCCESS MESSAGE
      // -----------------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request Sent! waiting for seller approval ⏳"),
          backgroundColor: AppTheme.primaryColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Subscription failed: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Milk Subscription")),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fresh Milk Subscription",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.sellerName != null
                          ? "From ${widget.sellerName} • ${widget.milkType ?? 'Fresh Milk'}"
                          : "Get pure milk delivered daily to your doorstep.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Text("Select Daily Quantity", style: AppTheme.heading2),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                initialValue: selectedQuantity,
                decoration: AppTheme.inputDecoration(
                  "Quantity",
                  Icons.local_drink,
                ),
                items:
                    [
                          "0.5 Liter",
                          "1 Liter",
                          "1.5 Liters",
                          "2 Liters",
                          "3 Liters",
                        ]
                        .map(
                          (qty) =>
                              DropdownMenuItem(value: qty, child: Text(qty)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedQuantity = value!;
                    calculatePrice();
                  });
                },
              ),

              const SizedBox(height: 25),

              Text("Duration", style: AppTheme.heading2),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                initialValue: selectedDays,
                decoration: AppTheme.inputDecoration(
                  "Duration",
                  Icons.calendar_today,
                ),
                items: ["7 Days", "15 Days", "30 Days"]
                    .map(
                      (days) =>
                          DropdownMenuItem(value: days, child: Text(days)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDays = value!;
                    calculatePrice();
                  });
                },
              ),

              const SizedBox(height: 25),

              Text("Delivery Address", style: AppTheme.heading2),
              const SizedBox(height: 10),

              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: AppTheme.inputDecoration(
                  "Enter your full address",
                  Icons.location_on,
                ),
              ),
              const SizedBox(height: 25),

              // Price Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Price:",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        "Rs. ${totalPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _subscribe,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Request Subscription",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}

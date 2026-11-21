import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'seller_details_page.dart';

class OrderMilkPage extends StatefulWidget {
  const OrderMilkPage({super.key});

  @override
  State<OrderMilkPage> createState() => _OrderMilkPageState();
}

class _OrderMilkPageState extends State<OrderMilkPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text("Order Milk", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: AppTheme.inputDecoration(
                "Search dairy...",
                Icons.search,
              ).copyWith(filled: true, fillColor: Colors.white),
            ),

            const SizedBox(height: 25),

            Text("Nearby Dairies", style: AppTheme.heading2),
            const SizedBox(height: 15),

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

                  final docs = snapshot.data!.docs;

                  // Filter docs based on search query
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final name = (data['dairyName']?.toString() ?? "")
                        .toLowerCase();
                    final area = (data['area']?.toString() ?? "").toLowerCase();
                    final owner = (data['ownerName']?.toString() ?? "")
                        .toLowerCase();

                    return name.contains(_searchQuery) ||
                        area.contains(_searchQuery) ||
                        owner.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text("No dairies found"));
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final dairyDoc = filteredDocs[index];

                      // Always safe because we use data(), not get()
                      final data =
                          dairyDoc.data() as Map<String, dynamic>? ?? {};

                      // SAFE READ — no exception even if missing
                      final name =
                          data['dairyName']?.toString() ?? "Unknown Dairy";
                      final area = data['area']?.toString() ?? "No location";
                      final owner =
                          data['ownerName']?.toString() ?? "Unknown Owner";
                      final double stock = (data['availableMilk'] ?? 0)
                          .toDouble();
                      final bool isOutOfStock = stock <= 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(Icons.store, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isOutOfStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Text(
                                    "LIMIT EXCEEDED",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text("$area • Owner: $owner"),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerDetailsPage(
                                  sellerId: dairyDoc.id,
                                  sellerData: data,
                                ),
                              ),
                            );
                          },
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
  }
}

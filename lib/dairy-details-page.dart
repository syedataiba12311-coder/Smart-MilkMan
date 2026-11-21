import 'package:flutter/material.dart';

class DairyDetailPage extends StatelessWidget {
  final Map<String, dynamic> dairyData;

  const DairyDetailPage({super.key, required this.dairyData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dairyData['dairyName'] ?? 'Dairy Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dairyData['dairyName'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Milk Types: ${dairyData['milkType'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Rating: ${dairyData['rating'] ?? '0'} ⭐",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Contact: ${dairyData['contact'] ?? 'Not Provided'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Address: ${dairyData['address'] ?? 'Not Provided'}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
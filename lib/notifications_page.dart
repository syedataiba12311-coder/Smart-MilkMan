import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markAllRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final unreadDocs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: user == null
          ? const Center(child: Text("Please login to view notifications"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Notifications 🔔", style: AppTheme.heading1),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('notifications')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No notifications yet",
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          return _notificationCard(doc.id, data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _notificationCard(String docId, Map<String, dynamic> data) {
    bool unread = !(data["read"] ?? false);
    dynamic rawTimestamp = data["timestamp"];
    Timestamp? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      DateTime? parsed = DateTime.tryParse(rawTimestamp);
      if (parsed != null) timestamp = Timestamp.fromDate(parsed);
    }
    
    String timeString = timestamp != null
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
        : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: unread
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
        border: Border.all(
          color: unread ? Colors.blue.shade50 : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: unread
              ? AppTheme.primaryColor
              : Colors.grey.shade400,
          child: Icon(
            unread ? Icons.notifications_active : Icons.notifications,
            color: Colors.white,
          ),
        ),
        title: Text(
          data["title"] ?? "Notification",
          style: TextStyle(
            fontWeight: unread ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
            color: unread ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(data["message"] ?? ""),
        ),
        trailing: Text(
          timeString,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          if (unread) {
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(docId)
                .update({'read': true});
          }
        },
      ),
    );
  }
}

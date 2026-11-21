import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milkman/my_account_page.dart';
import 'app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {});
  }



  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password reset email sent to ${user.email}"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Account"),
          _menuTile(Icons.person, "Edit Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyAccountPage()),
            );
          }),
          _menuTile(Icons.payment, "Payment Settings", () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment Settings coming soon")),
            );
          }),
          _menuTile(Icons.security, "Privacy & Security", () {
            _showPrivacySecurityDialog(context);
          }),

          const SizedBox(height: 10),
          _sectionDivider(),
          _sectionTitle("Support"),
          _menuTile(Icons.help_center, "Help & Support", () {
            _showHelpDialog(context);
          }),
          _menuTile(Icons.info, "About App", () {
            _showAboutDialog(context);
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.only(top: 5, bottom: 5),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help & Support"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("For any queries, contact us at:"),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text("support@smartmilkman.com"),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text("+92 300 1234567"),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "Smart Milkman",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(
        Icons.local_drink,
        size: 40,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          "Smart Milkman is your digital solution for daily milk deliveries. We connect customers, riders, and sellers efficiently.",
        ),
      ],
    );
  }

  void _showPrivacySecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy & Security"),
        content: const Text("Manage your account security."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _changePassword();
            },
            child: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

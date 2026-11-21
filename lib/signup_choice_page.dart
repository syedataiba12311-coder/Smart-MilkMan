import 'package:flutter/material.dart';
import 'customer_signup_page.dart'; // existing customer signup page
import 'dairy_form_page.dart'; // seller (List Dairy) page - contains DairyFormPage
import 'app_theme.dart';

class SignupChoicePage extends StatelessWidget {
  const SignupChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Create Your Account"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🥛 App Icon / Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_drink,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Join Smart Milkman",
                textAlign: TextAlign.center,
                style: AppTheme.heading1,
              ),
              const SizedBox(height: 10),
              Text(
                "Choose your role to get started",
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // 🧑‍🌾 Seller Button (navigates to DairyFormPage)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DairyFormPage()),
                    );
                  },
                  icon: const Icon(Icons.store_mall_directory_rounded),
                  label: const Text(
                    "Sign Up as Seller",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  style: AppTheme.primaryButtonStyle,
                ),
              ),

              const SizedBox(height: 20),
              // 👤 Customer Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerSignupPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text(
                    "Sign Up as Customer",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Already have an account
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

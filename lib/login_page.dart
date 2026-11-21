import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milkman/seller_dashboard_page.dart';
import 'customer_login_page.dart';
import 'dairy_form_page.dart';
import 'rider_login_page.dart';
import 'app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? selectedRole;
  final _ownerController = TextEditingController();
  final _cnicController = TextEditingController();

  bool isLoading = false;
  bool _isUrdu = false;

  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login',
      'smart_milkman': 'Smart Milkman',
      'welcome_back': 'Welcome back, please login to continue',
      'choose_role': 'Choose your role',
      'seller': 'Seller',
      'customer': 'Customer',
      'rider': 'Rider',
      'seller_login': 'Seller Login',
      'owner_name': 'Owner Name',
      'cnic_number': 'CNIC Number',
      'forgot_password': 'Forgot Password?',
      'no_account': "Don't have an account? Sign Up",
      'language': 'Language',
      'select_language': 'Select Language',
      'fill_fields': 'Please fill in all fields',
      'invalid_credentials': 'Invalid Owner Name or CNIC',
      'reset_password': 'Reset Password',
      'enter_email_reset': 'Enter your email to receive a password reset link.',
      'email': 'Email',
      'send_email': 'Send Email',
      'cancel': 'Cancel',
      'reset_sent': 'Password reset email sent! 📧',
      'slogan': 'Pure Milk at Your Doorstep',
    },
    'ur': {
      'login': 'لاگ ان',
      'smart_milkman': 'سمارٹ ملک مین',
      'welcome_back': 'خوش آمدید، جاری رکھنے کے لیے براہ کرم لاگ ان کریں',
      'choose_role': 'اپنا کردار منتخب کریں',
      'seller': 'فروخت کنندہ',
      'customer': 'گاہک',
      'rider': 'رائڈر',
      'seller_login': 'سیلر لاگ ان',
      'owner_name': 'مالک کا نام',
      'cnic_number': 'شناختی کارڈ نمبر',
      'forgot_password': 'پاس ورڈ بھول گئے؟',
      'no_account': 'اکاؤنٹ نہیں ہے؟ سائن اپ کریں',
      'language': 'زبان',
      'select_language': 'زبان منتخب کریں',
      'fill_fields': 'براہ کرم تمام خانے پُر کریں',
      'invalid_credentials': 'مالک کا نام یا شناختی کارڈ نمبر غلط ہے',
      'reset_password': 'پاس ورڈ دوبارہ ترتیب دیں',
      'enter_email_reset':
          'پاس ورڈ ری سیٹ لنک حاصل کرنے کے لیے اپنا ای میل درج کریں۔',
      'email': 'ای میل',
      'send_email': 'ای میل بھیجیں',
      'cancel': 'منسوخ کریں',
      'reset_sent': 'پاس ورڈ ری سیٹ ای میل بھیج دی گئی ہے! 📧',
      'slogan': 'خالص دودھ، آپ کے دروازے پر',
    },
  };

  String _t(String key) {
    return _localizedValues[_isUrdu ? 'ur' : 'en']![key] ?? key;
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(_t('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("English"),
                trailing: !_isUrdu
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _isUrdu = false);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("اردو (Urdu)"),
                trailing: _isUrdu
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _isUrdu = true);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> sellerLogin() async {
    final String owner = _ownerController.text.trim();
    final String cnic = _cnicController.text.trim();

    if (owner.isEmpty || cnic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('fill_fields'))),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('owner')
          .where('cnic', isEqualTo: cnic)
          .where('ownerName', isEqualTo: owner)
          .get();

      if (!mounted) return;

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t("invalid_credentials"))),
        );
        return;
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'Pending';

      // ✅ Check status
      if (status == 'Pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Your registration request is pending. Please wait for admin approval."),
          ),
        );
        return;
      }

      if (status == 'Rejected') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Your registration request was rejected. Please contact admin."),
          ),
        );
        return;
      }

      // ✅ Only approved sellers can login
      if (status == 'Approved') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SellerDashboardPage(cnic: cnic),
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  //----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_t('login')),
        leading: selectedRole != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => selectedRole = null),
              )
            : null,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'language') {
                _showLanguageDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(_t('language')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              //   child: const Icon(
              //     Icons.local_drink,
              //     size: 60,
              //     color: AppTheme.primaryColor,
              //   ),
              // ),
               child: ClipOval(
                    child: Image.asset(
                "assets/images/logo.jpg",
                width: 100,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),),
              const SizedBox(height: 10),
              Text(_t('smart_milkman'), style: AppTheme.heading1),
              const SizedBox(height: 10),
              Text(
                _t('slogan'),
                style: AppTheme.bodyText.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Step 1: Role Selection
              if (selectedRole == null) ...[
                Text(_t('choose_role'), style: AppTheme.heading2),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoleCard(_t("seller"), Icons.store, "Seller"),
                      const SizedBox(width: 12),
                      _buildRoleCard(_t("customer"), Icons.person, "Customer"),
                      const SizedBox(width: 12),
                      _buildRoleCard(_t("rider"), Icons.motorcycle, "Rider"),
                    ],
                  ),
                ),
              ]
              // Step 2: Seller Login
              else if (selectedRole == "Seller") ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(_t("seller_login"), style: AppTheme.heading2),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _ownerController,
                          decoration: AppTheme.inputDecoration(
                            _t("owner_name"),
                            Icons.person,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _cnicController,
                          decoration: AppTheme.inputDecoration(
                            _t("cnic_number"),
                            Icons.credit_card,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: sellerLogin,
                                  child: Text(_t("login")),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DairyFormPage()),
                    );
                  },
                  child: Text(
                    _t("no_account"),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
              // Step 3: Customer Login
              else if (selectedRole == "Customer") ...[
                _navigateToCustomerLogin(context),
              ]
              // Step 4: Rider Login
              else if (selectedRole == "Rider") ...[
                _navigateToRiderLogin(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigateToCustomerLogin(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
      );
      setState(() => selectedRole = null);
    });

    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }

  Widget _navigateToRiderLogin(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiderLoginPage()),
      );
      setState(() => selectedRole = null);
    });

    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }
  Widget _buildRoleCard(String displayName, IconData icon, String roleKey) {
    final bool isSelected = selectedRole == roleKey;

    return GestureDetector(
      onTap: () => setState(() => selectedRole = roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          // 🔥 Soft professional shadow
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.25)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
          //  Border highlight
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //  Icon with modern badge style
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.15),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                )
                    : null,
                color: isSelected
                    ? null
                    : Colors.grey.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            //  Title
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            //  Subtle subtitle (NEW – makes it look premium)
            Text(
              _getRoleSubtitle(roleKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            //  Selected indicator (very modern touch)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Selected",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleSubtitle(String role) {
    switch (role) {
      case "Seller":
        return "Manage dairy & sell milk";
      case "Customer":
        return "Order fresh milk daily";
      case "Rider":
        return "Deliver milk to customers";
      default:
        return "";
    }
  }
}

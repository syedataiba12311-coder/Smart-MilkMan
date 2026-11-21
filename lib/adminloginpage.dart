// import 'package:flutter/material.dart';
// import 'app_theme.dart';
// import 'admin.dart';
//
// class AdminLoginPage extends StatefulWidget {
//   const AdminLoginPage({super.key});
//
//   @override
//   State<AdminLoginPage> createState() => _AdminLoginPageState();
// }
//
// class _AdminLoginPageState extends State<AdminLoginPage> {
//
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   final _formKey = GlobalKey<FormState>();
//
//   final String adminEmail = "admin@gmail.com";
//   final String adminPassword = "admin123";
//
//   bool isLoading = false;
//   bool obscurePassword = true;
//
//   void loginAdmin() {
//
//     if (!_formKey.currentState!.validate()) return;
//
//     final email = _emailController.text.trim();
//     final password = _passwordController.text.trim();
//
//     if (email == adminEmail && password == adminPassword) {
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const SmartMilkManAdminApp()),
//       );
//
//     } else {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Invalid username or password"),
//           backgroundColor: AppTheme.errorColor,
//         ),
//       );
//
//     }
//   }
//
//   void _showForgotPasswordDialog() {
//
//     showDialog(
//       context: context,
//       builder: (context) {
//
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: const Text("Forgot Password"),
//           content: const Text(
//             "Please contact system administrator to reset the admin password.",
//             style: AppTheme.bodyText,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("OK"),
//             )
//           ],
//         );
//
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin Login")),
//
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//
//           child: Form(
//             key: _formKey,
//             //
//             // child: Card(
//             //   elevation: 4,
//             //   shape: RoundedRectangleBorder(
//             //     borderRadius: BorderRadius.circular(16),
//             //   ),
//             //
//             //   child: Padding(
//             //     padding: const EdgeInsets.all(28),
//             //
//             //     child: Column(
//             //       mainAxisSize: MainAxisSize.min,
//             //       children: [
//
//            child:  Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 420),
//                 child: Card(
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(28),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                     const Icon(
//                       Icons.admin_panel_settings,
//                       size: 60,
//                       color: AppTheme.primaryColor,
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     const Text(
//                       "Administrator Panel",
//                       style: AppTheme.heading1,
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     const Text(
//                       "Login to manage Smart Milkman system",
//                       style: AppTheme.bodyText,
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     TextFormField(
//                       controller: _emailController,
//                       decoration: AppTheme.inputDecoration(
//                         "Admin Email",
//                         Icons.email,
//                       ),
//
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return "Email cannot be empty";
//                         }
//                         return null;
//                       },
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: obscurePassword,
//
//                       decoration: AppTheme.inputDecoration(
//                         "Password",
//                         Icons.lock,
//                       ).copyWith(
//
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             obscurePassword
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                           ),
//
//                           onPressed: () {
//                             setState(() {
//                               obscurePassword = !obscurePassword;
//                             });
//                           },
//                         ),
//                       ),
//
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return "Password cannot be empty";
//                         }
//                         return null;
//                       },
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: AppTheme.primaryButtonStyle,
//                         onPressed: loginAdmin,
//                         child: const Text(
//                           "Login",
//                           style: AppTheme.buttonText,
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 10),
//
//                     TextButton(
//                       onPressed: _showForgotPasswordDialog,
//                       child: const Text(
//                         "Forgot Password?",
//                         style: TextStyle(
//                           color: AppTheme.primaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     )
//
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//         )
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'admin.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;

  final String adminEmail = "admin@gmail.com";
  final String adminPassword = "admin123";

  void loginAdmin() {

    if (!_formKey.currentState!.validate()) return;

    if (_emailController.text.trim() == adminEmail &&
        _passwordController.text.trim() == adminPassword) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SmartMilkManAdminApp()),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid username or password"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void forgotPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Forgot Password"),
        content: const Text(
            "Please contact system administrator to reset admin credentials."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Row(
        children: [

          /// LEFT SIDE (LOGO / IMAGE)
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.primaryColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Image.asset(
                      "assets/images/logo.jpg", // your logo
                      width: 180,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "SMART MILKMAN",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Milk Supply Management System",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          /// RIGHT SIDE (LOGIN CARD)
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.backgroundColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(30),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            const Text(
                              "Admin Login",
                              style: AppTheme.heading2,
                            ),

                            const SizedBox(height: 25),

                            TextFormField(
                              controller: _emailController,
                              decoration: AppTheme.inputDecoration(
                                  "Email", Icons.email),

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email cannot be empty";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: obscurePassword,

                              decoration: AppTheme.inputDecoration(
                                  "Password", Icons.lock)
                                  .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password cannot be empty";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 25),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: AppTheme.primaryButtonStyle,
                                onPressed: loginAdmin,
                                child: const Text("Login"),
                              ),
                            ),

                            const SizedBox(height: 10),

                            TextButton(
                              onPressed: forgotPassword,
                              child: const Text("Forgot Password?"),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
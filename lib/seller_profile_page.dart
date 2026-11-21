import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'login_page.dart';

class SellerProfilePage extends StatefulWidget {
  final String cnic;
  const SellerProfilePage({super.key, required this.cnic});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dairyNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _milkTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime? _selectedDate;

  bool isLoading = true;
  bool isSaving = false;
  String? docId;
  List<Map<String, dynamic>> ridersList = [];

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('owner')
          .where('cnic', isEqualTo: widget.cnic)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        docId = doc.id;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _dairyNameController.text = data['dairyName']?.toString() ?? '';
          _nameController.text = data['ownerName']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _areaController.text = data['area']?.toString() ?? '';

          // Load Milk Rate Data
          _milkTypeController.text = data['milkType']?.toString() ?? '';
          _priceController.text = data['pricePerLiter']?.toString() ?? '';

          if (data['effectiveDate'] != null) {
            Timestamp ts = data['effectiveDate'];
            _selectedDate = ts.toDate();
          }

          if (data['ridersList'] != null) {
            ridersList = List<Map<String, dynamic>>.from(data['ridersList']);
          } else {
            ridersList = [];
          }

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller data not found')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (docId == null) return;

    setState(() => isSaving = true);

    try {
      Map<String, dynamic> updateData = {
        'dairyName': _dairyNameController.text.trim(),
        'ownerName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'area': _areaController.text.trim(),
        'ridersList': ridersList,
        'riders': ridersList.length,
        'milkType': _milkTypeController.text.trim(),
        'pricePerLiter': double.tryParse(_priceController.text.trim()) ?? 0.0,
      };

      if (_selectedDate != null) {
        updateData['effectiveDate'] = Timestamp.fromDate(_selectedDate!);
      }

      await FirebaseFirestore.instance
          .collection('owner')
          .doc(docId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showRiderDialog({int? index}) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    if (index != null) {
      nameController.text = ridersList[index]['name'];
      phoneController.text = ridersList[index]['phone'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add Rider' : 'Edit Rider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Rider Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                setState(() {
                  final riderData = {
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                  };

                  if (index == null) {
                    ridersList.add(riderData);
                  } else {
                    ridersList[index] = riderData;
                  }
                });
                Navigator.pop(context);
                // Auto-save after modifying riders
                _updateProfile();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteRider(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rider'),
        content: const Text('Are you sure you want to delete this rider?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                ridersList.removeAt(index);
              });
              Navigator.pop(context);
              _updateProfile();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage(
                              'assets/images/logo.jpg',
                            ),
                            child: null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Profile picture update disabled",
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dairy Information",
                              style: AppTheme.heading2.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _dairyNameController,
                              decoration: AppTheme.inputDecoration(
                                'Dairy Name',
                                Icons.store,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter dairy name' : null,
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _nameController,
                              decoration: AppTheme.inputDecoration(
                                'Owner Name',
                                Icons.person,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter owner name' : null,
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: AppTheme.inputDecoration(
                                'Phone Number',
                                Icons.phone,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter phone number' : null,
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _areaController,
                              decoration: AppTheme.inputDecoration(
                                'Area / City',
                                Icons.location_on,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Enter area' : null,
                            ),

                            const SizedBox(height: 30),
                            const Divider(),
                            const SizedBox(height: 20),

                            Text(
                              "Milk Rate Information",
                              style: AppTheme.heading2.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _milkTypeController,
                              decoration: AppTheme.inputDecoration(
                                'Milk Type (e.g. Cow, Buffalo)',
                                Icons.water_drop,
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: AppTheme.inputDecoration(
                                'Price per Liter (Rs)',
                                Icons.attach_money,
                              ),
                            ),
                            const SizedBox(height: 20),

                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate == null
                                          ? 'Select Effective Date'
                                          : 'Effective Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedDate == null
                                            ? Colors.grey[600]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: isSaving
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ElevatedButton(
                                      onPressed: _updateProfile,
                                      style: AppTheme.primaryButtonStyle,
                                      child: const Text(
                                        'Update Profile',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Riders Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Registered Riders",
                                style: AppTheme.heading2.copyWith(fontSize: 20),
                              ),
                              IconButton(
                                onPressed: () => _showRiderDialog(),
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: AppTheme.primaryColor,
                                ),
                                tooltip: 'Add Rider',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (ridersList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text("No riders registered yet."),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ridersList.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final rider = ridersList[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppTheme.secondaryColor,
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(rider['name'] ?? 'Unknown'),
                                  subtitle: Text(rider['phone'] ?? 'No Phone'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _showRiderDialog(index: index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteRider(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

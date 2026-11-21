import 'dart:io'; // ✅ Needed for File
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ Needed for Firebase Storage
import 'app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DairyFormPage extends StatefulWidget {
  const DairyFormPage({super.key});

  @override
  State<DairyFormPage> createState() => _DairyFormPageState();
}

class _DairyFormPageState extends State<DairyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dairyNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _ownerPhoneCtrl = TextEditingController();
  final TextEditingController _cnicCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _milkTypeCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _availableMilkCtrl = TextEditingController();
  DateTime _effectiveDate = DateTime.now();

  final List<Map<String, String>> _riders = [];
  String? _certificatePath;
  String? _certificateUrl; // ✅ To save URL after upload

  @override
  void dispose() {
    _dairyNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _cnicCtrl.dispose();
    _areaCtrl.dispose();
    _milkTypeCtrl.dispose();
    _priceCtrl.dispose();
    _availableMilkCtrl.dispose();
    super.dispose();
  }

  // ---------------- PICK CERTIFICATE ----------------
  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _certificatePath = result.files.single.path;
      });
    }
  }

  // ---------------- ADD RIDER ----------------
  void _addRiderDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Rider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: AppTheme.inputDecoration('Rider Name', Icons.person),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: AppTheme.inputDecoration('Phone Number', Icons.phone),
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
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provide name and phone')),
                );
                return;
              }
              setState(() {
                _riders.add({'name': name, 'phone': phone});
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeRider(int index) {
    setState(() {
      _riders.removeAt(index);
    });
  }

  String? _cnicValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final digitsOnly = value.replaceAll('-', '').trim();
    if (digitsOnly.length != 13) return 'CNIC should be 13 digits';
    if (!RegExp(r'^\d{13}$').hasMatch(digitsOnly)) return 'Enter only digits';
    return null;
  }

  // // ---------------- SUBMIT FORM ----------------
  // void _submitForm() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   if (_riders.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Add at least one rider')),
  //     );
  //     return;
  //   }
  //
  //   // ---------------- UPLOAD CERTIFICATE ----------------
  //   String? certificateUrl;
  //   if (_certificatePath != null) {
  //     try {
  //       final file = File(_certificatePath!);
  //
  //       if (!await file.exists()) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Selected file not found')),
  //         );
  //         return;
  //       }
  //
  //       final fileName = _certificatePath!.split('/').last;
  //       final storageRef = FirebaseStorage.instance.ref('certificates/$fileName');
  //
  //       // Use putData for safer upload
  //       final uploadTask = storageRef.putData(await file.readAsBytes());
  //
  //       final snapshot = await uploadTask.whenComplete(() {});
  //       certificateUrl = await snapshot.ref.getDownloadURL();
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Upload failed: $e')),
  //       );
  //       return;
  //     }
  //   }
  //
  //
  //
  //   final dairyData = {
  //     'dairyName': _dairyNameCtrl.text.trim(),
  //     'ownerName': _ownerNameCtrl.text.trim(),
  //     'phone': _ownerPhoneCtrl.text.trim(),
  //     'cnic': _cnicCtrl.text.trim(),
  //     'area': _areaCtrl.text.trim(),
  //     'milkType': _milkTypeCtrl.text.trim(),
  //     'pricePerLiter': double.tryParse(_priceCtrl.text) ?? 0,
  //     'availableMilk': double.tryParse(_availableMilkCtrl.text) ?? 0,
  //     'effectiveDate': Timestamp.fromDate(_effectiveDate),
  //     'riders': _riders.length,
  //     'ridersList': _riders,
  //     'certificateUrl': _certificateUrl, // ✅ Save URL instead of path
  //     'ownerId': FirebaseAuth.instance.currentUser?.uid,
  //     'createdAt': FieldValue.serverTimestamp(),
  //   };
  //
  //   try {
  //     await FirebaseFirestore.instance.collection('owner').add(dairyData);
  //
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Dairy listed successfully!')),
  //     );
  //
  //     // Clear form
  //     _dairyNameCtrl.clear();
  //     _ownerNameCtrl.clear();
  //     _ownerPhoneCtrl.clear();
  //     _cnicCtrl.clear();
  //     _areaCtrl.clear();
  //     _milkTypeCtrl.clear();
  //     _priceCtrl.clear();
  //     _availableMilkCtrl.clear();
  //     setState(() {
  //       _riders.clear();
  //       _certificatePath = null;
  //       _certificateUrl = null;
  //       _effectiveDate = DateTime.now();
  //     });
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error: $e')));
  //   }
  // }
  // Future<String?> uploadToCloudinary(File file) async {
  //   const cloudName = "dl8nisfav";
  //   const uploadPreset = "SmartMilkman";
  //
  //   final url = Uri.parse(
  //       "https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
  //
  //   var request = http.MultipartRequest('POST', url);
  //
  //   request.fields['upload_preset'] = uploadPreset;
  //
  //   request.files.add(
  //     await http.MultipartFile.fromPath('file', file.path),
  //   );
  //
  //   var response = await request.send();
  //
  //   if (response.statusCode == 200) {
  //     final responseData = await response.stream.bytesToString();
  //     final jsonData = json.decode(responseData);
  //
  //     return jsonData['secure_url']; // ✅ This is PDF URL
  //   } else {
  //     return null;
  //   }
  // }
  Future<String?> uploadToCloudinary(File file) async {
    const cloudName = 'dl8nisfav';
    const uploadPreset = 'SmartMilkman';

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/raw/upload",
    );

    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.path.split('/').last,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      // ✅ Return secure URL
      return jsonData['secure_url'];
    } else {
      print('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  // Future<String?> uploadToCloudinary(File file) async {
  //   const cloudName = "dl8nisfav";
  //   const uploadPreset = "SmartMilkman";
  //
  //   final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload"); // ✅ raw for PDFs
  //
  //   var request = http.MultipartRequest('POST', url);
  //   request.fields['upload_preset'] = uploadPreset;
  //
  //   request.files.add(
  //     await http.MultipartFile.fromPath('file', file.path),
  //   );
  //
  //   var response = await request.send();
  //
  //   if (response.statusCode == 200) {
  //     final responseData = await response.stream.bytesToString();
  //     final jsonData = json.decode(responseData);
  //     return jsonData['secure_url']; // ✅ Use this URL in Firestore
  //   } else {
  //     print('Upload failed: ${response.statusCode}');
  //     return null;
  //   }
  // }
  // void _submitForm() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   if (_riders.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Add at least one rider')),
  //     );
  //     return;
  //   }
  //
  //   if (_certificatePath == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please upload certificate')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final file = File(_certificatePath!);
  //
  //     if (!await file.exists()) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Selected file not found')),
  //       );
  //       return;
  //     }
  //
  //     // 🔥 Convert file to Base64
  //     final bytes = await file.readAsBytes();
  //
  //     // ⚠️ Check size (Firestore limit safety)
  //     if (bytes.length > 900000) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //             content: Text('File too large! Please upload smaller file (<1MB)')),
  //       );
  //       return;
  //     }
  //
  //     final base64File = base64Encode(bytes);
  //
  //     final dairyData = {
  //       'dairyName': _dairyNameCtrl.text.trim(),
  //       'ownerName': _ownerNameCtrl.text.trim(),
  //       'phone': _ownerPhoneCtrl.text.trim(),
  //       'cnic': _cnicCtrl.text.trim(),
  //       'area': _areaCtrl.text.trim(),
  //       'milkType': _milkTypeCtrl.text.trim(),
  //       'pricePerLiter': double.tryParse(_priceCtrl.text) ?? 0,
  //       'availableMilk': double.tryParse(_availableMilkCtrl.text) ?? 0,
  //       'effectiveDate': Timestamp.fromDate(_effectiveDate),
  //       'riders': _riders.length,
  //       'ridersList': _riders,
  //       'certificateBase64': base64File, // ✅ STORED HERE
  //       'ownerId': FirebaseAuth.instance.currentUser?.uid ?? "guest",
  //       'createdAt': FieldValue.serverTimestamp(),
  //     };
  //
  //     await FirebaseFirestore.instance.collection('owner').add(dairyData);
  //
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Dairy listed successfully!')),
  //     );
  //
  //     // Clear form
  //     _dairyNameCtrl.clear();
  //     _ownerNameCtrl.clear();
  //     _ownerPhoneCtrl.clear();
  //     _cnicCtrl.clear();
  //     _areaCtrl.clear();
  //     _milkTypeCtrl.clear();
  //     _priceCtrl.clear();
  //     _availableMilkCtrl.clear();
  //
  //     setState(() {
  //       _riders.clear();
  //       _certificatePath = null;
  //       _effectiveDate = DateTime.now();
  //     });
  //
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_riders.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one rider')));
      return;
    }

    if (_certificatePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload certificate')),
      );
      return;
    }

    try {
      final file = File(_certificatePath!);

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file not found')),
        );
        return;
      }

      // Upload to Cloudinary
      String? certificateUrl = await uploadToCloudinary(file);

      if (certificateUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate upload failed')),
        );
        return;
      }

      // Store data in Firestore
      final dairyData = {
        'dairyName': _dairyNameCtrl.text.trim(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'phone': _ownerPhoneCtrl.text.trim(),
        'cnic': _cnicCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'milkType': _milkTypeCtrl.text.trim(),
        'pricePerLiter': double.tryParse(_priceCtrl.text) ?? 0,
        'availableMilk': double.tryParse(_availableMilkCtrl.text) ?? 0,
        'effectiveDate': Timestamp.fromDate(_effectiveDate),
        'riders': _riders.length,
        'ridersList': _riders,
        'certificateUrl': certificateUrl, // Cloudinary URL
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('owner').add(dairyData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dairy listed successfully!')),
      );

      // Clear form
      _dairyNameCtrl.clear();
      _ownerNameCtrl.clear();
      _ownerPhoneCtrl.clear();
      _cnicCtrl.clear();
      _areaCtrl.clear();
      _milkTypeCtrl.clear();
      _priceCtrl.clear();
      _availableMilkCtrl.clear();
      setState(() {
        _riders.clear();
        _certificatePath = null;
        _effectiveDate = DateTime.now();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickEffectiveDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _effectiveDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ------------------- UI REMAINS EXACTLY SAME -------------------
    return Scaffold(
      appBar: AppBar(title: const Text('List Your Dairy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Dairy Information"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _dairyNameCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Dairy Name',
                            Icons.store,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _areaCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Delivery Area',
                            Icons.map,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("Owner Details"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _ownerNameCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Owner Name',
                            Icons.person,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ownerPhoneCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Owner Phone',
                            Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cnicCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Owner CNIC (13 digits)',
                            Icons.credit_card,
                          ),
                          keyboardType: TextInputType.number,
                          validator: _cnicValidator,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("Milk Details"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _milkTypeCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Milk Type',
                            Icons.local_drink,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Price per Liter',
                            Icons.money,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _availableMilkCtrl,
                          decoration: AppTheme.inputDecoration(
                            'Initial Milk Stock (Liters)',
                            Icons.inventory,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          title: Text(
                            'Effective Date: ${_effectiveDate.toLocal()}'.split(
                              ' ',
                            )[0],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickEffectiveDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("Riders"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_riders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No riders added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _riders.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final r = _riders[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.secondaryColor,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  r['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(r['phone'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppTheme.errorColor,
                                  ),
                                  onPressed: () => _removeRider(index),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _addRiderDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Rider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("Documents"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _pickCertificate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _certificatePath != null
                                ? _certificatePath!.split('/').last
                                : 'Upload Certificate',
                            style: TextStyle(
                              color: _certificatePath != null
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Submit Application',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title, style: AppTheme.heading2.copyWith(fontSize: 18)),
    );
  }
}

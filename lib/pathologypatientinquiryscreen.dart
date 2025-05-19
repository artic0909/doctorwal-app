import 'dart:convert';

import 'package:demoapp/Models/all_available_opd_model.dart';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PathologyPatientInquiryScreen extends StatefulWidget {
  final AllAvailablePathModel pathology;
  final dynamic userData;

  const PathologyPatientInquiryScreen({
    super.key,
    required this.pathology,
    required this.userData,
  });

  @override
  State<PathologyPatientInquiryScreen> createState() => _PathologyPatientInquiryScreenState();
}

class _PathologyPatientInquiryScreenState extends State<PathologyPatientInquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _partnerIdController = TextEditingController();
  final TextEditingController _enquiryAboutController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _inquiryOPD = false;
  bool _inquiryPath = false;
  bool _inquiryDoctor = false;

  @override
  void initState() {
    super.initState();

    _partnerIdController.text =
        widget.pathology.currentlyLoggedInPartnerId ?? '';
    _enquiryAboutController.text = widget.pathology.clinicName ?? '';

    _nameController.text = widget.userData['name'] ?? '';
    _cityController.text = widget.userData['city'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    _phoneController.text = widget.userData['mobile'] ?? '';

    // ✅ Automatically pre-select Path as the inquiry type
    _inquiryPath = true;
  }

  @override
  void dispose() {
    _partnerIdController.dispose();
    _enquiryAboutController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'Enquiry Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[900],
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Fill this form to get best deals",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                "Partner ID",
                _partnerIdController,
                readOnly: true,
              ),
              _buildTextField(
                "Enquiry About",
                _enquiryAboutController,
                readOnly: true,
              ),
              _buildTextField("Name", _nameController, readOnly: true),
              _buildTextField("City", _cityController, readOnly: true),
              _buildTextField(
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              _buildTextField(
                "Phone No",
                _phoneController,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Inquiry Type:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  FilterChip(
                    label: const Text("OPD"),
                    selected: _inquiryOPD,
                    onSelected: (val) => setState(() => _inquiryOPD = val),
                  ),
                  FilterChip(
                    label: const Text("Path"),
                    selected: _inquiryPath,
                    onSelected: (val) => setState(() => _inquiryPath = val),
                  ),
                  FilterChip(
                    label: const Text("Doctor"),
                    selected: _inquiryDoctor,
                    onSelected: (val) => setState(() => _inquiryDoctor = val),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                "Inquiry Message",
                _messageController,
                maxLines: 3,
                readOnly: false,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "CONFIRM",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: (value) {
          if (readOnly) return null; // skip validation for readonly fields
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_inquiryOPD && !_inquiryPath && !_inquiryDoctor) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one inquiry type."),
          ),
        );
        return;
      }

      // Debug print all form data to console:
      print('partnerId: ${_partnerIdController.text}');
      print('enquiryAbout: ${_enquiryAboutController.text}');
      print('name: ${_nameController.text}');
      print('city: ${_cityController.text}');
      print('email: ${_emailController.text}');
      print('phone: ${_phoneController.text}');
      print('message: ${_messageController.text}');
      print(
        'Inquiry Types: OPD=$_inquiryOPD, Path=$_inquiryPath, Doctor=$_inquiryDoctor',
      );

      final inquiryType =
          _inquiryOPD
              ? 'OPD'
              : _inquiryPath
              ? 'Path'
              : 'Doctor'; // First selected one

      final url = Uri.parse(
        'http://10.0.2.2:8000/api/patient-inquiry',
      ); // replace with your actual API endpoint

      final body = {
        "currently_loggedin_partner_id": _partnerIdController.text,
        "clinic_type": inquiryType,
        "clinic_name": _enquiryAboutController.text,
        "user_name": _nameController.text,
        "user_city": _cityController.text,
        "user_mobile": _phoneController.text,
        "user_email": _emailController.text,
        "user_inquiry": _messageController.text,
      };

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inquiry submitted successfully!")),
          );
          Navigator.pop(context); // Close the screen or reset form
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Submission failed')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

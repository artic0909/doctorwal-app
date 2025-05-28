import 'dart:convert';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PathologyFeedbackScreen extends StatefulWidget {
  final AllAvailablePathModel pathology;
  final dynamic userData;

  const PathologyFeedbackScreen({
    super.key,
    required this.pathology,
    required this.userData,
  });

  @override
  State<PathologyFeedbackScreen> createState() =>
      _PathologyFeedbackScreenState();
}

class _PathologyFeedbackScreenState extends State<PathologyFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _partnerIdController = TextEditingController();
  final TextEditingController _enquiryAboutController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  final bool _inquiryOPD = false;
  bool _inquiryPath = false;
  final bool _inquiryDoctor = false;

  int _rating = 0;

  @override
  void initState() {
    super.initState();

    _partnerIdController.text =
        widget.pathology.currentlyLoggedInPartnerId ?? '';
    _enquiryAboutController.text = widget.pathology.clinicName ?? '';
    _nameController.text = widget.userData['name'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';

    // Pre-select Path as the inquiry type
    _inquiryPath = true;
  }

  @override
  void dispose() {
    _partnerIdController.dispose();
    _enquiryAboutController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
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
              'Feedback',
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
                "Please fill the following details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                "Feedback About",
                _enquiryAboutController,
                readOnly: true,
              ),
              _buildTextField("Name", _nameController, readOnly: true),
              _buildTextField(
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              // const SizedBox(height: 20),

              // const Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text(
              //     "Feedback Type:",
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Wrap(
              //   spacing: 10,
              //   children: [
              //     FilterChip(
              //       label: const Text("OPD"),
              //       selected: _inquiryOPD,
              //       onSelected:
              //           (val) => setState(() {
              //             _inquiryOPD = val;
              //             _inquiryPath = false;
              //             _inquiryDoctor = false;
              //           }),
              //     ),
              //     FilterChip(
              //       label: const Text("Path"),
              //       selected: _inquiryPath,
              //       onSelected:
              //           (val) => setState(() {
              //             _inquiryPath = val;
              //             _inquiryOPD = false;
              //             _inquiryDoctor = false;
              //           }),
              //     ),
              //     FilterChip(
              //       label: const Text("Doctor"),
              //       selected: _inquiryDoctor,
              //       onSelected:
              //           (val) => setState(() {
              //             _inquiryDoctor = val;
              //             _inquiryOPD = false;
              //             _inquiryPath = false;
              //           }),
              //     ),
              //   ],
              // ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Rate our service:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: index < _rating ? Colors.orange : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 20),
              _buildTextField(
                "Give your feedback",
                _feedbackController,
                maxLines: 3,
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
          if (readOnly) return null;
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
            content: Text("Please select at least one feedback type."),
          ),
        );
        return;
      }

      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please provide a rating before submitting."),
          ),
        );
        return;
      }

      final inquiryType =
          _inquiryOPD
              ? 'OPD'
              : _inquiryPath
              ? 'Path'
              : 'Doctor';

      final url = Uri.parse('https://doctorwala.info/api/patient-feedback');

      final body = {
        "currently_loggedin_partner_id": _partnerIdController.text,
        "clinic_type": inquiryType,
        "clinic_name": _enquiryAboutController.text,
        "user_name": _nameController.text,
        "user_email": _emailController.text,
        "feedback": _feedbackController.text,
        "rating": _rating.toString(),
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
            const SnackBar(content: Text("Thanks for your valuable feedback!")),
          );
          Navigator.pop(context);
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

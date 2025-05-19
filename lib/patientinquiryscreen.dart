import 'package:flutter/material.dart';

class PatientInquiryScreen extends StatefulWidget {
  const PatientInquiryScreen({super.key});

  @override
  State<PatientInquiryScreen> createState() => _PatientInquiryScreenState();
}

class _PatientInquiryScreenState extends State<PatientInquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _partnerIdController = TextEditingController();
  final TextEditingController _enquiryAboutController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(
    text: "test saklin",
  );
  final TextEditingController _cityController = TextEditingController(
    text: "haldia",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "ts@gmail.com",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "6123456890",
  );
  final TextEditingController _messageController = TextEditingController();

  bool _inquiryOPD = false;
  bool _inquiryPath = false;
  bool _inquiryDoctor = false;

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

              // Input Fields
              _buildTextField("Partner ID", _partnerIdController),
              _buildTextField("Enquiry About", _enquiryAboutController),
              _buildTextField("Name", _nameController),
              _buildTextField("City", _cityController),
              _buildTextField(
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                "Phone No",
                _phoneController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // Inquiry Type Chips
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
              ),

              const SizedBox(height: 30),

              // Confirm Button
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator:
            (value) =>
                value == null || value.isEmpty ? 'Please enter $label' : null,
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

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (!_inquiryOPD && !_inquiryPath && !_inquiryDoctor) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one inquiry type."),
          ),
        );
        return;
      }

      final inquiryTypes = [];
      if (_inquiryOPD) inquiryTypes.add("OPD");
      if (_inquiryPath) inquiryTypes.add("Path");
      if (_inquiryDoctor) inquiryTypes.add("Doctor");

      print("Partner ID: ${_partnerIdController.text}");
      print("Name: ${_nameController.text}");
      print("City: ${_cityController.text}");
      print("Email: ${_emailController.text}");
      print("Phone: ${_phoneController.text}");
      print("Message: ${_messageController.text}");
      print("Enquiry About: ${_enquiryAboutController.text}");
      print("Inquiry Types: $inquiryTypes");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Inquiry submitted!")));

      // You can now send this data to your API using http.post or Dio
    }
  }
}

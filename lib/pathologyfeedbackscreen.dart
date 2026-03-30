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

  int _rating = 0;

  @override
  void initState() {
    super.initState();

    _partnerIdController.text =
        widget.pathology.currentlyLoggedInPartnerId ?? '';
    _enquiryAboutController.text = widget.pathology.clinicName ?? '';
    _nameController.text = widget.userData['name'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
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
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionHeader("Service Information"),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Rate Your Experience"),
                    const SizedBox(height: 16),
                    _buildRatingSelector(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Share Your Feedback"),
                    const SizedBox(height: 16),
                    _buildFeedbackField(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.blue[900],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "Feedback",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[900]!, Colors.blue[700]!],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.science_rounded, "Lab Name", _enquiryAboutController.text),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildInfoRow(Icons.person_rounded, "Patient Name", _nameController.text),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildInfoRow(Icons.alternate_email_rounded, "Email Address", _emailController.text),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue[800], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              bool isSelected = index < _rating;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isSelected ? Colors.amber : Colors.grey[300],
                        size: 40,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _getRatingText(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getRatingColor(),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1: return "Poor";
      case 2: return "Fair";
      case 3: return "Good";
      case 4: return "Very Good";
      case 5: return "Excellent!";
      default: return "Select Rating";
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.blue;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildFeedbackField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: _feedbackController,
        maxLines: 5,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2D2D2D)),
        decoration: InputDecoration(
          hintText: "Tell us about your experience...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your feedback';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[700]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "SUBMIT FEEDBACK",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please provide a rating before submitting."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      final url = Uri.parse('https://doctorwala.info/api/patient-feedback');
      final body = {
        "currently_loggedin_partner_id": _partnerIdController.text,
        "clinic_type": "Path",
        "clinic_name": _enquiryAboutController.text,
        "user_name": _nameController.text,
        "user_email": _emailController.text,
        "feedback": _feedbackController.text,
        "rating": _rating.toString(),
      };

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: CircularProgressIndicator(color: Colors.blue[900]),
          ),
        ),
      );

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        Navigator.pop(context); // Close loading dialog

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Thanks for your valuable feedback!"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Submission failed'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

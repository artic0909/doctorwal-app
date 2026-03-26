import 'package:demoapp/Services/apiservice.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;

  const ChangePasswordScreen({super.key, required this.email});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.updatePassword(
        currentPassword: _currentPasswordController.text,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Update failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Update Credentials",
          style: TextStyle(color: Color(0xFF263238), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Security Settings",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Update your password to keep your medical data secure.",
                    style: TextStyle(color: Color(0xFF546E7A), fontSize: 14),
                  ),
                  const SizedBox(height: 35),
                  
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: "Current Password",
                    isVisible: _isCurrentPasswordVisible,
                    toggleVisible: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                    validator: (v) => v!.isEmpty ? "Current password is required" : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: "New Security Password",
                    isVisible: _isNewPasswordVisible,
                    toggleVisible: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                    validator: (v) => v!.length < 8 ? "Password must be at least 8 characters" : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: "Confirm New Password",
                    isVisible: _isConfirmPasswordVisible,
                    toggleVisible: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    validator: (v) => v != _newPasswordController.text ? "Passwords do not match" : null,
                  ),
                  
                  const SizedBox(height: 45),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      shadowColor: const Color(0xFFE53935).withAlpha(102),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "UPDATE SECURITY ACCESS",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisible,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF263238)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1565C0), size: 20),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.blueGrey[200], size: 20),
            onPressed: toggleVisible,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

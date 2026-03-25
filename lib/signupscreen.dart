import 'package:demoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:lottie/lottie.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('https://doctorwala.info/api/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_name': nameController.text.trim(),
          'user_email': emailController.text.trim(),
          'user_password': passwordController.text.trim(),
          'user_password_confirmation': confirmPasswordController.text.trim(),
          'user_mobile': phoneController.text.trim(),
          'user_city': cityController.text.trim(),
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(76)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(64),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/animations/success.json',
                            repeat: false,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Registration Successful!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black26),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pop(); // close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen(showSuccessMessage: true)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['message'] ?? 'Registration failed'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Realistic Medical Environmental Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg1.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
                color: Color(0xFFF0F4F8),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // 2. Ecosystem Branding Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/logo.png', height: 35),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DOCTORWALA",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE53935),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "Create Medical Card",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // 3. Unique Ecosystem Form Container
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Form Card Body
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 85),
                        padding: const EdgeInsets.fromLTRB(25, 85, 25, 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withAlpha(20),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              buildElegantInput(
                                controller: nameController,
                                label: "Legal Full Name",
                                icon: Icons.person_add_alt_1_rounded,
                                validator: (value) => value!.isEmpty ? "Required" : null,
                              ),
                              const SizedBox(height: 12),
                              buildElegantInput(
                                controller: phoneController,
                                label: "Mobile Contact",
                                icon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) => (value!.length != 10) ? "10 digits required" : null,
                              ),
                              const SizedBox(height: 12),
                              buildElegantInput(
                                controller: cityController,
                                label: "Primary City",
                                icon: Icons.map_rounded,
                                validator: (value) => value!.isEmpty ? "Required" : null,
                              ),
                              const SizedBox(height: 12),
                              buildElegantInput(
                                controller: emailController,
                                label: "Email Address",
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value!) ? "Invalid email" : null,
                              ),
                              const SizedBox(height: 12),
                              buildElegantInput(
                                controller: passwordController,
                                label: "Create Access Key",
                                icon: Icons.password_rounded,
                                obscure: _obscurePassword,
                                toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                validator: (value) => value!.length < 8 ? "Min 8 chars" : null,
                              ),
                              const SizedBox(height: 12),
                              buildElegantInput(
                                controller: confirmPasswordController,
                                label: "Verify Access Key",
                                icon: Icons.verified_user_rounded,
                                obscure: _obscureConfirmPassword,
                                toggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                validator: (value) => value != passwordController.text ? "Mismatch" : null,
                              ),
                              const SizedBox(height: 25),
                              _isLoading
                                  ? const CircularProgressIndicator(color: Color(0xFF1565C0))
                                  : ElevatedButton(
                                      onPressed: registerUser,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1565C0),
                                        minimumSize: const Size(double.infinity, 60),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        elevation: 8,
                                        shadowColor: const Color(0xFF1565C0).withAlpha(128),
                                      ),
                                      child: const Text(
                                        "CREATE ECOSYSTEM ACCOUNT",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Royal Blue Medical Card Element (Header)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.78,
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset('assets/images/logo.png', height: 25, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "SECURE REGISTRATION CARD",
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.security_rounded, color: Colors.white70, size: 14),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                "YOUR MEDICAL CARD",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("CARD HOLDER", style: TextStyle(color: Colors.white70, fontSize: 8)),
                                      Text("NEW MEMBER", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("VERIFIED BY", style: TextStyle(color: Colors.white70, fontSize: 8)),
                                      Text("DOCTORWALA", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Bottom Support
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have access? ",
                        style: TextStyle(color: Colors.blueGrey[400], fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text(
                          "Login Now",
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildElegantInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggle,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8).withAlpha(128),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueGrey.withAlpha(51), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 18),
          suffixIcon: toggle != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.blueGrey[200], size: 18),
                  onPressed: toggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }
}

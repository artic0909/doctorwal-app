import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:demoapp/main.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isOTPSent = false;
  bool isOTPVerified = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  int remainingSeconds = 180;
  Timer? countdownTimer;

  final String baseUrl = 'https://doctorwala.info';

  void startCountdown() {
    countdownTimer?.cancel();
    setState(() => remainingSeconds = 180);
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/send-otp'),
        headers: {'Accept': 'application/json'},
        body: {'user_email': email},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        setState(() => isOTPSent = true);
        startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Something went wrong.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> verifyCode() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify-otp'),
        headers: {'Accept': 'application/json'},
        body: {'user_email': email, 'otp': otp},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        setState(() => isOTPVerified = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "OTP verification failed.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> updatePassword() async {
    final email = emailController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update-password-during-otp'),
        headers: {'Accept': 'application/json'},
        body: {
          'user_email': email,
          'user_password': newPassword,
          'user_password_confirmation': confirmPassword,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Password updated")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Password update failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildPhaseIndicator(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: _buildCurrentPhase(),
                  ),
                ],
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
          "Forget Password",
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

  Widget _buildPhaseIndicator() {
    int currentPhase = isOTPVerified ? 2 : (isOTPSent ? 1 : 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index <= currentPhase;
        return Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue[800] : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: index < currentPhase
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: index < currentPhase ? Colors.blue[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentPhase() {
    if (isOTPVerified) {
      return _buildResetPasswordPhase();
    } else if (isOTPSent) {
      return _buildVerifyOTPPhase();
    } else {
      return _buildEmailIdentificationPhase();
    }
  }

  Widget _buildEmailIdentificationPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.alternate_email_rounded, size: 60, color: Colors.blue[800]),
        ),
        const SizedBox(height: 30),
        const Text(
          "No worries!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 12),
        Text(
          "Enter your registered email to receive\nan OTP for password reset.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildTextFieldWithIcon(
          controller: emailController,
          label: "Email Address",
          hint: "user@example.com",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 40),
        _buildActionButton(
          label: "SEND RESET CODE",
          onPressed: sendCode,
          gradientColors: [Colors.blue[900]!, Colors.blue[700]!],
        ),
      ],
    );
  }

  Widget _buildVerifyOTPPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shield_outlined, size: 60, color: Colors.orange[800]),
        ),
        const SizedBox(height: 30),
        const Text(
          "Verification",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a 4-digit code to\n${emailController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildOTPInputWidget(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: Colors.red[700]),
            const SizedBox(width: 6),
            Text(
              'Expires in: ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildActionButton(
          label: "VERIFY CODE",
          onPressed: verifyCode,
          gradientColors: [Colors.orange[900]!, Colors.orange[700]!],
        ),
        TextButton(
          onPressed: remainingSeconds == 0 ? sendCode : null,
          child: Text(
            "Resend Code",
            style: TextStyle(
              color: remainingSeconds == 0 ? Colors.blue[800] : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset_rounded, size: 60, color: Colors.green[800]),
        ),
        const SizedBox(height: 30),
        const Text(
          "Secure Account",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 12),
        Text(
          "Create a strong new password to\nsecure your account.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildPasswordField(
          controller: newPasswordController,
          label: "New Password",
          visible: passwordVisible,
          onToggle: () => setState(() => passwordVisible = !passwordVisible),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: confirmPasswordController,
          label: "Confirm Password",
          visible: confirmPasswordVisible,
          onToggle: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
        ),
        const SizedBox(height: 40),
        _buildActionButton(
          label: "UPDATE PASSWORD",
          onPressed: updatePassword,
          gradientColors: [Colors.green[800]!, Colors.green[600]!],
        ),
      ],
    );
  }

  Widget _buildOTPInputWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: otpController.text.length > index ? Colors.blue[800]! : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: TextField(
              autofocus: index == 0,
              onChanged: (value) {
                if (value.isNotEmpty && index < 3) {
                  FocusScope.of(context).nextFocus();
                } else if (value.isEmpty && index > 0) {
                  FocusScope.of(context).previousFocus();
                }
                
                // Construct the full OTP
                String currentOtp = otpController.text;
                if (value.isNotEmpty) {
                  if (currentOtp.length > index) {
                    currentOtp = currentOtp.replaceRange(index, index + 1, value);
                  } else {
                    currentOtp += value;
                  }
                } else {
                  if (currentOtp.length > index) {
                    currentOtp = currentOtp.substring(0, index);
                  }
                }
                otpController.text = currentOtp;
                setState(() {});
              },
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue[800], size: 22),
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey[600]),
          floatingLabelStyle: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.blue[800], size: 22),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey, size: 20),
            onPressed: onToggle,
          ),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          floatingLabelStyle: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: gradientColors),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}

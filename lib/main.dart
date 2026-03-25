import 'dart:convert';
import 'package:demoapp/categoryscreen.dart';
import 'package:demoapp/forgetpasswordscreen.dart';
import 'package:demoapp/signupscreen.dart';
import 'package:demoapp/spalashscreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool showSuccessMessage;
  const LoginScreen({super.key, this.showSuccessMessage = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  Map<String, dynamic>? _loggedUserData;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    if (widget.showSuccessMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful!")),
        );
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final mobile = prefs.getString('mobile');
    final city = prefs.getString('city');

    if (token != null && name != null && email != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => CategoryHomeScreen(
                userData: {
                  'token': token,
                  'name': name,
                  'email': email,
                  'mobile': mobile ?? '',
                  'city': city ?? '',
                },
              ),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> loginUser(
    String identifier,
    String password,
  ) async {
    final url = Uri.parse('https://doctorwala.info/api/login');
    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_identifier': identifier, 'user_password': password}),
      );

      setState(() => _isLoading = false);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data.containsKey('token')) {
        return {
          'token': data['token'],
          'name': data['user']['name'],
          'email': data['user']['email'],
          'mobile': data['user']['mobile'] ?? '',
          'city': data['user']['city'] ?? '',
        };
      } else {
        _showErrorDialog(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error: $e');
    }

    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessPopup() {
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
                        onLoaded: (composition) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            'token',
                            _loggedUserData!['token'],
                          );
                          await prefs.setString(
                            'name',
                            _loggedUserData!['name'],
                          );
                          await prefs.setString(
                            'email',
                            _loggedUserData!['email'],
                          );
                          await prefs.setString(
                            'mobile',
                            _loggedUserData!['mobile'],
                          );
                          await prefs.setString(
                            'city',
                            _loggedUserData!['city'],
                          );

                          Future.delayed(const Duration(seconds: 1), () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CategoryHomeScreen(
                                      userData: _loggedUserData!,
                                    ),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Login Successful!",
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
                  Column(
                    children: [
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
                            child: Image.asset('assets/images/logo.png', height: 40),
                          ),
                          const SizedBox(width: 15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DOCTORWALA",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE53935),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                "Medical Ecosystem",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1565C0),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your Health. Your Records. Your Lifeline.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF546E7A),
                        ),
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
                        padding: const EdgeInsets.fromLTRB(28, 85, 28, 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withAlpha(25),
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
                                controller: emailController,
                                label: "Email or Mobile ID",
                                icon: Icons.person_outline_rounded,
                                validator: (value) => value!.isEmpty ? 'Identity required' : null,
                              ),
                              const SizedBox(height: 20),
                              buildElegantInput(
                                controller: passwordController,
                                label: "Security Password",
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                validator: (value) => value!.isEmpty ? 'Password required' : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                                  ),
                                  child: const Text(
                                    "Forgot Access?",
                                    style: TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              _isLoading
                                  ? const CircularProgressIndicator(color: Color(0xFF1565C0))
                                  : ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          final userData = await loginUser(
                                            emailController.text.trim(),
                                            passwordController.text.trim(),
                                          );
                                          if (userData != null) {
                                            _loggedUserData = userData;
                                            _showSuccessPopup();
                                          }
                                        }
                                      },
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
                                        "PROCEED TO ECOSYSTEM",
                                        style: TextStyle(
                                          fontSize: 14,
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
                      
                      // Royal Blue Medical ID Card Element (Header)
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
                                    "Doctorwala MEDICAL CARD",
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.wifi_rounded, color: Colors.white70, size: 14),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                "DW01 0001 001",
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
                                      Text("YOUR IDENTITY", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("EXPIRY", style: TextStyle(color: Colors.white70, fontSize: 8)),
                                      Text("MM/YY", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 25),
                  
                  // 4. Ecosystem Service Badges
                  const Column(
                    children: [
                      Text(
                        "DISCOVER DOCTORWALA",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          EcosystemBadge(icon: Icons.personal_injury_rounded, label: "Doctors"),
                          EcosystemBadge(icon: Icons.local_hospital_rounded, label: "Clinics"),
                          EcosystemBadge(icon: Icons.science_rounded, label: "Labs"),
                          EcosystemBadge(icon: Icons.support_agent_rounded, label: "24/7"),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  
                  // Bottom Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not a member yet? ",
                        style: TextStyle(color: Colors.blueGrey[400], fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: const Text(
                          "Create Medical Card",
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
        style: const TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          suffixIcon: toggle != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.blueGrey[300]),
                  onPressed: toggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: validator,
      ),
    );
  }
}

class EcosystemBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const EcosystemBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      ],
    );
  }
}

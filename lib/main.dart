import 'dart:convert';
import 'package:demoapp/categoryscreen.dart';
import 'package:demoapp/forgetpasswordscreen.dart';
import 'package:demoapp/loginwithotpscreen.dart';
import 'package:demoapp/signupscreen.dart';
import 'package:demoapp/spalashscreen.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
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

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.orange),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      errorStyle: const TextStyle(color: Colors.white),
      counterText: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg2.jpeg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(125, 56, 56, 56).withAlpha(153),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(76),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Image.asset('assets/images/logo.png', height: 60),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Welcome to Doctorwala!',
                          textStyle: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          speed: const Duration(milliseconds: 100),
                        ),
                        TypewriterAnimatedText(
                          '+Your health partner in one click+',
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                      isRepeatingAnimation: false,
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: _buildInputDecoration("Email or Phone"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                              );
                              final phoneRegex = RegExp(r'^\d{10}$');
                              if (!emailRegex.hasMatch(value) &&
                                  !phoneRegex.hasMatch(value)) {
                                return 'Invalid email or phone';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: _buildInputDecoration(
                              "Password",
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 8) return 'Min 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
                                  backgroundColor: Colors.deepOrange,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgetPasswordScreen(),
                                ),
                              ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginWithScreen(),
                                ),
                              ),
                          child: const Text(
                            "Login with OTP",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: TextButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            ),
                        child: const Text(
                          "New User? Signup here",
                          style: TextStyle(
                            color: Colors.white,
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
        ],
      ),
    );
  }
}

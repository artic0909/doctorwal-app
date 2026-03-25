import 'package:flutter/material.dart';
import 'dart:async';
import 'package:demoapp/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/categoryscreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Controller for scaling and fading the logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Controller for the entire screen fade-in
    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _logoController.forward();
    _fadeController.forward();

    Timer(const Duration(milliseconds: 3500), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        Widget nextScreen;
        if (token != null && token.isNotEmpty) {
          final userData = {
            'token': token,
            'name': prefs.getString('name') ?? '',
            'email': prefs.getString('email') ?? '',
            'mobile': prefs.getString('mobile') ?? '',
            'city': prefs.getString('city') ?? '',
            'member_id': prefs.getString('member_id') ?? '',
            'medical_card_no': prefs.getString('medical_card_no') ?? '',
            'image': prefs.getString('image') ?? '',
          };
          nextScreen = CategoryHomeScreen(userData: userData);
        } else {
          nextScreen = const LoginScreen();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // Pure white at top
              Color(0xFFE3F2FD), // Very light blue medical look
              Color(0xFFBBDEFB), // Light blue bottom
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeController,
          child: Stack(
            children: [
              // Subtle background pattern or floating elements could go here
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with scale and fade animation
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(51),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Doctorwala Brand Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Doctor",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF35824A), // 0xFF35824A Brand Red
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          "wala",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFE53935), // Brand Blue
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    SizedBox(
                      height: 44,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF546E7A),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Your Health. Your Records. Your Lifeline.',
                              speed: const Duration(milliseconds: 80),
                            ),
                          ],
                          isRepeatingAnimation: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Footer
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      "Medical Ecosystem",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF90A4AE),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 40,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.blue.withAlpha(30),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1565C0),
                        ),
                        minHeight: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

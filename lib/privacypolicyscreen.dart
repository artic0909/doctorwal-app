import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // 0. Living Background with Animated Blobs
          _buildAnimatedBackground(),

          // 1. Static Pattern Backdrop
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/contact_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 2. Glassmorphism Header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF1565C0).withAlpha(200), const Color(0xFF0D47A1).withAlpha(220)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(height: 60),
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.security_rounded, color: Colors.white, size: 35),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Privacy Policy",
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Your security is our priority",
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Policy Content in Premium Cards
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _policySection(
                      icon: Icons.info_outline_rounded,
                      title: "Introduction",
                      content: 'DoctorWala.info ("we", "our", or "us") values your privacy. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app and services.',
                    ),
                    _policySection(
                      icon: Icons.data_usage_rounded,
                      title: "Information We Collect",
                      content: '• Personal Information (Name, Email, Phone, City)\n• Usage Data (App usage, clicks, time spent)\n• Location (only if allowed by you)',
                    ),
                    _policySection(
                      icon: Icons.settings_suggest_rounded,
                      title: "How We Use Your Information",
                      content: 'We use the collected information to:\n• Provide and improve our services\n• Customize user experience\n• Send notifications (if enabled)\n• Respond to customer queries',
                    ),
                    _policySection(
                      icon: Icons.lock_outline_rounded,
                      title: "Data Protection",
                      content: 'We implement industry-standard security measures to protect your data. However, no method of transmission over the Internet is 100% secure.',
                    ),
                    _policySection(
                      icon: Icons.share_rounded,
                      title: "Third-Party Sharing",
                      content: 'We do not sell or rent your personal information. Your data may be shared with trusted partners only to help operate our services, under strict confidentiality agreements.',
                    ),
                    _policySection(
                      icon: Icons.check_circle_outline_rounded,
                      title: "Your Choices",
                      content: 'You can:\n• Update or delete your profile\n• Opt-out of notifications\n• Contact us to remove your account',
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        '© 2026 DoctorWala.info. All rights reserved.',
                        style: TextStyle(color: Colors.blueGrey[300], fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        _animatedBlob(const Color(0xFF1565C0).withAlpha(15), 150, top: 100, left: -50),
        _animatedBlob(const Color(0xFF6A1B9A).withAlpha(12), 200, bottom: 100, right: -50),
        _animatedBlob(const Color(0xFF2E7D32).withAlpha(10), 120, top: 400, left: 200),
      ],
    );
  }

  Widget _animatedBlob(Color color, double size, {double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 4),
        builder: (context, double value, child) {
          final double moveX = ui.lerpDouble(-20, 20, math.sin(value * math.pi * 2)) ?? 0;
          final double moveY = ui.lerpDouble(-20, 20, math.cos(value * math.pi * 2)) ?? 0;

          return Transform.translate(
            offset: Offset(moveX, moveY),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 40, spreadRadius: 10),
                ],
              ),
            ),
          );
        },
        onEnd: () {},
      ),
    );
  }

  Widget _policySection({required IconData icon, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF455A64), fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

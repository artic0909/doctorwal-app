import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info.doctorwala@gmail.com',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: '+916292237205');
    try {
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching phone: $e");
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://www.doctorwala.info');
    try {
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching website: $e");
    }
  }

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
                expandedHeight: 240,
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
                              radius: 40,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 40),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "We're Here to Help",
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Reach out to us anytime",
                              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Bento Grid Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // First Row: Large Visit Card
                      Row(
                        children: [
                          _bentoCard(
                            color: const Color(0xFF1565C0),
                            height: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _bentoIcon(Icons.location_on_rounded, const Color(0xFF1565C0)),
                                const Spacer(),
                                const Text(
                                  "VISIT US",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF1565C0)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "City Office: Ranihati, Joynagar, Panchla, Howrah - 711302",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Second Row: Email and Call
                      Row(
                        children: [
                          _bentoCard(
                            color: const Color(0xFF6A1B9A),
                            height: 180,
                            onTap: _launchEmail,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _bentoIcon(Icons.alternate_email_rounded, const Color(0xFF6A1B9A)),
                                const Spacer(),
                                const Text(
                                  "EMAIL",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF6A1B9A)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "info.doctorwala\n@gmail.com",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                                ),
                              ],
                            ),
                          ),
                          _bentoCard(
                            color: const Color(0xFF2E7D32),
                            height: 180,
                            onTap: _launchPhone,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _bentoIcon(Icons.phone_iphone_rounded, const Color(0xFF2E7D32)),
                                const Spacer(),
                                const Text(
                                  "CALL",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF2E7D32)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "+91 62922\n37205",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Third Row: Website Link or Social Placeholder
                      Row(
                        children: [
                          _bentoCard(
                            color: const Color(0xFFE65100),
                            height: 100,
                            onTap: _launchWebsite,
                            child: Row(
                              children: [
                                _bentoIcon(Icons.language_rounded, const Color(0xFFE65100)),
                                const SizedBox(width: 16),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text("WEBSITE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                                    Text("www.doctorwala.info", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.open_in_new_rounded, color: Colors.black26),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Text(
                        '© 2026 DoctorWala.info. All rights reserved.',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey[300], fontWeight: FontWeight.w900, letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
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

  Widget _bentoIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _bentoCard({
    required Widget child,
    required Color color,
    double? height,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Container(
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(180),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withAlpha(20), blurRadius: 40, offset: const Offset(0, 20)),
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: color.withAlpha(30),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

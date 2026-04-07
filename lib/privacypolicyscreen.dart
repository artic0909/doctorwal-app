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
          // Living Background with Animated Blobs
          _buildAnimatedBackground(),

          // Static Pattern Backdrop
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/contact_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Glassmorphism Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1565C0).withAlpha(200),
                              const Color(0xFF0D47A1).withAlpha(220),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(height: 40),
                            Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Privacy Policy",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Effective Date: March 30, 2026",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Policy Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMetadataCard(),
                    const SizedBox(height: 20),

                    _policySection(
                      icon: Icons.info_outline_rounded,
                      title: "1. Introduction",
                      content: [
                        _paragraph(
                          "Sumatra Sales Private Limited ('Company', 'We', 'Us', 'Our') owns and operates the Doctorwala platform accessible via:",
                        ),
                        _bullet("Website: www.doctorwala.info"),
                        _bullet(
                          "Android Application: available on Google Play Store",
                        ),
                        _paragraph(
                          "This Privacy Policy governs the collection, use, storage, sharing, and protection of your personal and health data across all platforms. By using Doctorwala, you explicitly agree to these terms.",
                        ),
                        _paragraph(
                          "Complies with: IT Act 2000, DPDP Act 2023, NDHM/ABDM Guidelines, Telemedicine Practice Guidelines 2020, and Play Store Policies.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.devices_other_rounded,
                      title: "2. Scope — Website & Android",
                      content: [
                        _subHeading("2.1 Website"),
                        _bullet(
                          "Features: OPD search, Pathology search, Patient/Partner registration.",
                        ),
                        _bullet("Uses browser cookies and local storage."),
                        _bullet("SSL/TLS encrypted connection mandatory."),
                        _subHeading("2.2 Android Application"),
                        _bullet("Min Android version: 8.0 (Oreo) and above."),
                        _bullet("Data transmitted via HTTPS only."),
                        _bullet("Uses Android Keystore for secure storage."),
                      ],
                    ),

                    _policySection(
                      icon: Icons.people_outline_rounded,
                      title: "3. Who We Are — User Types",
                      content: [
                        _subHeading("3.1 Patients (B2C)"),
                        _paragraph(
                          "Individuals managing health records, finding nearby doctors/labs, and using the AI Symptom Checker.",
                        ),
                        _subHeading("3.2 Partners (B2B)"),
                        _paragraph(
                          "Healthcare providers: Clinics/OPDs, Pathology Labs, Medical Shops, and Individual Doctors.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.add_moderator_outlined,
                      title: "4. Data We Collect",
                      content: [
                        _subHeading("4.1 Personal Data"),
                        _bullet(
                          "Name, DOB, Age, Gender, Mobile (OTP verified), Email.",
                        ),
                        _bullet("Address, City, PIN, State."),
                        _subHeading("4.2 Health & Medical Data (Sensitive)"),
                        _paragraph(
                          "⚠ Classified as Sensitive Personal Data under Indian Law.",
                        ),
                        _bullet("Symptoms typed in AI Symptom Checker."),
                        _bullet(
                          "Uploaded prescriptions and pathology reports.",
                        ),
                        _bullet(
                          "Medical history, Medications, Allergies, Blood group, BMI.",
                        ),
                        _subHeading("4.3 Unique Medical ID"),
                        _bullet("Auto-generated DW-YYYY-STATE-XXXXXX format."),
                        _subHeading("4.4 Technical Data"),
                        _bullet(
                          "Device model, OS version, Anonymized Device ID.",
                        ),
                        _bullet(
                          "GPS location (only for 'Find Nearby', foreground only).",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.security_outlined,
                      title: "5. App Permissions",
                      content: [
                        _subHeading("Android Permissions"),
                        _permissionRow(
                          "CAMERA",
                          "Scan/photograph prescriptions",
                        ),
                        _permissionRow("STORAGE", "Upload/Save reports"),
                        _permissionRow("LOCATION", "Find nearby doctors/labs"),
                        _permissionRow(
                          "NOTIFICATIONS",
                          "Appointment reminders",
                        ),
                        _paragraph(
                          "\n⚠ Doctorwala NEVER tracks location in the background. GPS is used only when you actively trigger a search.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.auto_graph_rounded,
                      title: "6. How We Use Your Data",
                      content: [
                        _bullet(
                          "Medical ID: Maintain lifetime health records.",
                        ),
                        _bullet(
                          "AI Symptom Checker: Provide guidance based on symptoms.",
                        ),
                        _bullet(
                          "Nearby Search: Show closest facilities via device location.",
                        ),
                        _bullet(
                          "Security: Identity verification via safe OTP.",
                        ),
                        _bullet(
                          "Analytics: Anonymized crash reporting and UX improvement.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.psychology_outlined,
                      title: "7. AI Symptom Checker — Disclaimer",
                      isAlert: true,
                      content: [
                        _paragraph(
                          "⚠ CRITICAL DISCLAIMER: The AI Symptom Checker is a HEALTH GUIDANCE TOOL ONLY. It does NOT provide medical diagnosis. In emergencies, call 108 immediately.",
                        ),
                        _subHeading("How AI Processes Data"),
                        _bullet("Symptoms sent securely to our backend."),
                        _bullet(
                          "Anonymized text sent to Claude AI (Anthropic Inc.).",
                        ),
                        _bullet(
                          "NO personal data (Name, ID) is shared with the AI provider.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.share_location_rounded,
                      title: "8. Data Sharing",
                      content: [
                        _paragraph(
                          "✔ We NEVER sell data to pharma or insurance companies.",
                        ),
                        _subHeading("When we share:"),
                        _bullet(
                          "With Providers: Only when you authorize during a visit.",
                        ),
                        _bullet(
                          "Legal Requirement: When compelled by Indian Law/Court Order.",
                        ),
                        _bullet(
                          "Service Providers: SMS gateways and Indian Cloud hosting (AWS/Google Cloud).",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.lock_person_outlined,
                      title: "9. Data Storage & Security",
                      content: [
                        _bullet(
                          "Local Storage: Servers physically located in India.",
                        ),
                        _bullet(
                          "Encryption: AES-256 for records, TLS 1.3 for transit.",
                        ),
                        _bullet(
                          "Hashing: bcrypt for passwords (never plain text).",
                        ),
                        _bullet("RBAC: Role-based access for staff."),
                        _bullet(
                          "Breach: Notification within 72 hours if affected.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.g_translate_rounded,
                      title: "10. Your Rights",
                      content: [
                        _bullet(
                          "Right to Access: Request a copy of your data.",
                        ),
                        _bullet(
                          "Right to Erasure: Request account/data deletion.",
                        ),
                        _bullet(
                          "Right to Withdraw: Toggle consent in Privacy Settings.",
                        ),
                        _bullet(
                          "Portability: Export health records as Password-Protected PDF.",
                        ),
                      ],
                    ),

                    _policySection(
                      icon: Icons.contact_support_outlined,
                      title: "Contact & Grievance",
                      content: [
                        _paragraph("Sumatra Sales Private Limited"),
                        _paragraph("Jurisdiction: Howrah, West Bengal, India"),
                        _paragraph("Support: settings@doctorwala.info"),
                        _paragraph("Grievance: grievance@doctorwala.info"),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            "Company: Sumatra Sales Private Limited",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© 2026 Doctorwala. All rights reserved.',
                            style: TextStyle(
                              color: Colors.blueGrey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _metadataRow(
            Icons.business_rounded,
            "Company",
            "Sumatra Sales Pvt Ltd",
          ),
          const Divider(height: 24),
          _metadataRow(
            Icons.branding_watermark_outlined,
            "Brand",
            "Doctorwala",
          ),
          const Divider(height: 24),
          _metadataRow(
            Icons.language_rounded,
            "Website",
            "www.doctorwala.info",
          ),
          const Divider(height: 24),
          _metadataRow(
            Icons.email_outlined,
            "Contact",
            "info.doctorwala@gmail.com",
          ),
        ],
      ),
    );
  }

  Widget _metadataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey[400], size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.blueGrey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _policySection({
    required IconData icon,
    IconData? iconData,
    required String title,
    required List<Widget> content,
    bool isAlert = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFFF3E0) : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isAlert
                  ? Colors.orange.withAlpha(100)
                  : Colors.white.withAlpha(200),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
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
                      decoration: BoxDecoration(
                        color: (isAlert
                                ? Colors.orange
                                : const Color(0xFF1565C0))
                            .withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconData ?? icon,
                        color:
                            isAlert ? Colors.orange : const Color(0xFF1565C0),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color:
                              isAlert
                                  ? Colors.brown[900]
                                  : const Color(0xFF263238),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF455A64),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _subHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF37474F),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF546E7A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionRow(String name, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF455A64),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        _animatedBlob(
          const Color(0xFF1565C0).withAlpha(15),
          150,
          top: 100,
          left: -50,
        ),
        _animatedBlob(
          const Color(0xFF6A1B9A).withAlpha(12),
          200,
          bottom: 300,
          right: -50,
        ),
        _animatedBlob(
          const Color(0xFF2E7D32).withAlpha(10),
          120,
          top: 400,
          left: 200,
        ),
      ],
    );
  }

  Widget _animatedBlob(
    Color color,
    double size, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 10),
        builder: (context, double value, child) {
          final double moveX =
              ui.lerpDouble(-30, 30, math.sin(value * math.pi * 2)) ?? 0;
          final double moveY =
              ui.lerpDouble(-30, 30, math.cos(value * math.pi * 2)) ?? 0;

          return Transform.translate(
            offset: Offset(moveX, moveY),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 60, spreadRadius: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

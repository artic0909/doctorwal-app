import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[900],
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Effective Date: April 29, 2025',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Introduction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'DoctorWala.info ("we", "our", or "us") values your privacy. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app and services.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'Information We Collect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '- Personal Information (Name, Email, Phone, City)\n'
              '- Usage Data (App usage, clicks, time spent)\n'
              '- Location (only if allowed by you)',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'How We Use Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We use the collected information to:\n'
              '- Provide and improve our services\n'
              '- Customize user experience\n'
              '- Send notifications (if enabled)\n'
              '- Respond to customer queries',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'Data Protection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We implement industry-standard security measures to protect your data. However, no method of transmission over the Internet is 100% secure.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'Third-Party Sharing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We do not sell or rent your personal information. Your data may be shared with trusted partners only to help operate our services, under strict confidentiality agreements.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Choices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can:\n'
              '- Update or delete your profile\n'
              '- Opt-out of notifications\n'
              '- Contact us to remove your account',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                '© 2025 DoctorWala. All rights reserved.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:demoapp/Models/all_available_doctors_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'doctortimedetailsscreen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final AllAvailableDoctorsModel doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    String capitalizeWords(String input) {
      return input
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF9FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: Text(
              capitalizeWords(doctor.partnerDoctorName ?? "Dr. Doctor Name"),
              style: const TextStyle(
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image:
                    doctor.banner != null
                        ? NetworkImage(doctor.banner!)
                        : const AssetImage("assets/images/logo.png"),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            _infoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(BuildContext context) {
    String capitalizeWords(String input) {
      return input
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            capitalizeWords(doctor.partnerDoctorName ?? "Dr. Doctor Name"),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            doctor.partnerDoctorSpecialist ?? "Not Defined",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color.fromARGB(255, 92, 91, 91),
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.person,
            'Designation: ${doctor.partnerDoctorDesignation ?? "Not Defined"}',
          ),
          _infoRow(Icons.phone, doctor.partnerDoctorMobile ?? "Not Defined"),
          _infoRow(Icons.email, doctor.partnerDoctorEmail ?? "Not Defined"),
          _infoRow(
            Icons.location_city,
            'Landmark: ${doctor.partnerDoctorLandmark ?? "Not Defined"}',
          ),
          _infoRow(
            Icons.location_history,
            'State: ${doctor.partnerDoctorState ?? "Not Defined"}',
          ),
          _infoRow(
            Icons.location_searching,
            'City: ${doctor.partnerDoctorCity ?? "Not Defined"}',
          ),
          _infoRow(
            Icons.location_pin,
            'City: ${doctor.partnerDoctorAddress ?? "Not Defined"}',
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton("Send Inquiry", Colors.red, () {
                launchUrl(Uri.parse("tel:${doctor.partnerDoctorMobile}"));
              }),
              _actionButton("See Location", Colors.green, () async {
                final url = doctor.partnerDoctorGoogleMapLink ?? "";
                if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Unable to open map link.")),
                  );
                }
              }),
              _actionButton("Day & Time", Colors.teal, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DoctorTimeDetailsScreen(doctor: doctor),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  static Widget _actionButton(
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }
}

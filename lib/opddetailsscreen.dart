import 'package:flutter/material.dart';
import 'opddoctordetailsscreen.dart'; // import the doctor details screen
import 'opdinquiryscreen.dart'; // import the inquiry screen

class OPDDetailsScreen extends StatelessWidget {
  const OPDDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            title: const Text(
              'OPD Details',
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/blog.jpg',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),

            _infoSection(context),

            const SizedBox(height: 20),

            const Text(
              "OPD DETAILS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 230,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => _doctorCard(context),
            ),

            const SizedBox(height: 30),

            const Text(
              "SERVICE LISTS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bulletItem('Parking Facility'),
                _bulletItem('Free Wi-Fi'),
                _bulletItem('24/7 Emergency'),
                _bulletItem('Flexible Timing'),
                _bulletItem('Sanitized Premises'),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "PHOTOS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/blog.jpg',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            const Text(
              "ABOUT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Lorem ipsum dolor sit amet consectetur, adipisicing elit...",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),

            const Text(
              "VISION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Lorem ipsum dolor sit amet consectetur, adipisicing elit...",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 10),

            const Text(
              "MISSION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Lorem ipsum dolor sit amet consectetur, adipisicing elit...",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JIO JI BHARKA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'OPD Title',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on, 'Ranhati, Kolkata, 700126'),
          _infoRow(Icons.location_city, 'Landmark: Ranhati'),
          _infoRow(Icons.phone, '+91 123 456 789'),
          _infoRow(Icons.email, 'doctorwala9@gmail.com'),
          _infoRow(Icons.person, 'Contact: Saklin Mustak'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton("Send Inquiry", Colors.red, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OPDInquiryScreen(),
                  ),
                );
              }),
              _actionButton("See Location", Colors.green, () {}),
              _actionButton("Feedback", Colors.teal, () {}),
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

  static Widget _doctorCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Icon(Icons.medical_services, size: 40, color: Colors.green),
            const SizedBox(height: 6),
            const Text(
              "Dr. Doctor Name",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MBBS, MD, SP, DG", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Text(
                    "Specialist: Psychologist",
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text("Fees: ₹ 900", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ODPDoctorDetailScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "View Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bulletItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

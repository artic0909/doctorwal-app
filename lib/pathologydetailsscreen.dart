import 'package:flutter/material.dart';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:demoapp/pathologyfeedbackscreen.dart';
import 'package:demoapp/pathologyinquiryscreen.dart';
import 'package:demoapp/pathologytestsdetailsscreen.dart';
import 'package:url_launcher/url_launcher.dart';

class PathologyDetailsScreen extends StatelessWidget {
  final AllAvailablePathModel pathology;

  const PathologyDetailsScreen({super.key, required this.pathology});

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
              'Pathology Details',
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
              child:
                  pathology.bannerImage.isNotEmpty
                      ? Image.network(
                        pathology.bannerImage,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Image.asset(
                              'assets/images/logo.png',
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        'assets/images/logo.png',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
            ),
            const SizedBox(height: 12),
            _infoSection(context),
            const SizedBox(height: 20),
            const Text(
              "PATHOLOGY DETAILS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            pathology.tests.isNotEmpty
                ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pathology.tests.length,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 230,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder:
                      (context, index) => _doctorCard(
                        context,
                        pathology.tests[index],
                        pathology,
                      ),
                )
                : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No Tests Found",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
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
            pathology.services.isNotEmpty
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      pathology.services.expand<Widget>((service) {
                        final List<dynamic> list =
                            service['service_lists'] ?? [];
                        return list.map<Widget>(
                          (item) => _bulletItem(item.toString()),
                        );
                      }).toList(),
                )
                : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No Services Found",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(BuildContext context) {
    String uppercaseWords(String input) {
      return input
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toUpperCase();
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
            'Jio Ji Bharka',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            uppercaseWords(pathology.clinicName),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on, pathology.clinicAddress),
          _infoRow(Icons.location_city, pathology.clinicLandmark),
          _infoRow(Icons.phone, pathology.clinicMobileNumber),
          _infoRow(Icons.email, pathology.clinicEmail),
          _infoRow(Icons.person, 'Contact: ${pathology.contactPersonName}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton("Send Inquiry", Colors.red, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PathologyInquiryScreen(),
                  ),
                );
              }),
              _actionButton("See Location", Colors.green, () async {
                final url = pathology.clinicGoogleMapLink;
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

              _actionButton("Feedback", Colors.teal, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PathologyFeedbackScreen(),
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

  static Widget _doctorCard(
    BuildContext context,
    dynamic test,
    AllAvailablePathModel pathology,
  ) {
    String uppercaseWords(String input) {
      return input
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toUpperCase();
          })
          .join(' ');
    }

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Icon(Icons.bloodtype, size: 40, color: Colors.red),
            const SizedBox(height: 6),
            Text(
              uppercaseWords(test['test_name'] ?? 'N/A'),
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Test Type: ${uppercaseWords(test['test_type'] ?? 'N/A')}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Clinic: ${uppercaseWords(pathology.clinicName ?? 'N/A')}",
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      builder:
                          (context) => PathologyTestsDetailsScreen(test: test),
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

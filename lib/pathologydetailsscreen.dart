import 'dart:async';
import 'package:flutter/material.dart';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:demoapp/pathologyfeedbackscreen.dart';
import 'package:demoapp/pathologytestsdetailsscreen.dart';
import 'package:url_launcher/url_launcher.dart';

class PathologyDetailsScreen extends StatefulWidget {
  final AllAvailablePathModel pathology;
  final Map<String, dynamic> userData;

  const PathologyDetailsScreen({
    super.key,
    required this.pathology,
    required this.userData,
  });

  @override
  State<PathologyDetailsScreen> createState() => _PathologyDetailsScreenState();
}

class _PathologyDetailsScreenState extends State<PathologyDetailsScreen> {
  List<dynamic> filteredTests = [];
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    filteredTests = List.from(widget.pathology.tests);
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = searchController.text.toLowerCase().trim();
      if (query.isEmpty) {
        setState(() {
          filteredTests = List.from(widget.pathology.tests);
        });
      } else {
        setState(() {
          filteredTests =
              widget.pathology.tests.where((test) {
                final name = (test['test_name'] ?? '').toString().toLowerCase();
                final type = (test['test_type'] ?? '').toString().toLowerCase();
                return name.contains(query) || type.contains(query);
              }).toList();
        });
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    _onSearchChanged();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pathology = widget.pathology;

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
            // Banner
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
                            (_, __, ___) => Image.asset(
                              'assets/images/empty-min.jpg',
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        'assets/images/empty-min.jpg',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
            ),
            const SizedBox(height: 12),
            _infoSection(context),

            const SizedBox(height: 20),
            // 🔍 Search Bar (styled exactly as before)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black45),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Tests or Types',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                ],
              ),
            ),

            const Text(
              "PATHOLOGY DETAILS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            // Tests grid
            filteredTests.isNotEmpty
                ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTests.length,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 230,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder:
                      (context, idx) =>
                          _doctorCard(context, filteredTests[idx], pathology),
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

  // Retain your original widgets below unchanged

  Widget _infoSection(BuildContext context) {
    String uppercaseWords(String input) {
      return input
          .split(' ')
          .map(
            (word) =>
                word.isEmpty
                    ? word
                    : word[0].toUpperCase() + word.substring(1).toUpperCase(),
          )
          .join(' ');
    }

    final p = widget.pathology;
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
            'Jio Ji Bharka',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            uppercaseWords(p.clinicName),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on, p.clinicAddress),
          _infoRow(Icons.location_city, p.clinicLandmark),
          _infoRow(Icons.phone, p.clinicMobileNumber),
          _infoRow(Icons.email, p.clinicEmail),
          _infoRow(Icons.person, 'Contact: ${p.contactPersonName}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton("Send Inquiry", Colors.red, () {
                launchUrl(Uri.parse("tel:${p.clinicMobileNumber}"));
              }),
              _actionButton("See Location", Colors.green, () async {
                final url = p.clinicGoogleMapLink;
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
                    builder:
                        (context) => PathologyFeedbackScreen(
                          pathology: p,
                          userData: widget.userData,
                        ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  static Widget _actionButton(
    String label,
    Color color,
    VoidCallback onPressed,
  ) => SizedBox(
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

  static Widget _doctorCard(
    BuildContext context,
    dynamic test,
    AllAvailablePathModel pathology,
  ) {
    String uppercaseWords(String input) {
      return input
          .split(' ')
          .map(
            (word) =>
                word.isEmpty
                    ? word
                    : word[0].toUpperCase() + word.substring(1).toUpperCase(),
          )
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
                    "Clinic: ${uppercaseWords(pathology.clinicName ?? '')}",
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

  static Widget _bulletItem(String label) => Padding(
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

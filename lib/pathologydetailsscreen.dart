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
      final allTests = widget.pathology.tests;
      if (query.isEmpty) {
        setState(() {
          filteredTests = List.from(allTests);
        });
      } else {
        setState(() {
          filteredTests =
              allTests.where((test) {
                final name = (test['test_name'] ?? '').toString().toLowerCase();
                final type = (test['test_type'] ?? '').toString().toLowerCase();
                return name.contains(query) || type.contains(query);
              }).toList();
        });
      }
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          // 1. Scrolling Premium Header
          SliverToBoxAdapter(
            child: _buildImageStyleHeader(context),
          ),

          // 2. Robust Sticky Search Bar
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: const Color(0xFFF8FAFF),
            elevation: 0,
            toolbarHeight: 80,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: _buildSearchBar(),
          ),

          // 3. Test Listing Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: Color(0xFF2E7D32), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Available Diagnostics",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                  ),
                  const Spacer(),
                  Text(
                    "${filteredTests.length} Tests",
                    style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          if (filteredTests.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text("No matching tests found", style: TextStyle(color: Colors.blueGrey[200], fontSize: 13)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filteredTests.length) return null;
                    final test = filteredTests[index];
                    return _buildTestCard(test);
                  },
                  childCount: filteredTests.length,
                ),
              ),
            ),

          // 4. Services Section
          if (widget.pathology.services.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC62828).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFC62828), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Premium Services",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= widget.pathology.services.length) return null;
                    final service = widget.pathology.services[index];
                    final list = service['service_lists'] as List? ?? [];
                    return Column(
                      children: list.map((item) => _buildServiceItem(item?.toString() ?? "")).toList(),
                    );
                  },
                  childCount: widget.pathology.services.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom + 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStyleHeader(BuildContext context) {
    final p = widget.pathology;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _capitalizeWords(p.clinicName),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Official Healthcare Partner",
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (p.contactPersonName.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.person_rounded, color: Colors.white.withAlpha(200), size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Contact Manager: ",
                          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: _capitalizeWords(p.contactPersonName),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on_rounded, color: Colors.white.withAlpha(200), size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Lab Address: ",
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: _capitalizeWords(p.clinicAddress),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _headerActionBtn("CALL", Icons.phone_rounded, () => launchUrl(Uri.parse("tel:${p.clinicMobileNumber}")))),
              const SizedBox(width: 10),
              Expanded(child: _headerActionBtn("MAP", Icons.near_me_rounded, () async {
                final url = p.clinicGoogleMapLink;
                if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              })),
              const SizedBox(width: 10),
              Expanded(child: _headerActionBtn("FEEDBACK", Icons.rate_review_rounded, () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => PathologyFeedbackScreen(pathology: p, userData: widget.userData)));
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerActionBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(28), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withAlpha(40))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Filter diagnostics by name or type...",
            hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(dynamic test) {
    final t = test as Map<String, dynamic>;
    final price = t['test_price']?.toString() ?? '0';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E7D32).withAlpha(10)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PathologyTestsDetailsScreen(test: t, userData: widget.userData, clinicName: widget.pathology.clinicName))),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: const Color(0xFF2E7D32).withAlpha(10), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.science_rounded, color: Color(0xFF2E7D32), size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeWords(t['test_name']?.toString() ?? 'N/A'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Type: ${t['test_type']?.toString() ?? 'General'}",
                    style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹$price", style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 4),
                const Text("BOOK NOW", style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFC62828).withAlpha(5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFC62828), size: 15),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF263238)))),
        ],
      ),
    );
  }

  String _capitalizeWords(String? input) {
    if (input == null || input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }
}

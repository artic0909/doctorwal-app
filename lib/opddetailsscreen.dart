import 'package:demoapp/Models/all_available_opd_model.dart';
import 'package:demoapp/opdfeedbackscreen.dart';
import 'package:demoapp/bookingscreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'opddoctordetailsscreen.dart';

class OPDDetailsScreen extends StatefulWidget {
  final AllAvailableOPDModel opd;
  final Map<String, dynamic> userData;

  const OPDDetailsScreen({
    super.key,
    required this.opd,
    required this.userData,
  });

  @override
  State<OPDDetailsScreen> createState() => _OPDDetailsScreenState();
}

class _OPDDetailsScreenState extends State<OPDDetailsScreen> {
  List<dynamic> filteredDoctors = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredDoctors = List.from(widget.opd.doctors);
  }

  void _filterDoctors(String query) {
    query = query.toLowerCase();
    setState(() {
      final allDoctors = widget.opd.doctors;
      if (query.isEmpty) {
        filteredDoctors = List.from(allDoctors);
      } else {
        filteredDoctors = allDoctors.where((doctor) {
          final name = (doctor['doctor_name'] ?? '').toString().toLowerCase();
          final specialist = (doctor['doctor_specialist'] ?? '').toString().toLowerCase();
          final more = (doctor['doctor_more'] ?? '').toString().toLowerCase();
          return name.contains(query) || specialist.contains(query) || more.contains(query);
        }).toList();
      }
    });
  }

  void _resetSearch() {
    searchController.clear();
    _filterDoctors('');
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

          // 3. Doctor List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            sliver: filteredDoctors.isEmpty 
              ? const SliverToBoxAdapter(child: _EmptyDoctorsState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= filteredDoctors.length) return null;
                      final doctor = filteredDoctors[index];
                      return _buildUniformDoctorCard(context, doctor);
                    },
                    childCount: filteredDoctors.length,
                  ),
                ),
          ),

          // 4. Services Section
          if (widget.opd.services.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildServicesSection(),
            ),
          
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
    final o = widget.opd;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
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
                child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _capitalizeWords(o.clinicName),
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
          if (o.contactPersonName.isNotEmpty) ...[
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
                          text: _capitalizeWords(o.contactPersonName),
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
                        text: "Clinic Address: ",
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: _capitalizeWords("${o.clinicAddress}${o.clinicLandmark.isNotEmpty ? ', ${o.clinicLandmark}' : ''}"),
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
              Expanded(child: _headerActionBtn("CALL", Icons.phone_rounded, () => launchUrl(Uri.parse("tel:${o.clinicMobileNumber}")))),
              const SizedBox(width: 10),
              Expanded(child: _headerActionBtn("MAP", Icons.near_me_rounded, () async {
                final url = o.clinicGoogleMapLink;
                if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              })),
              const SizedBox(width: 10),
              Expanded(child: _headerActionBtn("FEEDBACK", Icons.rate_review_rounded, () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => OPDFeedbackScreen(opd: o, userData: widget.userData)));
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
          onChanged: _filterDoctors,
          decoration: InputDecoration(
            hintText: "Filter doctors by name or specialty...",
            hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 18),
            suffixIcon: searchController.text.isNotEmpty 
                ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: _resetSearch) 
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildUniformDoctorCard(BuildContext context, dynamic doctor) {
    final docs = doctor as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1565C0).withAlpha(8), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(12), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.person_rounded, color: Color(0xFF1565C0), size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _capitalizeWords(docs['doctor_name']?.toString() ?? ""),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00C853).withAlpha(15), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "₹${docs['doctor_fees']?.toString() ?? '0'}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      docs['doctor_specialist']?.toString() ?? "Specialist",
                      style: const TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _miniTagRow(Icons.description_rounded, docs['doctor_more']?.toString() ?? "N/A"),
          const SizedBox(height: 8),
          _miniTagRow(Icons.check_circle_rounded, "Verified Availability"),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ODPDoctorDetailScreen(opd: widget.opd, doctor: docs, userData: widget.userData),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
                  ),
                  child: const Text("VIEW DETAILS", style: TextStyle(color: Color(0xFF1565C0), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          type: BookingType.opd,
                          partnerId: widget.opd.currentlyLoggedInPartnerId.toString(),
                          clinicName: widget.opd.clinicName,
                          userData: widget.userData,
                          itemId: docs['id']?.toString(),
                          itemName: docs['doctor_name']?.toString(),
                          itemPrice: docs['doctor_fees']?.toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("APPOINTMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTagRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.blueGrey[300]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.blueGrey[400], fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blueGrey[50] ?? const Color(0xFFECEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AVAILABLE SERVICES", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE53935), fontSize: 14, letterSpacing: 0.5)),
          const SizedBox(height: 15),
          ...widget.opd.services.expand<Widget>((service) {
            final List<dynamic> list = service['service_lists'] ?? [];
            return list.map<Widget>((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF00C853)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF263238), fontWeight: FontWeight.w600))),
                ],
              ),
            ));
          }).toList(),
        ],
      ),
    );
  }

  String _capitalizeWords(String? input) {
    if (input == null || input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }
}

class _EmptyDoctorsState extends StatelessWidget {
  const _EmptyDoctorsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.person_search_rounded, size: 80, color: Colors.blueGrey[100]),
            const SizedBox(height: 15),
            Text("No doctors match your filter", style: TextStyle(color: Colors.blueGrey[300], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

import 'package:demoapp/Models/all_available_opd_model.dart';
import 'package:demoapp/opdfeedbackscreen.dart';
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
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredDoctors = List.from(widget.opd.doctors);
  }

  void _filterDoctors(String query) {
    query = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredDoctors = List.from(widget.opd.doctors);
      } else {
        filteredDoctors = widget.opd.doctors.where((doctor) {
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
          // 1. Premium App Bar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1565C0),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Clinic Details",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            centerTitle: true,
          ),

          // 2. Comprehensive Clinic Header
          SliverToBoxAdapter(
            child: _buildClinicHeaderCard(context),
          ),

          // 3. Sticky Search Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchDelegate(
              child: _buildStickySearchBar(),
            ),
          ),

          // 4. Doctor List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            sliver: filteredDoctors.isEmpty 
              ? const SliverToBoxAdapter(child: _EmptyDoctorsState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUniformDoctorCard(context, filteredDoctors[index]),
                    childCount: filteredDoctors.length,
                  ),
                ),
          ),

          // 5. Services Section
          if (widget.opd.services.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildServicesSection(),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildClinicHeaderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF), // Non-white background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(15), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1565C0).withAlpha(5), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.business_rounded, color: Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizeWords(widget.opd.clinicName),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF263238), height: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Healthcare Partner",
                      style: TextStyle(color: const Color(0xFF1565C0).withAlpha(150), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _infoRow(Icons.person_outline_rounded, "Contact", _capitalizeWords(widget.opd.contactPersonName.isNotEmpty ? widget.opd.contactPersonName : "Incharge Manager")),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, "Address", "${widget.opd.clinicAddress}, ${widget.opd.clinicLandmark} - ${widget.opd.clinicPincode}"),
          const SizedBox(height: 15),
          Row(
            children: [
              _compactActionBtn(Icons.call_rounded, "CALL", const Color(0xFF1565C0), () => launchUrl(Uri.parse("tel:${widget.opd.clinicMobileNumber}"))),
              const SizedBox(width: 10),
              _compactActionBtn(Icons.directions_rounded, "MAP", const Color(0xFF00C853), () async {
                final url = widget.opd.clinicGoogleMapLink;
                if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              }),
              const SizedBox(width: 10),
              _compactActionBtn(Icons.rate_review_rounded, "FEEDBACK", Colors.orange[800] ?? Colors.orange, () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OPDFeedbackScreen(opd: widget.opd, userData: widget.userData)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey[300]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Color(0xFF455A64), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStickySearchBar() {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: _filterDoctors,
          decoration: InputDecoration(
            hintText: "Filter doctors by name or specialty...",
            hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 18),
            suffixIcon: searchController.text.isNotEmpty 
                ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: _resetSearch) 
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildUniformDoctorCard(BuildContext context, dynamic doctor) {
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
                            _capitalizeWords(doctor['doctor_name'] ?? ""),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00C853).withAlpha(15), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "₹${doctor['doctor_fees'] ?? '0'}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['doctor_specialist'] ?? "Specialist",
                      style: const TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _miniTagRow(Icons.description_rounded, doctor['doctor_more'] ?? "N/A"),
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
                        builder: (context) => ODPDoctorDetailScreen(opd: widget.opd, doctor: doctor),
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
                        builder: (context) => ODPDoctorDetailScreen(opd: widget.opd, doctor: doctor),
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
                  child: const Text("BOOK NOW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

  String _capitalizeWords(String input) {
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }
}

// -----------------------------------------------------------------------------
// STICKY SEARCH DELEGATE
// -----------------------------------------------------------------------------
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 75;

  @override
  double get minExtent => 75;

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

// -----------------------------------------------------------------------------
// EMPTY STATE WIDGET
// -----------------------------------------------------------------------------
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

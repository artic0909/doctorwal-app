import 'package:flutter/material.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String initialCategory;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    required this.initialCategory,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  String _currentCategory = 'all';
  bool _isLoading = true;
  Map<String, dynamic> _results = {
    'opds': [],
    'pathologies': [],
    'doctors': [],
    'total_results': 0,
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _currentCategory = widget.initialCategory;
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getSearchResult(
        _searchController.text,
        category: _currentCategory,
      );
      if (response['status'] == true) {
        setState(() {
          _results = response['data'];
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryTabs(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              Expanded(
                child: Text(
                  "Results for \"${_searchController.text}\"",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Found ${_results['total_results']} results",
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Refine search...",
                hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueGrey, size: 20),
                suffixIcon: IconButton(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF1565C0), size: 18),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'all', 'label': 'All', 'count': _results['total_results']},
      {'id': 'doctor', 'label': 'Doctors', 'count': (_results['doctors'] as List).length},
      {'id': 'opd', 'label': 'OPD', 'count': (_results['opds'] as List).length},
      {'id': 'pathology', 'label': 'Pathology', 'count': (_results['pathologies'] as List).length},
    ];

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          bool isSelected = _currentCategory == cat['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _currentCategory = cat['id'] as String);
              _performSearch();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: Row(
                  children: [
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.blueGrey,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1565C0).withAlpha(30) : Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${cat['count']}",
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF1565C0) : Colors.blueGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList() {
    final allDocs = _results['doctors'] as List;
    final allOpds = _results['opds'] as List;
    final allPaths = _results['pathologies'] as List;

    if (_results['total_results'] == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.blueGrey[100]),
            const SizedBox(height: 16),
            const Text("No results found", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (allDocs.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'doctor')) ...[
          _sectionHeader(Icons.person_rounded, "Doctors Found"),
          ...allDocs.map((d) => _doctorCard(d)),
          const SizedBox(height: 20),
        ],
        if (allOpds.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'opd')) ...[
          _sectionHeader(Icons.assignment_rounded, "OPD Clinics"),
          ...allOpds.map((o) => _clinicCard(o, 'opd')),
          const SizedBox(height: 20),
        ],
        if (allPaths.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'pathology')) ...[
          _sectionHeader(Icons.biotech_rounded, "Pathology Labs"),
          ...allPaths.map((p) => _clinicCard(p, 'pathology')),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
        ],
      ),
    );
  }

  Widget _doctorCard(dynamic doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.person_rounded, color: Color(0xFF1565C0), size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['partner_doctor_name'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
                    const SizedBox(height: 4),
                    Text(doc['partner_doctor_specialist'] ?? "", style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: Colors.blueGrey[300]),
                        const SizedBox(width: 4),
                        Expanded(child: Text("${doc['partner_doctor_city']}, ${doc['partner_doctor_state']}", style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),
          Row(
            children: [
               Expanded(child: _infoItem(Icons.work_rounded, doc['partner_doctor_designation'] ?? "Doctor")),
               _continueBtn(() async {
                 final url = doc['partner_doctor_google_map_link'];
                 if (url != null && await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
               }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clinicCard(dynamic clinic, String type) {
    final doctors = clinic['doctors'] as List?;
    final tests = clinic['tests'] as List?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: type == 'opd' ? Colors.blue[600] : Colors.green[600], borderRadius: BorderRadius.circular(6)),
                 child: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
               ),
               const Spacer(),
               Icon(Icons.more_vert_rounded, color: Colors.blueGrey[200], size: 18),
             ],
           ),
           const SizedBox(height: 10),
           Text(clinic['clinic_name'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
           const SizedBox(height: 4),
           Row(
              children: [
                Icon(Icons.location_on_rounded, size: 12, color: Colors.blueGrey[300]),
                const SizedBox(width: 4),
                Expanded(child: Text(clinic['clinic_address'] ?? "", style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              ],
           ),
           const SizedBox(height: 12),
           if (doctors != null && doctors.isNotEmpty) ...[
             const Text("Specialists:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
             const SizedBox(height: 6),
             ...doctors.take(3).map((d) => Padding(
               padding: const EdgeInsets.only(bottom: 4),
               child: Row(
                 children: [
                   const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF1565C0)),
                   const SizedBox(width: 8),
                   Expanded(child: Text("${d['doctor_name']} (${d['doctor_specialist']})", style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                 ],
               ),
             )),
           ],
           if (tests != null && tests.isNotEmpty) ...[
             const Text("Available Tests:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
             const SizedBox(height: 6),
             Wrap(
               spacing: 6,
               runSpacing: 6,
               children: tests.take(4).map((t) => Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: Colors.green.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                 child: Text(t['test_type'] ?? "", style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w800)),
               )).toList(),
             ),
           ],
           const SizedBox(height: 15),
           const Divider(height: 1),
           const SizedBox(height: 15),
           Row(
             children: [
                Expanded(child: _infoItem(Icons.phone_rounded, clinic['clinic_mobile_number'] ?? "")),
                _continueBtn(() async {
                   final url = clinic['clinic_google_map_link'];
                   if (url != null && await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
                }),
             ],
           ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey[300]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: Colors.blueGrey[400], fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _continueBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: const Row(
          children: [
            Icon(Icons.directions_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text("CONTINUE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

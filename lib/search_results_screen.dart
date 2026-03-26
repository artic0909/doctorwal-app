import 'package:flutter/material.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/opddetailsscreen.dart';
import 'package:demoapp/pathologydetailsscreen.dart';
import 'package:demoapp/doctordetailsscreen.dart';
import 'package:demoapp/Models/all_available_opd_model.dart';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:demoapp/Models/all_available_doctors_model.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String initialCategory;
  final Map<String, dynamic> userData;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    required this.initialCategory,
    required this.userData,
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
          _sectionHeader(Icons.person_rounded, "Doctors Found", const Color(0xFF673AB7)),
          ...allDocs.map((d) => _uniformResultCard(
            type: 'DOCTOR',
            title: d['partner_doctor_name'] ?? "Unknown Doctor",
            subtitle: d['partner_doctor_specialist'] ?? "Specialist",
            color: const Color(0xFF673AB7),
            icon: Icons.person_rounded,
            infoLines: [
              {"icon": Icons.work_rounded, "text": d['partner_doctor_designation'] ?? "Doctor"},
              {"icon": Icons.location_on_rounded, "text": "${d['partner_doctor_city']}, ${d['partner_doctor_state']}"},
            ],
            rawData: d,
          )),
          const SizedBox(height: 20),
        ],
        if (allOpds.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'opd')) ...[
          _sectionHeader(Icons.assignment_rounded, "OPD Clinics", const Color(0xFF1565C0)),
          ...allOpds.map((o) => _uniformResultCard(
            type: 'OPD CLINIC',
            title: o['clinic_name'] ?? "Unknown Clinic",
            subtitle: o['clinic_address'] ?? "No Address",
            color: const Color(0xFF1565C0),
            icon: Icons.local_hospital_rounded,
            infoLines: [
              {"icon": Icons.phone_rounded, "text": o['clinic_mobile_number'] ?? ""},
              {"icon": Icons.group_rounded, "text": "Multiple Specialists Available"},
            ],
            extraItems: (o['doctors'] as List?)?.take(2).map((d) => "${d['doctor_name']} (${d['doctor_specialist']})").toList(),
            rawData: o,
          )),
          const SizedBox(height: 20),
        ],
        if (allPaths.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'pathology')) ...[
          _sectionHeader(Icons.biotech_rounded, "Pathology Labs", const Color(0xFF2E7D32)),
          ...allPaths.map((p) => _uniformResultCard(
            type: 'PATHOLOGY LAB',
            title: p['clinic_name'] ?? "Unknown Lab",
            subtitle: p['clinic_address'] ?? "No Address",
            color: const Color(0xFF2E7D32),
            icon: Icons.biotech_rounded,
            infoLines: [
              {"icon": Icons.phone_rounded, "text": p['clinic_mobile_number'] ?? ""},
              {"icon": Icons.science_rounded, "text": "Diagnostics & Testing"},
            ],
            extraItems: (p['tests'] as List?)?.take(3).map((t) => t['test_type'] as String).toList(),
            rawData: p,
          )),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
        ],
      ),
    );
  }

  Widget _uniformResultCard({
    required String type,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required List<Map<String, dynamic>> infoLines,
    required Map<String, dynamic> rawData,
    List<String>? extraItems,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withAlpha(10), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  type,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              Icon(Icons.verified_rounded, color: color.withAlpha(80), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...infoLines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(line['icon'] as IconData, size: 14, color: Colors.blueGrey[300]),
                const SizedBox(width: 8),
                Expanded(child: Text(line['text'] as String, style: TextStyle(fontSize: 11, color: Colors.blueGrey[400], fontWeight: FontWeight.w600))),
              ],
            ),
          )),
          if (extraItems != null && extraItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: extraItems.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withAlpha(10), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(20))),
                child: Text(item, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),
          Row(
            children: [
              const Spacer(),
              _continueBtn(color, () {
                _navigateToDetail(type, rawData);
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(String type, Map<String, dynamic> rawData) {
    if (type == 'OPD CLINIC') {
      final opdModel = AllAvailableOPDModel.fromSearchResult(rawData);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OPDDetailsScreen(
            opd: opdModel,
            userData: widget.userData,
          ),
        ),
      );
    } else if (type == 'PATHOLOGY LAB') {
      final pathModel = AllAvailablePathModel.fromSearchResult(rawData);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PathologyDetailsScreen(
            pathology: pathModel,
            userData: widget.userData,
          ),
        ),
      );
    } else if (type == 'DOCTOR') {
      final doctorModel = AllAvailableDoctorsModel.fromSearchResult(rawData);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorDetailsScreen(
            doctor: doctorModel,
            userData: widget.userData,
          ),
        ),
      );
    }
  }

  Widget _continueBtn(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: const Row(
          children: [
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text("CONTINUE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

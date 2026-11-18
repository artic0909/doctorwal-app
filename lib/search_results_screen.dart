import 'package:flutter/material.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/opddetailsscreen.dart';
import 'package:demoapp/pathologydetailsscreen.dart';
import 'package:demoapp/doctordetailsscreen.dart';
import 'package:demoapp/Models/all_available_opd_model.dart';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:demoapp/Models/all_available_doctors_model.dart';
import 'package:demoapp/services/location_service.dart';
import 'package:demoapp/widgets/skeleton_loader.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String initialCategory;
  final bool initialIsNearMe;
  final Map<String, dynamic> userData;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    required this.initialCategory,
    this.initialIsNearMe = true,
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
  bool _isNearMe = true;
  String _userCity = '';
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
    _isNearMe = widget.initialIsNearMe;
    _initLocationAndSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndSearch() async {
    if (_isNearMe) {
      final city = await LocationService.getUserCity(context: context);
      if (city != null) {
        _userCity = city;
      }
    } else {
      _userCity = '';
    }
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getSearchResult(
        _searchController.text,
        category: _currentCategory,
        userCity: _userCity,
      );
      if (response['status'] == true) {
        setState(() {
          _results = response['data'];
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLocationToggle() {
    return GestureDetector(
      onTap: () async {
        final newValue = !_isNearMe;
        setState(() => _isNearMe = newValue);
        await LocationService.setIsNearMe(newValue);
        _initLocationAndSearch();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isNearMe ? Colors.white : Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isNearMe ? Colors.white : Colors.white.withAlpha(70),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isNearMe ? Icons.near_me_rounded : Icons.public_rounded,
              color: _isNearMe ? const Color(0xFF1565C0) : Colors.white,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              _isNearMe ? "Near Me" : "Everywhere",
              style: TextStyle(
                color: _isNearMe ? const Color(0xFF1565C0) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 16.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x330D47A1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Back + Title + Results Count + Location Toggle
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchController.text.isNotEmpty
                          ? "Results for \"${_searchController.text}\""
                          : "Search Results",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_results['total_results']} total results found",
                      style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildLocationToggle(),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Search Input Field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Refine search...",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                                _performSearch();
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                GestureDetector(
                  onTap: _performSearch,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {
        'id': 'all',
        'label': 'All',
        'icon': Icons.auto_awesome_rounded,
        'count': _results['total_results'] ?? 0,
      },
      {
        'id': 'doctor',
        'label': 'Doctor',
        'icon': Icons.medical_services_rounded,
        'count': (_results['doctors'] as List?)?.length ?? 0,
      },
      {
        'id': 'opd',
        'label': 'Chambers (OPD)',
        'icon': Icons.business_rounded,
        'count': (_results['opds'] as List?)?.length ?? 0,
      },
      {
        'id': 'pathology',
        'label': 'Lab Tests',
        'icon': Icons.biotech_rounded,
        'count': (_results['pathologies'] as List?)?.length ?? 0,
      },
    ];

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final bool isSelected = _currentCategory == cat['id'];
          final IconData icon = cat['icon'] as IconData;
          final int count = cat['count'] as int;

          return GestureDetector(
            onTap: () {
              if (_currentCategory != cat['id']) {
                setState(() => _currentCategory = cat['id'] as String);
                _performSearch();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1565C0) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withAlpha(35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(45)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$count",
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "No results found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty
                    ? "We couldn't find any matches for \"${_searchController.text}\". Try another keyword or switch location."
                    : "No items match your filter. Try clearing filters or searching for something else.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
      children: [
        if (allDocs.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'doctor')) ...[
          _sectionHeader(Icons.medical_services_rounded, "Doctors (${allDocs.length})", const Color(0xFF1565C0)),
          ...allDocs.map((d) => _uniformResultCard(
            type: 'DOCTOR',
            title: d['partner_doctor_name'] ?? "Unknown Doctor",
            subtitle: d['partner_doctor_specialist'] ?? "Specialist",
            color: const Color(0xFF1565C0),
            icon: Icons.person_rounded,
            actionLabel: "Book Appointment",
            infoLines: [
              if (d['partner_doctor_designation'] != null && d['partner_doctor_designation'].toString().isNotEmpty)
                {"icon": Icons.work_outline_rounded, "text": d['partner_doctor_designation'].toString()},
              if (d['partner_doctor_city'] != null || d['partner_doctor_state'] != null)
                {
                  "icon": Icons.location_on_outlined,
                  "text": "${d['partner_doctor_city'] ?? ''}, ${d['partner_doctor_state'] ?? ''}".replaceAll(RegExp(r'^,\s*|,\s*$'), '')
                },
            ],
            rawData: d,
          )),
          const SizedBox(height: 14),
        ],
        if (allOpds.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'opd')) ...[
          _sectionHeader(Icons.business_rounded, "Chambers & OPDs (${allOpds.length})", const Color(0xFF00897B)),
          ...allOpds.map((o) => _uniformResultCard(
            type: 'OPD CLINIC',
            title: o['clinic_name'] ?? "Unknown Clinic",
            subtitle: o['clinic_address'] ?? "No Address",
            color: const Color(0xFF00897B),
            icon: Icons.local_hospital_rounded,
            actionLabel: "View Chamber",
            infoLines: [
              if (o['clinic_mobile_number'] != null && o['clinic_mobile_number'].toString().isNotEmpty)
                {"icon": Icons.phone_outlined, "text": o['clinic_mobile_number'].toString()},
              {"icon": Icons.group_outlined, "text": "Multiple Specialists Available"},
            ],
            extraItems: (o['doctors'] as List?)?.take(3).map((d) => "${d['doctor_name']} (${d['doctor_specialist']})").toList(),
            rawData: o,
          )),
          const SizedBox(height: 14),
        ],
        if (allPaths.isNotEmpty && (_currentCategory == 'all' || _currentCategory == 'pathology')) ...[
          _sectionHeader(Icons.biotech_rounded, "Pathology Labs (${allPaths.length})", const Color(0xFF2E7D32)),
          ...allPaths.map((p) => _uniformResultCard(
            type: 'PATHOLOGY LAB',
            title: p['clinic_name'] ?? "Unknown Lab",
            subtitle: p['clinic_address'] ?? "No Address",
            color: const Color(0xFF2E7D32),
            icon: Icons.biotech_rounded,
            actionLabel: "View Lab & Tests",
            infoLines: [
              if (p['clinic_mobile_number'] != null && p['clinic_mobile_number'].toString().isNotEmpty)
                {"icon": Icons.phone_outlined, "text": p['clinic_mobile_number'].toString()},
              {"icon": Icons.science_outlined, "text": "Certified Diagnostics & Testing"},
            ],
            extraItems: (p['tests'] as List?)?.take(4).map((t) => t['test_type'] as String).toList(),
            rawData: p,
          )),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
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
    required String actionLabel,
    required List<Map<String, dynamic>> infoLines,
    required Map<String, dynamic> rawData,
    List<String>? extraItems,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDetail(type, rawData),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.verified_rounded, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Image + Title + Subtitle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: (type == 'DOCTOR' && rawData['banner'] != null)
                        ? Image.network(
                            _getImageUrl(rawData['banner'] is Map
                                ? rawData['banner']['doctorbanner']
                                : rawData['banner']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(icon, color: color, size: 26),
                          )
                        : Icon(icon, color: color, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Lines
            ...infoLines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    line['icon'] as IconData,
                    size: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line['text'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),

            // Extra chips (e.g. tests available or specialties)
            if (extraItems != null && extraItems.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: extraItems.map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withAlpha(30)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Bottom Action Row
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(45),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(String type, Map<String, dynamic> rawData) {
    if (type == 'OPD CLINIC') {
      final opdModel = AllAvailableOPDModel.fromSearchResult(rawData);
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => OPDDetailsScreen(
            opd: opdModel,
            userData: widget.userData,
          ),
        ),
      );
    } else if (type == 'PATHOLOGY LAB') {
      final pathModel = AllAvailablePathModel.fromSearchResult(rawData);
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => PathologyDetailsScreen(
            pathology: pathModel,
            userData: widget.userData,
          ),
        ),
      );
    } else if (type == 'DOCTOR') {
      final doctorModel = AllAvailableDoctorsModel.fromSearchResult(rawData);
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => DoctorDetailsScreen(
            doctor: doctorModel,
            userData: widget.userData,
          ),
        ),
      );
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    const String domain = "https://doctorwala.info/";
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }
    return domain + cleanPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryTabs(),
          Expanded(
            child: _isLoading
                ? const SearchResultsSkeleton()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }
}

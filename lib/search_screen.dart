import 'package:flutter/material.dart';
import 'package:demoapp/search_results_screen.dart';
import 'package:demoapp/services/location_service.dart';

class SearchScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SearchScreen({super.key, required this.userData});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  bool _isNearMe = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final val = await LocationService.getIsNearMe();
    if (mounted) {
      setState(() => _isNearMe = val);
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'All',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'id': 'doctor',
      'name': 'Doctor',
      'icon': Icons.medical_services_rounded,
    },
    {
      'id': 'opd',
      'name': 'Chambers (OPD)',
      'icon': Icons.business_rounded,
    },
    {
      'id': 'pathology',
      'name': 'Lab Tests',
      'icon': Icons.biotech_rounded,
    },
  ];

  final List<Map<String, dynamic>> _popularSpecialties = const [
    {'name': 'Cardiologist', 'icon': Icons.favorite_rounded, 'color': Color(0xFFE11D48)},
    {'name': 'Dermatologist', 'icon': Icons.face_retouching_natural_rounded, 'color': Color(0xFFD97706)},
    {'name': 'Pediatrician', 'icon': Icons.child_care_rounded, 'color': Color(0xFF0284C7)},
    {'name': 'Gynecologist', 'icon': Icons.pregnant_woman_rounded, 'color': Color(0xFF9333EA)},
    {'name': 'Orthopedic', 'icon': Icons.accessibility_new_rounded, 'color': Color(0xFF059669)},
    {'name': 'Neurologist', 'icon': Icons.psychology_rounded, 'color': Color(0xFF7C3AED)},
    {'name': 'Dentist', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': Color(0xFF0D9488)},
    {'name': 'Eye Specialist', 'icon': Icons.visibility_rounded, 'color': Color(0xFF2563EB)},
    {'name': 'General Physician', 'icon': Icons.health_and_safety_rounded, 'color': Color(0xFF1565C0)},
    {'name': 'ENT Specialist', 'icon': Icons.hearing_rounded, 'color': Color(0xFFB45309)},
    {'name': 'General Surgeon', 'icon': Icons.healing_rounded, 'color': Color(0xFFDC2626)},
    {'name': 'Gastroenterologist', 'icon': Icons.medication_rounded, 'color': Color(0xFF16A34A)},
  ];

  final List<Map<String, dynamic>> _popularLabTests = const [
    {'name': 'Full Body Checkup', 'icon': Icons.verified_user_rounded, 'color': Color(0xFF00897B)},
    {'name': 'Blood Test (CBC)', 'icon': Icons.bloodtype_rounded, 'color': Color(0xFFE11D48)},
    {'name': 'Thyroid Profile (TSH)', 'icon': Icons.biotech_rounded, 'color': Color(0xFF7C3AED)},
    {'name': 'Lipid Profile', 'icon': Icons.monitor_heart_rounded, 'color': Color(0xFFEA580C)},
    {'name': 'Diabetes / HbA1c', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF0284C7)},
    {'name': 'X-Ray & Imaging', 'icon': Icons.camera_alt_rounded, 'color': Color(0xFF4F46E5)},
    {'name': 'Liver Function Test', 'icon': Icons.science_rounded, 'color': Color(0xFF059669)},
    {'name': 'Urine Routine', 'icon': Icons.colorize_rounded, 'color': Color(0xFFD97706)},
  ];

  void _handleSearch(String query, {String? categoryOverride}) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          initialQuery: query.trim(),
          initialCategory: categoryOverride ?? _selectedCategory,
          initialIsNearMe: _isNearMe,
          userData: widget.userData,
        ),
      ),
    );
  }

  Widget _buildLocationToggle() {
    return GestureDetector(
      onTap: () async {
        final newValue = !_isNearMe;
        setState(() => _isNearMe = newValue);
        await LocationService.setIsNearMe(newValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isNearMe ? const Color(0xFF00897B).withAlpha(18) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isNearMe ? const Color(0xFF00897B) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isNearMe ? Icons.near_me_rounded : Icons.public_rounded,
              color: _isNearMe ? const Color(0xFF00897B) : const Color(0xFF64748B),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _isNearMe ? "Near Me" : "Everywhere",
              style: TextStyle(
                color: _isNearMe ? const Color(0xFF00897B) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 22),
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
                hintText: "Search doctor, clinic, test, specialty...",
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (query) => _handleSearch(query),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _handleSearch(_searchController.text),
            child: Container(
              margin: const EdgeInsets.all(5),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                "SEARCH IN",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final bool isSelected = _selectedCategory == cat['id'];
              final IconData iconData = cat['icon'] as IconData;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              color: const Color(0xFF1565C0).withAlpha(40),
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
                        iconData,
                        size: 15,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Search Nearby",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "Doctors • Chambers • Lab Tests",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildLocationToggle(),
                  if (Navigator.canPop(context)) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 17),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Search Bar Input
            _buildSearchBar(),

            // Filter Category Tabs
            _buildCategoryFilters(),

            const SizedBox(height: 16),

            // Scrollable Suggestions & Popular Tags
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                children: [
                  // 1. Popular Doctor Specialties Section
                  _buildSectionHeader("POPULAR SPECIALTIES", Icons.local_fire_department_rounded, const Color(0xFFEA580C)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularSpecialties.map((item) {
                      final name = item['name'] as String;
                      final icon = item['icon'] as IconData;
                      final color = item['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          _searchController.text = name;
                          _handleSearch(name, categoryOverride: 'doctor');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(22),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 13),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 20),

                  // 2. Common Lab Tests & Diagnostics Section
                  _buildSectionHeader("POPULAR LAB TESTS & SCANS", Icons.biotech_rounded, const Color(0xFF00897B)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularLabTests.map((item) {
                      final name = item['name'] as String;
                      final icon = item['icon'] as IconData;
                      final color = item['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          _searchController.text = name;
                          _handleSearch(name, categoryOverride: 'pathology');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(22),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 13),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

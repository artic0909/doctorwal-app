import 'package:flutter/material.dart';
import 'package:demoapp/search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All'},
    {'id': 'doctor', 'name': 'Doctors'},
    {'id': 'opd', 'name': 'OPD'},
    {'id': 'pathology', 'name': 'Pathology'},
  ];

  final List<String> _popularTags = [
    'Cardiologist', 'Blood Test', 'Urine Test', 'Eye Specialist', 'X-Ray',
    'Skin Doctor', 'Dentist', 'Orthopedic', 'Pediatrician', 'General Physician',
    'General Surgeon', 'Gynecologist'
  ];

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          initialQuery: query,
          initialCategory: _selectedCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Search Nearby",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                        ),
                        Text(
                          "Doctors • Clinics • Tests",
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey[300], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.blueGrey, size: 20),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blueGrey[50],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1565C0).withAlpha(100), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1565C0).withAlpha(15), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 15),
                    const Icon(Icons.search_rounded, color: Color(0xFF1565C0)),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Type doctor name, clinic, test, city...",
                          hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                        ),
                        onSubmitted: _handleSearch,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleSearch(_searchController.text),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filters & Popular
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("FILTER:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((cat) {
                        bool isSelected = _selectedCategory == cat['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['id']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF1565C0).withAlpha(15)),
                            ),
                            child: Text(
                              cat['name']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1565C0),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    const Divider(color: Color(0xFFF0F2F5)),
                    const SizedBox(height: 20),
                    const Text("POPULAR:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1.2)),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularTags.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            _searchController.text = tag;
                            _handleSearch(tag);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFF1565C0).withAlpha(30)),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

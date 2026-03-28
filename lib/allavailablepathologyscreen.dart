import 'dart:async';
import 'dart:convert';
import 'package:demoapp/pathologydetailsscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Models/all_available_path_model.dart';

class AllAvailablePathologyScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AllAvailablePathologyScreen({super.key, required this.userData});

  @override
  State<AllAvailablePathologyScreen> createState() =>
      _AllAvailablePathologyScreenState();
}

class _AllAvailablePathologyScreenState
    extends State<AllAvailablePathologyScreen> {
  List<AllAvailablePathModel> _clinics = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadMoreLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchInitialClinics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchInitialClinics();
      }
    });
  }

  Future<void> _fetchInitialClinics() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _clinics = [];
    });
    await _fetchClinics(1);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchClinics(int page) async {
    final queryParam = _searchQuery.isNotEmpty ? '&query=${Uri.encodeComponent(_searchQuery)}' : '';
    final url = Uri.parse("https://doctorwala.info/api/api/all-pathology-contacts?page=$page$queryParam");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];
        final bool isSearch = jsonData['is_search'] ?? false;

        setState(() {
          final newClinics = data.map((json) => AllAvailablePathModel.fromJson(json)).toList();
          if (page == 1) {
            _clinics = newClinics;
          } else {
            _clinics.addAll(newClinics);
          }
          
          if (isSearch) {
            _currentPage = 1;
            _lastPage = 1;
          } else {
            _currentPage = jsonData['current_page'] ?? 1;
            _lastPage = jsonData['last_page'] ?? 1;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching pathology clinics: $e");
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _lastPage || _isLoadMoreLoading) return;

    setState(() => _isLoadMoreLoading = true);
    await _fetchClinics(_currentPage + 1);
    setState(() => _isLoadMoreLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Removed client-side filtering
    final displayClinics = _clinics;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : RefreshIndicator(
                    onRefresh: _fetchInitialClinics,
                    color: const Color(0xFF2E7D32),
                    child: displayClinics.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          itemCount: displayClinics.length + (_currentPage < _lastPage ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < displayClinics.length) {
                              return _buildPathologyCard(displayClinics[index]);
                            } else {
                              return _buildLoadMoreBtn();
                            }
                          },
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No pathology labs available" : "No results for \"$_searchQuery\"",
            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 15),
          const Text(
            "Pathology Labs",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 5),
          const Text(
            "Certified diagnostic testing at home",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search for tests or labs...",
                hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathologyCard(AllAvailablePathModel clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withAlpha(8), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: const Color(0xFF2E7D32).withAlpha(15), width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PathologyDetailsScreen(pathology: clinic, userData: widget.userData))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70, height: 70, color: const Color(0xFF2E7D32).withAlpha(10),
                child: const Icon(Icons.biotech_rounded, color: Color(0xFF2E7D32), size: 30),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeWords(clinic.clinicName),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalizeWords(clinic.clinicAddress),
                    style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.science_rounded, size: 12, color: Colors.blueGrey[300]),
                      const SizedBox(width: 6),
                      Text(
                        "${clinic.tests.length} Tests Available",
                        style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: _isLoadMoreLoading
            ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
            : TextButton(
                onPressed: _loadMore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: const Color(0xFF2E7D32).withAlpha(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "VIEW MORE LABS",
                  style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
      ),
    );
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }
}

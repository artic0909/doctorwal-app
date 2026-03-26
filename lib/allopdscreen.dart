import 'dart:convert';
import 'package:demoapp/opddetailsscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Models/all_available_opd_model.dart';

class AllAvailableOPDScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AllAvailableOPDScreen({super.key, required this.userData});

  @override
  State<AllAvailableOPDScreen> createState() => _AllAvailableOPDScreenState();
}

class _AllAvailableOPDScreenState extends State<AllAvailableOPDScreen> {
  List<AllAvailableOPDModel> _clinics = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadMoreLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchInitialClinics();
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
    final url = Uri.parse(
      "https://doctorwala.info/api/api/all-opd-contacts?page=$page",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];
        
        setState(() {
          final newClinics = data.map((json) => AllAvailableOPDModel.fromJson(json)).toList();
          _clinics.addAll(newClinics);
          _currentPage = jsonData['current_page'] ?? 1;
          _lastPage = jsonData['last_page'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint("Error fetching OPD clinics: $e");
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
    // Client-side filtering on already-fetched clinics
    final filteredClinics = _clinics.where((clinic) {
      final name = clinic.clinicName.toLowerCase();
      final address = clinic.clinicAddress.toLowerCase();
      final query = _searchQuery.toLowerCase();

      final doctorMatch = clinic.doctors.any((doctor) {
        final doctorName = (doctor['doctor_name'] ?? '').toString().toLowerCase();
        final specialization = (doctor['doctor_specialist'] ?? '').toString().toLowerCase();
        return doctorName.contains(query) || specialization.contains(query);
      });

      return name.contains(query) || address.contains(query) || doctorMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          // 1. Premium Header
          _buildHeader(),

          // 2. Listing
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : RefreshIndicator(
                    onRefresh: _fetchInitialClinics,
                    color: const Color(0xFF1565C0),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      itemCount: filteredClinics.length + (_currentPage < _lastPage ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < filteredClinics.length) {
                          return _buildClinicCard(filteredClinics[index]);
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
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
            "Available OPD Clinics",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 5),
          Text(
            "Book clinical appointments instantly",
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              onChanged: (value) => setState(() {
                _searchQuery = value;
              }),
              decoration: InputDecoration(
                hintText: "Search for clinics or doctors...",
                hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(AllAvailableOPDModel clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withAlpha(8), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(15), width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OPDDetailsScreen(opd: clinic, userData: widget.userData))),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70, height: 70, color: const Color(0xFF1565C0).withAlpha(10),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF1565C0), size: 30),
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
                        style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.group_rounded, size: 12, color: Colors.blueGrey[300]),
                          const SizedBox(width: 6),
                          Text(
                            "${clinic.doctors.length} Specialists Available",
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
            ? const CircularProgressIndicator(color: Color(0xFF1565C0))
            : TextButton(
                onPressed: _loadMore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: const Color(0xFF1565C0).withAlpha(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "VIEW MORE CLINICS",
                  style: TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

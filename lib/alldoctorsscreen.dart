import 'package:flutter/material.dart';
import 'package:demoapp/doctordetailsscreen.dart';
import 'package:demoapp/Models/all_available_doctors_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  List<AllAvailableDoctorsModel> _doctors = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadMoreLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchInitialDoctors();
  }

  Future<void> _fetchInitialDoctors() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _doctors = [];
    });
    await _fetchDoctors(1);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchDoctors(int page) async {
    try {
      final response = await http.get(
        Uri.parse('https://doctorwala.info/api/api/all-doctors-contacts?page=$page'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Handle both paginated 'data' key and legacy 'allDoctorContacts' key
        final List<dynamic> data = jsonData['data'] ?? jsonData['allDoctorContacts'] ?? [];
        
        setState(() {
          final newDoctors = data.map((json) => AllAvailableDoctorsModel.fromJson(json)).toList();
          _doctors.addAll(newDoctors);
          _currentPage = jsonData['current_page'] ?? 1;
          _lastPage = jsonData['last_page'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _lastPage || _isLoadMoreLoading) return;

    setState(() => _isLoadMoreLoading = true);
    await _fetchDoctors(_currentPage + 1);
    setState(() => _isLoadMoreLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Client-side filtering on fetched results
    final filteredDoctors = _doctors.where((doctor) {
      final name = doctor.partnerDoctorName?.toLowerCase() ?? '';
      final address = doctor.partnerDoctorAddress?.toLowerCase() ?? '';
      final specialist = doctor.partnerDoctorSpecialist?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || address.contains(query) || specialist.contains(query);
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
                    onRefresh: _fetchInitialDoctors,
                    color: const Color(0xFF1565C0),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      itemCount: filteredDoctors.length + (_currentPage < _lastPage ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < filteredDoctors.length) {
                          return _buildDoctorCard(filteredDoctors[index]);
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
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
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
            "Specialist Doctors",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 5),
          Text(
            "Connect with top experts in 50+ specialties",
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
                hintText: "Search by name, specialty, or city...",
                hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6A1B9A), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(AllAvailableDoctorsModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6A1B9A).withAlpha(8), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: const Color(0xFF6A1B9A).withAlpha(15), width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailsScreen(doctor: doctor))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF6A1B9A).withAlpha(30), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: 80, height: 80, color: const Color(0xFF6A1B9A).withAlpha(10),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF6A1B9A), size: 40),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeWords(doctor.partnerDoctorName ?? "Unknown Doctor"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalizeWords(doctor.partnerDoctorSpecialist ?? "Specialist"),
                    style: const TextStyle(color: Color(0xFF6A1B9A), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: Colors.blueGrey[300]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _capitalizeWords(doctor.partnerDoctorAddress ?? "Address not provided"),
                          style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            ? const CircularProgressIndicator(color: Color(0xFF6A1B9A))
            : TextButton(
                onPressed: _loadMore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: const Color(0xFF6A1B9A).withAlpha(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "VIEW MORE DOCTORS",
                  style: TextStyle(color: Color(0xFF6A1B9A), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

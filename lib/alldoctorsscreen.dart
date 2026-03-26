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
  int _visibleCount = 5;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('https://doctorwala.info/api/api/all-doctors-contacts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['allDoctorContacts'];
        setState(() {
          _doctors = data.map((json) => AllAvailableDoctorsModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
      setState(() => _isLoading = false);
    }
  }

  void _loadMore() {
    setState(() {
      _visibleCount += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allFiltered = _doctors.where((doctor) {
      final name = doctor.partnerDoctorName?.toLowerCase() ?? '';
      final address = doctor.partnerDoctorAddress?.toLowerCase() ?? '';
      final specialist = doctor.partnerDoctorSpecialist?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || address.contains(query) || specialist.contains(query);
    }).toList();

    final displayedDoctors = allFiltered.take(_visibleCount).toList();

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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      ...displayedDoctors.map((doctor) => _buildDoctorCard(doctor)),
                      if (allFiltered.length > _visibleCount)
                        _buildViewMoreBtn(),
                    ],
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
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)], // Branded Purple for Specialists
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
                _visibleCount = 5; // Reset pagination on search
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
                child: doctor.banner != null && doctor.banner!.isNotEmpty
                    ? Image.network(doctor.banner!, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholderImage())
                    : _placeholderImage(),
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

  Widget _placeholderImage() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(color: const Color(0xFF6A1B9A).withAlpha(10), borderRadius: BorderRadius.circular(13)),
      child: const Icon(Icons.person_rounded, color: Color(0xFF6A1B9A), size: 40),
    );
  }

  Widget _buildViewMoreBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: TextButton(
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

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
  int _visibleCount = 5;

  @override
  void initState() {
    super.initState();
    fetchClinics();
  }

  Future<void> fetchClinics() async {
    final url = Uri.parse(
      "http://doctorwala.info/api/api/all-opd-contacts",
    ); // Updated endpoint
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];

        setState(() {
          _clinics =
              data.map((json) => AllAvailableOPDModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching OPD clinics: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMore() {
    setState(() {
      _visibleCount += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allFiltered = _clinics.where((clinic) {
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

    final displayedClinics = allFiltered.take(_visibleCount).toList();

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
                      ...displayedClinics.map((clinic) => _buildClinicCard(clinic)),
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
                _visibleCount = 5; // Reset pagination on search
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
                  child: clinic.bannerImage.isNotEmpty
                      ? Image.network(clinic.bannerImage, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholderImage())
                      : _placeholderImage(),
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

  Widget _placeholderImage() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(10), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.business_rounded, color: Color(0xFF1565C0), size: 30),
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

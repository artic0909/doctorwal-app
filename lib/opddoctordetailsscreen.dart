import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ODPDoctorDetailScreen extends StatelessWidget {
  final dynamic opd;
  final dynamic doctor;

  const ODPDoctorDetailScreen({
    super.key,
    required this.opd,
    required this.doctor,
  });

  String _capitalizeWords(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          child: AppBar(
            title: Text(
              _capitalizeWords(doctor['doctor_name'] ?? "Specialist Profile"),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1565C0),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorHeader(),
                _buildDetailsSection(),
                _buildAvailabilitySection(),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // To be defined later as per user request
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                shadowColor: const Color(0xFF1565C0).withAlpha(100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 20),
                  SizedBox(width: 12),
                  Text("BOOK APPOINTMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(15), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Color(0xFF1565C0), size: 50),
          ),
          const SizedBox(height: 15),
          Text(
            _capitalizeWords(doctor['doctor_name'] ?? ""),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 5),
          Text(
            doctor['doctor_specialist'] ?? "Specialist",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF00C853).withAlpha(15), borderRadius: BorderRadius.circular(20)),
            child: Text(
              "Consultation Fee: ₹${doctor['doctor_fees'] ?? '0'}",
              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PROFESSIONAL PROFILE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF90A4AE), letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueGrey[50]!)),
            child: Text(
              doctor['doctor_more'] ?? "No additional information provided.",
              style: const TextStyle(fontSize: 14, color: Color(0xFF455A64), height: 1.6, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final visitDayTimeRaw = doctor['visit_day_time'];
    List<Map<String, dynamic>> visitDayTime = [];

    if (visitDayTimeRaw is String && visitDayTimeRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(visitDayTimeRaw);
        if (decoded is List) {
          visitDayTime = decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (e) {
        debugPrint('Error decoding visit_day_time: $e');
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("OPD AVAILABILITY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF90A4AE), letterSpacing: 1.0)),
          const SizedBox(height: 12),
          if (visitDayTime.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Not Available Currently", style: TextStyle(color: Colors.grey))))
          else
            ...visitDayTime.map((item) => _buildAvailabilityRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(Map<String, dynamic> item) {
    final day = item['day'] ?? '-';
    final start = item['start_time'] ?? '-';
    final end = item['end_time'] ?? '-';

    String formatTime(String timeStr) {
      try {
        final time = DateFormat("HH:mm").parse(timeStr);
        return DateFormat("h:mm a").format(time);
      } catch (e) {
        return timeStr;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blueGrey[50]!)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(10), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 15),
          Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263238))),
          const Spacer(),
          Text(
            "${formatTime(start)} - ${formatTime(end)}",
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1565C0), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

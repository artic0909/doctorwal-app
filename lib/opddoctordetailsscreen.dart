import 'package:demoapp/bookingscreen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ODPDoctorDetailScreen extends StatelessWidget {
  final dynamic opd;
  final dynamic doctor;
  final Map<String, dynamic> userData;

  const ODPDoctorDetailScreen({
    super.key,
    required this.opd,
    required this.doctor,
    required this.userData,
  });

  String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
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
    final docName = doctor['doctor_name'] ?? "Doctor";
    final fees = doctor['doctor_fees']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Sleek Compact Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              // 2. Professional Profile Section
              if ((doctor['doctor_more']?.toString() ?? "").isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withAlpha(15),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.medical_information_outlined, color: Color(0xFF1565C0), size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Professional Background",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E293B).withAlpha(5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            doctor['doctor_more'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Chamber Availability Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withAlpha(15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1565C0), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Chamber Availability",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Availability List
              _buildAvailabilitySliver(context),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom + 90,
                ),
              ),
            ],
          ),

          // Floating Bottom Booking Button
          Positioned(
            bottom: MediaQuery.of(context).viewPadding.bottom + 14,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withAlpha(60),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        type: BookingType.opd,
                        partnerId: doctor['currently_loggedin_partner_id']?.toString() ?? (opd != null ? opd.currentlyLoggedInPartnerId.toString() : ""),
                        clinicName: (opd != null && opd.clinicName != null) ? opd.clinicName : "Clinic",
                        userData: userData,
                        itemId: doctor['id']?.toString(),
                        itemName: docName,
                        itemPrice: fees,
                        schedule: doctor['visit_day_time'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text(
                  "BOOK APPOINTMENT",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final docName = doctor['doctor_name'] ?? "Doctor";
    final fees = doctor['doctor_fees']?.toString() ?? '0';
    final String? banner = doctor['banner'] ?? doctor['doctor_image'] ?? doctor['image'];
    final clinicTitle = (opd != null && opd.clinicName != null && opd.clinicName.toString().isNotEmpty)
        ? opd.clinicName.toString()
        : "OPD Chamber";

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                child: banner != null && banner.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _getImageUrl(banner),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                      )
                    : const Icon(Icons.person_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _capitalizeWords(docName),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capitalizeWords(doctor['doctor_specialist'] ?? "Specialist"),
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("FEES", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    Text(
                      fees.trim().isEmpty || fees == 'null' ? "N/A" : "₹$fees",
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.business_rounded, color: Colors.white.withAlpha(180), size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _capitalizeWords(clinicTitle),
                  style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, color: Color(0xFF86EFAC), size: 13),
              const SizedBox(width: 4),
              const Text(
                "Verified Specialist",
                style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySliver(BuildContext context) {
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
    } else if (visitDayTimeRaw is List) {
      visitDayTime = visitDayTimeRaw.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (visitDayTime.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: Text(
              "No specific chamber hours provided",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = visitDayTime[index];
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withAlpha(5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withAlpha(12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF1565C0), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Chamber Consultation Time",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${formatTime(start)} - ${formatTime(end)}",
                      style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: visitDayTime.length,
        ),
      ),
    );
  }
}

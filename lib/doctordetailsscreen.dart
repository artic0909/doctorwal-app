import 'package:demoapp/Models/all_available_doctors_model.dart';
import 'package:demoapp/bookingscreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final AllAvailableDoctorsModel doctor;
  final Map<String, dynamic> userData; // Added userData

  const DoctorDetailsScreen({super.key, required this.doctor, required this.userData});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Premium Image-Inspired Header
              _buildImageStyleHeader(context),

              // 2. Availability Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: Color(0xFF6A1B9A), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Chamber Availability",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                    ),
                  ],
                ),
              ),

              // 3. Availability List
              Expanded(
                child: _buildAvailabilityList(d.visitDayTime),
              ),
              
              const SizedBox(height: 120), // Bottom spacing
            ],
          ),

          // 4. Sticky Booking Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildBookingButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStyleHeader(BuildContext context) {
    final d = widget.doctor;
    final String docName = d.partnerDoctorName ?? "Dr. Unknown";
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizeWords(docName),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capitalizeWords(d.partnerDoctorSpecialist ?? "Specialist"),
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
              _feesBadge(d.partnerDoctorFees),
            ],
          ),
          const SizedBox(height: 20),
          _headerInfoRow(Icons.work_history_rounded, "Current Designation", d.partnerDoctorDesignation ?? "Doctor"),
          const SizedBox(height: 12),
          _headerInfoRow(Icons.location_on_rounded, "Consultation Address", d.partnerDoctorAddress ?? "Address not provided"),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: _headerActionBtn("CALL", Icons.phone_rounded, () => launchUrl(Uri.parse("tel:${d.partnerDoctorMobile}")))),
              const SizedBox(width: 12),
              Expanded(child: _headerActionBtn("MAP", Icons.near_me_rounded, () async {
                final url = d.partnerDoctorGoogleMapLink ?? "";
                if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feesBadge(String fees) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          const Text("FEES", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900)),
          Text("₹$fees", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _headerInfoRow(IconData icon, String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                _capitalizeWords(val),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerActionBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(40))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityList(List<dynamic>? visitTime) {
    if (visitTime == null || visitTime.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Text("No chamber hours available", style: TextStyle(color: Colors.blueGrey[200], fontSize: 13)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      itemCount: visitTime.length,
      itemBuilder: (context, index) {
        final item = visitTime[index];
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF6A1B9A).withAlpha(10)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF6A1B9A).withAlpha(10), shape: BoxShape.circle),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6A1B9A), size: 16),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF263238))),
                    const SizedBox(height: 2),
                    Text("Session Availability", style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(
                "${formatTime(start)} - ${formatTime(end)}",
                style: const TextStyle(color: Color(0xFF6A1B9A), fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6A1B9A).withAlpha(80), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingScreen(
                  type: BookingType.doctor,
                  partnerId: widget.doctor.currentlyLoggedinPartnerId.toString(),
                  clinicName: widget.doctor.partnerDoctorName ?? "Specialist",
                  userData: widget.userData,
                  itemId: widget.doctor.id.toString(),
                  itemName: widget.doctor.partnerDoctorName,
                  itemPrice: widget.doctor.partnerDoctorFees,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Text(
              "BOOK APPOINTMENT",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
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

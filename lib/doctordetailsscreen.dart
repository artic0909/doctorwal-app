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
                child: _buildAvailabilityList(context, d.visitDayTime),
              ),
            ],
          ),

          // 4. Sticky Booking Button
          Positioned(
            bottom: MediaQuery.of(context).viewPadding.bottom + 16,
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: d.banner != null && d.banner!.isNotEmpty
                      ? Image.network(
                          _getImageUrl(d.banner),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        )
                      : const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
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
                      _capitalizeWords(d.partnerDoctorSpecialist ?? "Specialist"),
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _feesBadge(d.partnerDoctorFees),
            ],
          ),
          const SizedBox(height: 10),
          if ((d.partnerDoctorDesignation ?? "").isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.work_history_rounded, color: Colors.white.withAlpha(200), size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Current Designation: ",
                          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: _capitalizeWords(d.partnerDoctorDesignation ?? "Doctor"),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on_rounded, color: Colors.white.withAlpha(200), size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Consultation Address: ",
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: _capitalizeWords(d.partnerDoctorAddress ?? "Address not provided"),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _headerActionBtn("CALL", Icons.phone_rounded, () => launchUrl(Uri.parse("tel:${d.partnerDoctorMobile}")))),
              const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withAlpha(28), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withAlpha(40))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("FEES", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Text(fees.trim().isEmpty || fees == 'null' ? "N/A" : "₹$fees", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _headerActionBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(28), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withAlpha(40))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityList(BuildContext context, List<dynamic>? visitTime) {
    final dateOnlySchedules = (visitTime ?? []).where((item) {
      if (item is! Map) return false;
      return (item['schedule_type'] == 'date' || item['type'] == 'date') && item['date'] != null;
    }).toList();

    if (dateOnlySchedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Text("No upcoming consultation dates scheduled", style: TextStyle(color: Colors.blueGrey[300], fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }

    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.trim().isEmpty) return '-';
      try {
        final time = DateFormat("HH:mm").parse(timeStr.trim());
        return DateFormat("h:mm a").format(time);
      } catch (e) {
        return timeStr;
      }
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 6, 20, MediaQuery.of(context).viewPadding.bottom + 96),
      itemCount: dateOnlySchedules.length,
      itemBuilder: (context, index) {
        final item = dateOnlySchedules[index];
        final dateStr = item['date']?.toString();
        final parsedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
        final day = item['day'] ?? (parsedDate != null ? DateFormat('EEEE').format(parsedDate) : '-');
        final rawSlots = item['slots'];
        final List<dynamic> slots = (rawSlots is List) ? rawSlots : [];

        final String dayNum = parsedDate != null ? DateFormat('dd').format(parsedDate) : '--';
        final String monthShort = parsedDate != null ? DateFormat('MMM').format(parsedDate).toUpperCase() : '';
        final String fullDateLabel = parsedDate != null ? DateFormat('dd MMM yyyy').format(parsedDate) : (dateStr ?? '-');

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Calendar Badge + Day & Date + Available Pill
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6A1B9A).withAlpha(30)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (monthShort.isNotEmpty)
                            Text(
                              monthShort,
                              style: const TextStyle(
                                color: Color(0xFF6A1B9A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                height: 1.0,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            dayNum,
                            style: const TextStyle(
                              color: Color(0xFF4A148C),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullDateLabel,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Available",
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

              // Slots List (Full-width aligned rows)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    if (slots.isNotEmpty)
                      ...List.generate(slots.length, (sIdx) {
                        final slot = slots[sIdx];
                        final slotId = (slot['id'] ?? '').toString().toLowerCase();
                        final slotName = slot['name'] ??
                            (slotId.isNotEmpty ? slotId[0].toUpperCase() + slotId.substring(1) : 'Slot');
                        final sStart = slot['start_time']?.toString() ?? '';
                        final sEnd = slot['end_time']?.toString() ?? '';
                        final String timeText = sStart.isNotEmpty && sEnd.isNotEmpty
                            ? "${formatTime(sStart)} - ${formatTime(sEnd)}"
                            : (sStart.isNotEmpty ? "From ${formatTime(sStart)}" : "Active");

                        Color iconBg = const Color(0xFFF1F5F9);
                        Color iconColor = const Color(0xFF475569);
                        IconData icon = Icons.access_time_rounded;

                        if (slotId == 'morning') {
                          iconBg = const Color(0xFFFEF3C7);
                          iconColor = const Color(0xFFD97706);
                          icon = Icons.wb_sunny_rounded;
                        } else if (slotId == 'afternoon') {
                          iconBg = const Color(0xFFFFEDD5);
                          iconColor = const Color(0xFFEA580C);
                          icon = Icons.light_mode_rounded;
                        } else if (slotId == 'evening') {
                          iconBg = const Color(0xFFEDE9FE);
                          iconColor = const Color(0xFF6A1B9A);
                          icon = Icons.nights_stay_rounded;
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: sIdx == slots.length - 1 ? 0 : 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: const Color(0xFFE2E8F0).withAlpha(180)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: iconColor, size: 15),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  slotName.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  timeText,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else if (item['start_time'] != null || item['end_time'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFE2E8F0).withAlpha(180)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.access_time_rounded, color: Color(0xFF6A1B9A), size: 15),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Consultation Hours",
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                "${formatTime(item['start_time'])} - ${formatTime(item['end_time'])}",
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
                  clinicRegistrationType: widget.doctor.clinicRegistrationType,
                  schedule: widget.doctor.visitDayTime,
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
}

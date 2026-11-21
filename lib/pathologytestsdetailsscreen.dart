import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:demoapp/bookingscreen.dart';

class PathologyTestsDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> test;
  final Map<String, dynamic> userData;
  final String clinicName;

  late final String testName;
  late final String testType;
  late final String testPrice;
  late final List<Map<String, dynamic>> testDayTime;

  PathologyTestsDetailsScreen({
    super.key,
    required this.test,
    required this.userData,
    required this.clinicName,
  }) {
    testName = test['test_name'] ?? 'N/A';
    testType = test['test_type'] ?? 'N/A';
    testPrice = test['test_price']?.toString() ?? '0';

    final rawDayTime = test['test_day_time'];
    if (rawDayTime is List) {
      testDayTime = rawDayTime.cast<Map<String, dynamic>>();
    } else if (rawDayTime is String && rawDayTime.isNotEmpty) {
      try {
        final decoded = json.decode(rawDayTime);
        if (decoded is List) {
          testDayTime = decoded.cast<Map<String, dynamic>>();
        } else {
          testDayTime = [];
        }
      } catch (e) {
        testDayTime = [];
      }
    } else {
      testDayTime = [];
    }
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Sleek Compact Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              // 2. Schedule Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withAlpha(15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2E7D32), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Test Schedule & Operating Hours",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Schedule List
              if (testDayTime.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withAlpha(12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.schedule_rounded, color: Color(0xFF2E7D32), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Standard Lab Operating Hours",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Available daily for sample collection and testing",
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = testDayTime[index];
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
                                  color: const Color(0xFF2E7D32).withAlpha(12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2E7D32), size: 16),
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
                                      "Lab Operating Hours",
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withAlpha(12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${formatTime(start)} - ${formatTime(end)}",
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: testDayTime.length,
                    ),
                  ),
                ),

              // 4. Test Highlights / Inclusions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withAlpha(15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.medical_services_outlined, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Test Highlights & Inclusions",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildHighlightRow(Icons.verified_outlined, "NABL Certified Laboratory Testing", "High accuracy automated processing"),
                      const Divider(height: 18, color: Color(0xFFF1F5F9)),
                      _buildHighlightRow(Icons.description_outlined, "Digital Smart Reports", "Delivered directly into your app account"),
                      const Divider(height: 18, color: Color(0xFFF1F5F9)),
                      _buildHighlightRow(Icons.home_outlined, "Lab & Home Sample Collection", "Flexible collection options available"),
                    ],
                  ),
                ),
              ),

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
                    color: const Color(0xFF2E7D32).withAlpha(60),
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
                        type: BookingType.pathology,
                        partnerId: test['currently_loggedin_partner_id']?.toString() ?? "",
                        clinicName: clinicName,
                        userData: userData,
                        itemId: test['id']?.toString(),
                        itemName: testName,
                        itemPrice: testPrice,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text(
                  "BOOK THIS TEST",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
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
                child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _capitalizeWords(testName),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinicName.isNotEmpty ? clinicName : "Certified Pathology Partner",
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w600),
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
                    const Text("PRICE", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    Text(
                      "₹$testPrice",
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
              Icon(Icons.category_rounded, color: Colors.white.withAlpha(180), size: 13),
              const SizedBox(width: 4),
              Text(
                "Type: ${_capitalizeWords(testType)}",
                style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, color: Color(0xFF86EFAC), size: 13),
              const SizedBox(width: 4),
              const Text(
                "Certified Diagnostic Test",
                style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

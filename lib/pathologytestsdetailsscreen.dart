import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:demoapp/bookingscreen.dart';

class PathologyTestsDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> test;
  final Map<String, dynamic> userData; // Added userData

  // Parse everything up front into final fields
  late final String clinicName;
  late final String testName;
  late final String testType;
  late final String testPrice;
  late final List<Map<String, dynamic>> testDayTime;

  PathologyTestsDetailsScreen({super.key, required this.test, required this.userData}) {
    clinicName = test['clinic_name'] ?? 'N/A';
    testName = test['test_name'] ?? 'N/A';
    testType = test['test_type'] ?? 'N/A';
    testPrice = test['test_price']?.toString() ?? '0';
    testDayTime =
        (test['test_day_time'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Premium Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              // 2. Test Details Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withAlpha(8), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DIAGNOSTIC TEST INFO", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      const SizedBox(height: 20),
                      _infoRow(Icons.biotech_rounded, "Test Name", testName),
                      _infoRow(Icons.category_rounded, "Test Type", testType),
                      _infoRow(Icons.local_hospital_rounded, "Laboratory", clinicName),
                      const Divider(height: 30),
                      Row(
                        children: [
                          const Text("Estimated Price", style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text("₹$testPrice", style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Availability Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withAlpha(15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.schedule_rounded, color: Color(0xFF2E7D32), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text("Test Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
                    ],
                  ),
                ),
              ),

              // 4. Availability List
              if (testDayTime.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text("No scheduling data available", style: TextStyle(color: Colors.blueGrey[200], fontSize: 14)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFF2E7D32).withAlpha(10)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFF2E7D32).withAlpha(10), shape: BoxShape.circle),
                                child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2E7D32), size: 16),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(day, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF263238))),
                                    const SizedBox(height: 2),
                                    Text("Lab Operating Hours", style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Text(
                                "${formatTime(start)} - ${formatTime(end)}",
                                style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: testDayTime.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                shadowColor: const Color(0xFF2E7D32).withAlpha(100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 20),
                  const SizedBox(width: 12),
                  const Text("BOOK THIS TEST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 30),
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
          const SizedBox(height: 20),
          const Text(
            "Test Details",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 5),
          Text(
            "Complete information and lab scheduling",
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey[200]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_capitalizeWords(val), style: const TextStyle(color: Color(0xFF263238), fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
  }
}

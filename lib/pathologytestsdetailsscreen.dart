import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PathologyTestsDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> test;

  // Parse everything up front into final fields
  late final String clinicName;
  late final String testName;
  late final String testType;
  late final String testPrice;
  late final List<Map<String, dynamic>> testDayTime;

  PathologyTestsDetailsScreen({super.key, required this.test}) {
    clinicName = test['clinic_name'] ?? 'N/A';
    testName = test['test_name'] ?? 'N/A';
    testType = test['test_type'] ?? 'N/A';
    // your JSON uses `test_price`
    testPrice = test['test_price']?.toString() ?? '0';
    // JSON uses a list under `test_day_time`
    testDayTime =
        (test['test_day_time'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'Test Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[900],
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _clinicTestDetailsCard(),
            const SizedBox(height: 20),
            const Text(
              'Availability',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _availabilityTable(),
          ],
        ),
      ),
    );
  }

  Widget _clinicTestDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.grey.withAlpha(76),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Test Name Row
            Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.purple, size: 24),
                const SizedBox(width: 10),
                const Text(
                  "Test Name:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    testName,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Test Type Row
            Row(
              children: [
                const Icon(Icons.science, color: Colors.redAccent, size: 24),
                const SizedBox(width: 10),
                const Text(
                  "Test Type:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    testType,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _availabilityTable() {
    if (testDayTime.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No Availability Data Found",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.orange[100]),
              columnSpacing: 20,
              horizontalMargin: 16,
              border: TableBorder.all(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Day',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Time',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: List.generate(testDayTime.length, (index) {
                final item = testDayTime[index];
                final start = item['start_time'] ?? '';
                final end = item['end_time'] ?? '';
                String formatTime(String timeStr) {
                  try {
                    final time = DateFormat("HH:mm").parse(timeStr);
                    return DateFormat("h:mm a").format(time);
                  } catch (e) {
                    return timeStr;
                  }
                }

                final time = '${formatTime(start)} - ${formatTime(end)}';

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(item['day'] ?? '-')),
                    DataCell(Text(time)),
                    DataCell(Text('₹$testPrice')),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

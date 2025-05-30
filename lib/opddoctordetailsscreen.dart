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

  @override
  Widget build(BuildContext context) {
    String capitalizeWords(String input) {
      return input
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

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
            title: Text(
              capitalizeWords(doctor['doctor_name'] ?? "Dr. Doctor Name"),
              style: const TextStyle(
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
            _doctorDetailsCard(),
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
            _availabilityTable(doctor),
          ],
        ),
      ),
    );
  }

  Widget _doctorDetailsCard() {
    String capitalizeWords(String input) {
      return input
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.grey.withAlpha(76),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 24),
                const SizedBox(width: 10),
                const Text(
                  "Doctor Name:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    capitalizeWords(doctor['doctor_name'] ?? "Dr. Doctor Name"),
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.medical_information,
                  color: Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Specialization:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    doctor['doctor_specialist'] ?? "Not Defined",
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.medical_services,
                  color: Color.fromARGB(255, 199, 131, 255),
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  "More Details:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    doctor['doctor_more'] ?? "Not Defined",
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.currency_rupee_rounded,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Fees:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    doctor['doctor_fees'] ?? "Not Defined",
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityTable(Map<String, dynamic> doctor) {
    final visitDayTimeRaw = doctor['visit_day_time'];

    List<Map<String, dynamic>> visitDayTime = [];

    if (visitDayTimeRaw is String && visitDayTimeRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(visitDayTimeRaw);
        if (decoded is List) {
          visitDayTime =
              decoded.map<Map<String, dynamic>>((e) {
                if (e is Map<String, dynamic>) {
                  return e;
                } else if (e is Map) {
                  return Map<String, dynamic>.from(e);
                }
                return <String, dynamic>{};
              }).toList();
        }
      } catch (e) {
        print('Error decoding visit_day_time: $e');
      }
    }

    if (visitDayTime.isEmpty) {
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
              ],
              rows: List.generate(visitDayTime.length, (index) {
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

                final time = '${formatTime(start)} - ${formatTime(end)}';

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(day)),
                    DataCell(Text(time)),
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

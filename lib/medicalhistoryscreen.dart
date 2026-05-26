import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/addmedicalrecordscreen.dart';
import 'package:demoapp/viewmedicalrecordscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final int initialTabIndex; // 0 for Reports, 1 for Prescriptions

  const MedicalHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  List<dynamic> _reports = [];
  List<dynamic> _prescriptions = [];
  List<dynamic> _systemPrescriptions = [];
  bool _isLoading = true;
  bool _isSystemPrescriptionView = false;

  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  List<dynamic> _applyFilter(List<dynamic> items) {
    if (_fromDate != null || _toDate != null) {
      return items.where((v) {
        DateTime dt = DateTime.parse(v['date_of_report']).toLocal();
        bool afterFrom = _fromDate == null || dt.isAfter(_fromDate!) || DateUtils.isSameDay(dt, _fromDate!);
        bool beforeTo = _toDate == null || dt.isBefore(_toDate!) || DateUtils.isSameDay(dt, _toDate!);
        return afterFrom && beforeTo;
      }).toList();
    }
    // Default: latest 10
    return items.take(10).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchData();
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final reportsRes = await _apiService.getMedicalHistory(type: 'report');
      final prescriptionsRes = await _apiService.getMedicalHistory(type: 'prescription');
      final sysPresRes = await _apiService.getMedicalHistory(type: 'system-prescription');

      if (mounted) {
        // Sort descending by date
        final List reportsList = reportsRes['data'] ?? [];
        reportsList.sort((a, b) => (b['date_of_report'] ?? "").compareTo(a['date_of_report'] ?? ""));
        
        final List prescriptionsList = prescriptionsRes['data'] ?? [];
        prescriptionsList.sort((a, b) => (b['date_of_report'] ?? "").compareTo(a['date_of_report'] ?? ""));

        final List sysPresList = sysPresRes['data'] ?? [];
        sysPresList.sort((a, b) => (b['created_at'] ?? "").compareTo(a['created_at'] ?? ""));

        setState(() {
          _reports = reportsList;
          _prescriptions = prescriptionsList;
          _systemPrescriptions = sysPresList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching medical history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("Are you sure you want to permanently remove this medical record?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await _apiService.deleteMedicalHistory(id);
      if (res['status'] == true) {
        _fetchData();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Medical History",
          style: TextStyle(color: Color(0xFF263238), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.blueGrey[300],
          indicatorColor: const Color(0xFF1565C0),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "REPORTS"),
            Tab(text: "PRESCRIPTIONS"),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_applyFilter(_reports), 'report'),
                    _isSystemPrescriptionView 
                        ? _buildSystemList(_applyFilter(_systemPrescriptions))
                        : _buildList(_applyFilter(_prescriptions), 'prescription'),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddMedicalRecordScreen(initialType: _tabController.index == 0 ? 'report' : 'prescription')),
        ).then((v) => v == true ? _fetchData() : null),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return _buildEmptyState(type);
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildRecordCard(items[index]),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    bool isFiltered = _fromDate != null || _toDate != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isFiltered ? Icons.filter_list_off_rounded : (type == 'report' ? Icons.assignment_outlined : Icons.medication_outlined), size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 15),
          Text(
            isFiltered ? "No records found for this range" : "No ${type}s found", 
            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: _clearFilter, child: const Text("Clear Filters", style: TextStyle(color: Color(0xFF1565C0)))),
          ]
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  _fromDate == null ? "From Date" : DateFormat('dd/MM/yy').format(_fromDate!),
                  Icons.calendar_today_rounded,
                  () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateButton(
                  _toDate == null ? "To Date" : DateFormat('dd/MM/yy').format(_toDate!),
                  Icons.event_available_rounded,
                  () => _selectDate(context, false),
                ),
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearFilter,
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                  style: IconButton.styleFrom(backgroundColor: Colors.red[50]),
                ),
              ],
            ],
          ),
          if (_fromDate == null && _toDate == null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text("Showing latest 10 records by default", style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _tabController.index == 1 
              ? Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isSystemPrescriptionView = false);
                            _fetchData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSystemPrescriptionView ? const Color(0xFF1565C0) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF1565C0).withAlpha(100)),
                            ),
                            alignment: Alignment.center,
                            child: Text("Uploaded", style: TextStyle(color: !_isSystemPrescriptionView ? Colors.white : const Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isSystemPrescriptionView = true);
                            _fetchData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSystemPrescriptionView ? const Color(0xFF00897B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00897B).withAlpha(100)),
                            ),
                            alignment: Alignment.center,
                            child: Text("Generated", style: TextStyle(color: _isSystemPrescriptionView ? Colors.white : const Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1565C0).withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF263238)))),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemList(List<dynamic> items) {
    if (items.isEmpty) {
      return _buildEmptyState('system-prescription');
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          String dateStr = "";
          try {
            DateTime dt = DateTime.parse(items[index]['created_at'] ?? items[index]['prescription_date'] ?? "").toLocal();
            dateStr = DateFormat('yyyy-MM-dd').format(dt);
          } catch(e) {
            dateStr = items[index]['prescription_date'] ?? "";
          }
          return _buildExpandingSystemPrescriptionCard(items[index], dateStr);
        },
      ),
    );
  }

  Widget _buildRecordCard(dynamic record) {
    int imgCount = (record['images'] as List?)?.length ?? 0;
    String dateStr = "";
    try {
      String targetDate = (record['partner_id'] != null && record['created_at'] != null) 
          ? record['created_at'] 
          : record['date_of_report'];
      DateTime dt = DateTime.parse(targetDate).toLocal();
      if (record['partner_id'] != null) {
        dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } else {
        dateStr = DateFormat('dd MMM yyyy').format(dt);
      }
    } catch (e) {
      dateStr = record['date_of_report'] ?? "";
    }

    String? clinicStr;
    String? doctorStr;
    String regType = (record['registration_type'] ?? "").toString().toLowerCase();

    if (record['partner_id'] != null) {
      if (regType == 'opd & pathology' || regType == 'opd') {
        if (record['clinic_name'] != null) clinicStr = "Clinic: ${record['clinic_name']}";
        if (record['doctor_name'] != null) {
          doctorStr = "Doctor: ${record['doctor_name']}";
          if (record['doctor_specialist'] != null) doctorStr += " (${record['doctor_specialist']})";
        }
      } else if (regType == 'pathology') {
        if (record['clinic_name'] != null) clinicStr = "Clinic: ${record['clinic_name']}";
      } else if (regType == 'doctor') {
        if (record['doctor_name'] != null) {
          doctorStr = "Doctor: ${record['doctor_name']}";
          if (record['doctor_specialist'] != null) doctorStr += " (${record['doctor_specialist']})";
        }
      } else {
        if (record['doctor_name'] != null && record['doctor_name'].toString().isNotEmpty) doctorStr = "Doctor: ${record['doctor_name']}";
        if (record['clinic_name'] != null && record['clinic_name'].toString().isNotEmpty) clinicStr = "Clinic: ${record['clinic_name']}";
      }
    } else {
      if (record['doctor_name'] != null && record['doctor_name'].toString().isNotEmpty) doctorStr = "Doctor: ${record['doctor_name']}";
      if (record['clinic_name'] != null && record['clinic_name'].toString().isNotEmpty) clinicStr = "Clinic: ${record['clinic_name']}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewMedicalRecordScreen(recordId: record['id'])),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: const Color(0xFF1565C0).withAlpha(12), borderRadius: BorderRadius.circular(15)),
                 child: Icon(record['type'] == 'report' ? Icons.assignment_rounded : Icons.medication_rounded, color: const Color(0xFF1565C0), size: 24),
               ),
               const SizedBox(width: 15),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(record['heading'] ?? "Untitled Record", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
                     const SizedBox(height: 4),
                     if (doctorStr != null) Text(doctorStr, style: TextStyle(color: Colors.blueGrey[600], fontSize: 11)),
                     if (clinicStr != null) Text(clinicStr, style: TextStyle(color: Colors.blueGrey[600], fontSize: 11)),
                     const SizedBox(height: 2),
                     Text(dateStr, style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined, size: 12, color: Colors.blueGrey[300]),
                          const SizedBox(width: 4),
                          Text("$imgCount", style: TextStyle(color: Colors.blueGrey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (record['partner_id'] == null)
                      Row(
                        children: [
                          _actionIcon(Icons.edit_rounded, Colors.blue, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddMedicalRecordScreen(recordData: record)),
                            ).then((v) => v == true ? _fetchData() : null);
                          }),
                          const SizedBox(width: 8),
                          _actionIcon(Icons.delete_outline_rounded, Colors.red, () => _deleteRecord(record['id'])),
                        ],
                      ),
                 ],
               ),
             ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  void _openWebPage(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      debugPrint("Could not launch $url");
    }
  }

  Widget _buildExpandingSystemPrescriptionCard(dynamic record, String dateStr) {
    String? clinicStr;
    String? doctorStr;
    String regType = (record['registration_type'] ?? "").toString().toLowerCase();

    if (regType == 'opd & pathology' || regType == 'opd') {
      if (record['clinic_name'] != null) clinicStr = "Clinic: ${record['clinic_name']}";
      if (record['doctor_name'] != null) {
        doctorStr = "Prescribed by ${record['doctor_name']}";
        if (record['doctor_specialist'] != null) doctorStr += " (${record['doctor_specialist']})";
      }
    } else if (regType == 'pathology') {
      if (record['clinic_name'] != null) clinicStr = "Clinic: ${record['clinic_name']}";
    } else if (regType == 'doctor') {
      if (record['doctor_name'] != null) {
        doctorStr = "Prescribed by ${record['doctor_name']}";
        if (record['doctor_specialist'] != null) doctorStr += " (${record['doctor_specialist']})";
      }
    } else {
      if (record['doctor_name'] != null && record['doctor_name'].toString().isNotEmpty) doctorStr = "Prescribed by ${record['doctor_name']}";
      if (record['clinic_name'] != null && record['clinic_name'].toString().isNotEmpty) clinicStr = "Clinic: ${record['clinic_name']}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueGrey.withAlpha(30)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("PRESCRIPTION", style: TextStyle(color: Color(0xFF00897B), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text(dateStr, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text(record['heading'] ?? "Prescription", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
              const SizedBox(height: 4),
              if (doctorStr != null)
                Text(doctorStr, style: TextStyle(color: Colors.blueGrey[600], fontSize: 13)),
              if (clinicStr != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(clinicStr, style: TextStyle(color: Colors.blueGrey[600], fontSize: 13)),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View PDF Button
                  InkWell(
                    onTap: () {
                      final url = 'https://www.doctorwala.info/share/prescription/${record['id']}/view';
                      _openWebPage(url);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text("View Prescription PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Vitals row
                  Row(
                    children: [
                      _buildVitalBox(Icons.calendar_today_rounded, "Age", record['user_age'] ?? 'N/A'),
                      const SizedBox(width: 10),
                      _buildVitalBox(Icons.face_rounded, "Gender", record['user_gender'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildVitalBox(Icons.water_drop_rounded, "Blood", record['blood_group'] ?? 'N/A'),
                  
                  const SizedBox(height: 20),
                  
                  // Symptoms
                  if (record['symptoms'] != null && (record['symptoms'] as List).isNotEmpty) ...[
                    _buildSectionHeading("SYMPTOMS / COMPLAINTS"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (record['symptoms'] as List).map<Widget>((symp) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey.withAlpha(50)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(symp.toString(), style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Medicines
                  if (record['medicines'] != null && (record['medicines'] as List).isNotEmpty) ...[
                    _buildSectionHeading("MEDICINES / RX"),
                    ...(record['medicines'] as List).map<Widget>((med) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Color(0xFF1565C0)),
                                const SizedBox(width: 6),
                                Expanded(child: Text(med['name'] ?? "", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)))),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 4),
                              child: Text(
                                "Frequency: ${med['frequency'] ?? 'N/A'} | Relation: ${med['relation'] ?? 'N/A'} | Duration: ${med['duration'] ?? 'N/A'}",
                                style: TextStyle(color: Colors.blueGrey[600], fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 10),
                  ],

                  // Tests
                  if (record['recommended_tests'] != null && (record['recommended_tests'] as List).isNotEmpty) ...[
                    _buildSectionHeading("RECOMMENDED TESTS"),
                    ...(record['recommended_tests'] as List).map<Widget>((test) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Color(0xFF7E57C2)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(test.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7E57C2)))),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey[300], letterSpacing: 1)),
      ),
    );
  }

  Widget _buildVitalBox(IconData icon, String title, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey.withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00897B), size: 16),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

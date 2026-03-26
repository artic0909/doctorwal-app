import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/addmedicalrecordscreen.dart';
import 'package:demoapp/viewmedicalrecordscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final reportsRes = await _apiService.getMedicalHistory(type: 'report');
      final prescriptionsRes = await _apiService.getMedicalHistory(type: 'prescription');

      if (mounted) {
        setState(() {
          _reports = reportsRes['data'] ?? [];
          _prescriptions = prescriptionsRes['data'] ?? [];
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_reports, 'report'),
              _buildList(_prescriptions, 'prescription'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == 'report' ? Icons.assignment_outlined : Icons.medication_outlined, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 15),
          Text("No ${type}s found", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(dynamic record) {
    int imgCount = (record['images'] as List?)?.length ?? 0;
    String dateStr = "";
    try {
      DateTime dt = DateTime.parse(record['date_of_report']).toLocal();
      dateStr = DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      dateStr = record['date_of_report'] ?? "";
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
}

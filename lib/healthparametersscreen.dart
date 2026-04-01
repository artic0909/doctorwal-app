import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/addvitalscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HealthParametersScreen extends StatefulWidget {
  const HealthParametersScreen({super.key});

  @override
  State<HealthParametersScreen> createState() => _HealthParametersScreenState();
}

class _HealthParametersScreenState extends State<HealthParametersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _vitals = [];
  bool _isLoading = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fetchVitals();
  }

  Future<void> _fetchVitals() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getVitals();
      if (response['status'] == true) {
        setState(() {
          _vitals = response['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching vitals: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVital(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to remove this vital record?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.deleteVitals(id);
        if (response['status'] == true) {
          _fetchVitals();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted successfully")));
          }
        }
      } catch (e) {
        debugPrint("Error deleting vital: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

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

  List<dynamic> get _filteredVitals {
    List<dynamic> list = List.from(_vitals);
    if (_fromDate != null || _toDate != null) {
      return list.where((v) {
        DateTime dt = DateTime.parse(v['created_at']).toLocal();
        bool afterFrom = _fromDate == null || dt.isAfter(_fromDate!) || DateUtils.isSameDay(dt, _fromDate!);
        bool beforeTo = _toDate == null || dt.isBefore(_toDate!) || DateUtils.isSameDay(dt, _toDate!);
        return afterFrom && beforeTo;
      }).toList();
    }
    // Default: latest 10
    return list.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVitals = _filteredVitals;
    bool isFiltered = _fromDate != null || _toDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Health Parameter Records",
          style: TextStyle(color: Color(0xFF263238), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1565C0)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddVitalScreen()),
            ).then((value) => value == true ? _fetchVitals() : null),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
              : filteredVitals.isEmpty 
                ? _buildEmptyState(isFiltered)
                : RefreshIndicator(
                    onRefresh: _fetchVitals,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: filteredVitals.length,
                      itemBuilder: (context, index) {
                        final vital = filteredVitals[index];
                        bool isLatest = index == 0 && !isFiltered;
                        return _buildVitalCard(vital, isLatest);
                      },
                    ),
                  ),
          ),
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

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isFiltered ? Icons.filter_list_off_rounded : Icons.monitor_heart_outlined, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          Text(
            isFiltered ? "No records found for this range" : "No vitals recorded yet",
            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: _clearFilter, child: const Text("Clear Filters", style: TextStyle(color: Color(0xFF1565C0)))),
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVitalScreen()),
              ).then((value) => value == true ? _fetchVitals() : null),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              child: const Text("Log Your First Vitals", style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalCard(dynamic vital, bool isLatest) {
    String dateStr = "";
    try {
      DateTime dt = DateTime.parse(vital['created_at']).toLocal();
      dateStr = DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    } catch (e) {
      dateStr = "Recent Entry";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isLatest ? Border.all(color: const Color(0xFF1565C0).withAlpha(30), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: (isLatest ? const Color(0xFF1565C0) : Colors.black).withAlpha(isLatest ? 15 : 8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isLatest) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("LATEST", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildActionBtn(Icons.edit_note_rounded, Colors.blue, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddVitalScreen(vitalData: vital)),
                      ).then((value) => value == true ? _fetchVitals() : null);
                    }),
                    const SizedBox(width: 4),
                    _buildActionBtn(Icons.delete_sweep_rounded, Colors.red, () => _deleteVital(vital['id'])),
                  ],
                ),
              ],
            ),
          ),
          
          // Data Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildParamItem(Icons.favorite_rounded, "Pulse", "${vital['heart_rate'] ?? '--'}", Colors.red),
                _buildParamItem(Icons.speed_rounded, "BP", "${vital['blood_pressure'] ?? '--'}", Colors.blue),
                _buildParamItem(Icons.thermostat_rounded, "Temp", "${vital['temparature'] ?? '--'}°", Colors.orange),
                _buildParamItem(Icons.bloodtype_rounded, "SpO2", "${vital['spo'] ?? '--'}%", Colors.teal),
                _buildParamItem(Icons.opacity_rounded, "Sugar", "${vital['blood_sugar'] ?? '--'}", Colors.deepPurple),
                _buildParamItem(Icons.height_rounded, "Height", "${vital['height'] ?? '--'}cm", Colors.indigo),
                _buildParamItem(Icons.monitor_weight_rounded, "Weight", "${vital['weight'] ?? '--'}kg", Colors.brown),
                _buildParamItem(Icons.calculate_rounded, "BMI", "${vital['bmi'] ?? '--'}", Colors.green),
                _buildParamItem(Icons.bloodtype_outlined, "Group", "${vital['blood_group'] ?? '--'}", Colors.pink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }

  Widget _buildParamItem(IconData icon, String label, String value, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: themeColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: themeColor),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

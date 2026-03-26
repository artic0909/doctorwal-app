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

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
        : _vitals.isEmpty 
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchVitals,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: _vitals.length,
                itemBuilder: (context, index) {
                  final vital = _vitals[index];
                  bool isLatest = index == 0;
                  return _buildVitalCard(vital, isLatest);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          const Text("No vitals recorded yet", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isLatest ? Border.all(color: const Color(0xFF1565C0).withAlpha(51), width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isLatest) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6)),
                            child: const Text("LATEST", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(dateStr, style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        _buildActionBtn(Icons.edit_rounded, Colors.blue, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddVitalScreen(vitalData: vital)),
                          ).then((value) => value == true ? _fetchVitals() : null);
                        }),
                        const SizedBox(width: 8),
                        _buildActionBtn(Icons.delete_outline_rounded, Colors.red, () => _deleteVital(vital['id'])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildParamItem(Icons.favorite_rounded, "Pulse", "${vital['heart_rate'] ?? '--'}"),
                    _buildParamItem(Icons.speed_rounded, "BP", "${vital['blood_pressure'] ?? '--'}"),
                    _buildParamItem(Icons.thermostat_rounded, "Temp", "${vital['temparature'] ?? '--'}"),
                    _buildParamItem(Icons.bloodtype_outlined, "SpO2", "${vital['spo'] ?? '--'}%"),
                    _buildParamItem(Icons.opacity_rounded, "Sugar", "${vital['blood_sugar'] ?? '--'}"),
                    _buildParamItem(Icons.calculate_rounded, "BMI", "${vital['bmi'] ?? '--'}"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildParamItem(IconData icon, String label, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) / 3,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF1565C0)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 8, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Color(0xFF263238), fontSize: 11, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

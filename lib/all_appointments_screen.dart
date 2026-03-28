import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/Models/appointment_model.dart';
import 'package:lottie/lottie.dart';

class AllAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AllAppointmentsScreen({super.key, required this.userData});

  @override
  State<AllAppointmentsScreen> createState() => _AllAppointmentsScreenState();
}

class _AllAppointmentsScreenState extends State<AllAppointmentsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  List<AppointmentModel> _appointments = [];
  String _errorMessage = '';

  final List<String> _statuses = ['Upcoming', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final status = _statuses[_tabController.index];
      final response = await _apiService.getAppointmentsByStatus(status);
      
      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _appointments = data.map((json) => AppointmentModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load appointments';
          _isLoading = false;
        });
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        msg = "Dio Error: ${e.response?.statusCode} - ${e.response?.data}";
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(int id, String action) async {
    // Show confirmation dialog
    bool confirm = await _showConfirmationDialog(action);
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;
      if (action == 'Complete') {
        response = await _apiService.markAppointmentAsCompleted(id);
      } else if (action == 'Cancel') {
        response = await _apiService.cancelAppointment(id);
      } else {
        // Edit/Delete placeholders
        _showSnackBar("Feature coming soon!");
        setState(() => _isLoading = false);
        return;
      }

      if (response['status'] == true) {
        _showSnackBar("Appointment $action successfully!");
        _fetchAppointments(); // Refresh list
      } else {
        _showSnackBar(response['message'] ?? "Action failed");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar("An error occurred");
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirm $action", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to $action this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'Cancel' ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Yes, $action", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("My Appointments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _statuses.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: _isLoading 
        ? Center(child: Lottie.asset('assets/animations/success.json', width: 100, height: 100)) 
        : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _appointments.isEmpty
            ? _buildEmptyView()
            : _buildAppointmentList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: Colors.blueGrey)),
          TextButton(onPressed: _fetchAppointments, child: const Text("Try Again")),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, color: Colors.blueGrey, size: 60),
          const SizedBox(height: 16),
          Text("No ${_statuses[_tabController.index].toLowerCase()} appointments found.", style: const TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildAppointmentList() {
    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final item = _appointments[index];
          return _buildAppointmentCard(item);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel item) {
    final statusColor = _getStatusColor(item.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(15)),
                  child: Icon(_getTypeIcon(item.clinicType), color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.clinicType?.toUpperCase() ?? "APPOINTMENT",
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          _buildStatusBadge(item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getClinicName(item),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                      ),
                      const SizedBox(height: 4),
                      _detailRow(Icons.location_on_outlined, "Location", _getClinicAddress(item)),
                      const SizedBox(height: 8),
                      if (item.doctorId != null)
                        _detailRow(Icons.person_outline, "Doctor", item.doctor?['doctor_name'] ?? "Specialist"),
                      if (item.testId != null)
                        _detailRow(Icons.biotech_outlined, "Test", item.test?['test_name'] ?? "Diagnostic Test"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _detailRow(Icons.calendar_today_outlined, "Date", item.bookingDate ?? "N/A")),
                          const SizedBox(width: 10),
                          Expanded(child: _detailRow(Icons.access_time_rounded, "Time", _formatTime(item.bookingTime))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (item.status == 'Upcoming') ...[
                  _actionButton(Icons.check_circle_outline, "Complete", Colors.green, () => _handleAction(item.id, 'Complete')),
                  _actionButton(Icons.cancel_outlined, "Cancel", Colors.red, () => _handleAction(item.id, 'Cancel')),
                ],
               
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: Colors.blueGrey[300]),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: TextStyle(fontSize: 12, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF455A64)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status?.toUpperCase() ?? "UNKNOWN",
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Upcoming': return Colors.orange[700]!;
      case 'Completed': return Colors.green[700]!;
      case 'Cancelled': return Colors.red[700]!;
      default: return Colors.blueGrey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'OPD': return Icons.local_hospital_rounded;
      case 'Pathology': return Icons.biotech_rounded;
      case 'Doctor': return Icons.person_rounded;
      default: return Icons.calendar_today_rounded;
    }
  }

  String _getClinicName(AppointmentModel item) {
    String? name;
    if (item.clinicType == 'OPD') name = item.opdContact?['clinic_name'];
    else if (item.clinicType == 'Pathology') name = item.pathologyContact?['clinic_name'];
    else if (item.clinicType == 'Doctor') name = item.doctorContact?['partner_doctor_name'];
    
    return name ?? item.clinicName ?? "Unknown Clinic";
  }

  String _getClinicAddress(AppointmentModel item) {
    String? address;
    if (item.clinicType == 'OPD') address = item.opdContact?['clinic_address'];
    else if (item.clinicType == 'Pathology') address = item.pathologyContact?['clinic_address']; // If address missing, name is better than null
    else if (item.clinicType == 'Doctor') address = item.doctorContact?['partner_doctor_address'];

    return address ?? "Address not provided";
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "N/A";
    try {
      final time = DateFormat("HH:mm:ss").parse(timeStr);
      return DateFormat("h:mm a").format(time);
    } catch (e) {
      return timeStr;
    }
  }
}

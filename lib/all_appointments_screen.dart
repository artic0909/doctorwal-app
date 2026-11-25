import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/Models/appointment_model.dart';
import 'package:demoapp/screens/video_call/video_call_screen.dart';
import 'package:demoapp/widgets/skeleton_loader.dart';

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

  Future<void> _startVideoCall(AppointmentModel item) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B9AAA)),
      ),
    );

    Map<String, dynamic>? response;
    try {
      response = await _apiService.getVideoCallToken(item.id);
    } catch (e) {
      debugPrint("Error fetching video call token: $e");
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Safely dismiss only the loading dialog
      }
    }

    if (response == null) {
      _showSnackBar('Failed to connect to video session.');
      return;
    }

    if (response['status'] == true && response['data'] != null) {
      final data = response['data'];
      final appId = data['app_id']?.toString() ?? '';
      final channel = data['channel']?.toString() ?? '';
      final token = data['token']?.toString() ?? '';
      final uid = int.tryParse(data['uid'].toString()) ?? 0;
      final doctorName = data['doctor_name']?.toString() ?? item.clinicName ?? 'Doctor';

      if (appId.isEmpty || channel.isEmpty || token.isEmpty) {
        _showSnackBar('Invalid video call credentials received from server.');
        return;
      }

      if (mounted) {
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              appId: appId,
              channelName: channel,
              token: token,
              uid: uid,
              appointmentId: item.id,
              participantName: doctorName,
              role: 'patient',
            ),
          ),
        );
        if (mounted) {
          _fetchAppointments(); // Refresh on return
        }
      }
    } else {
      _showSnackBar(response['message'] ?? 'Unable to join video call at this time.');
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
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'Complete' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "My Appointments",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: _isLoading
          ? const AppointmentsSkeleton()
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _appointments.isEmpty
                  ? _buildEmptyView()
                  : _buildAppointmentList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
          Text(
            "No ${_statuses[_tabController.index].toLowerCase()} appointments found.",
            style: const TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList() {
    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 80,
        ),
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
    final bool isUpcoming = item.status == 'Upcoming' || item.status == 'Confirmed' || item.status == 'Pending' || item.status == null || item.status == '';
    final bool isVideo = item.isVideoCall;
    final bool windowOpen = item.isWindowOpen();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 4)),
          BoxShadow(color: statusColor.withAlpha(10), blurRadius: 5, spreadRadius: -2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAppointmentDetailsModal(item),
            child: Column(
              children: [
                // 1. Highlighted Header (Date & Time) at Top
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: statusColor.withAlpha(15),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        item.bookingDate ?? "N/A",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: statusColor),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(item.bookingTime),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: statusColor),
                      ),
                    ],
                  ),
                ),

                // 2. Compact Main Summary (Tap card for full details)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_getTypeIcon(item.clinicType), color: statusColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.clinicType?.toUpperCase() ?? "APPOINTMENT",
                                  style: TextStyle(color: statusColor.withAlpha(180), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                                _buildStatusBadge(item.status),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _getClinicName(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (item.clinicType == 'Doctor' || item.clinicType == 'Others')
                                        ? (item.doctorContact?['partner_doctor_specialist'] ??
                                            item.doctor?['doctor_specialist'] ??
                                            (item.clinicType == 'Others' ? "Allied Care" : "Specialist"))
                                        : (item.testId != null
                                            ? (item.test?['test_name'] ?? "Diagnostic Test")
                                            : _getClinicAddress(item)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Details",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: statusColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

            // 3. Compact Single-Row Action Bar (Video + Complete + Cancel)
            if (isUpcoming)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    if (isVideo) ...[
                      Expanded(
                        flex: 5,
                        child: windowOpen
                            ? InkWell(
                                onTap: () => _startVideoCall(item),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D9488).withValues(alpha: 0.28),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.videocam_rounded, color: Colors.white, size: 15),
                                        SizedBox(width: 4),
                                        Text(
                                          "Join Call",
                                          style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.videocam_outlined, color: Colors.blueGrey[500], size: 15),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.getWindowStartFormatted(),
                                        style: TextStyle(color: Colors.blueGrey[700], fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      flex: 3,
                      child: _compactActionButton(
                        Icons.check_circle_outline,
                        "Complete",
                        Colors.green,
                        () => _handleAction(item.id, 'Complete'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _compactActionButton(
                        Icons.cancel_outlined,
                        "Cancel",
                        Colors.red,
                        () => _handleAction(item.id, 'Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetailsModal(AppointmentModel item) {
    final statusColor = _getStatusColor(item.status);
    final bool isUpcoming = item.status == 'Upcoming' || item.status == 'Confirmed' || item.status == 'Pending' || item.status == null || item.status == '';
    final bool isVideo = item.isVideoCall;
    final bool isDoctorOrOthers = item.clinicType == 'Doctor' || item.clinicType == 'Others';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(modalCtx).viewPadding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(22),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_getTypeIcon(item.clinicType), color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.clinicType?.toUpperCase() ?? "APPOINTMENT",
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              _buildStatusBadge(item.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getClinicName(item),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (isDoctorOrOthers)
                            Text(
                              item.doctorContact?['partner_doctor_specialist'] ??
                                  item.doctor?['doctor_specialist'] ??
                                  (item.clinicType == 'Others' ? "Allied Care" : "Specialist"),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // All Details Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _detailRow(Icons.calendar_today_outlined, "Date", item.bookingDate ?? "N/A", isHighlighted: true),
                      const SizedBox(height: 6),
                      _detailRow(Icons.access_time_rounded, "Booking Time", _formatTime(item.bookingTime), isHighlighted: true),
                      if (isDoctorOrOthers) ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.schedule_rounded, "Slot Timing", _getSlotTimingInfo(item), isHighlighted: true),
                        if (_getSubSlotDetails(item) != null) ...[
                          const SizedBox(height: 6),
                          _detailRow(Icons.timer_outlined, "Slot Details", _getSubSlotDetails(item)!, isHighlighted: true),
                        ],
                      ],
                      if (isDoctorOrOthers || (item.visitMode ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _detailRow(
                          isVideo ? Icons.videocam_outlined : Icons.apartment_rounded,
                          "Visit Mode",
                          isVideo ? "Online Video Consultation" : "Physical Visit",
                        ),
                      ],
                      if (isDoctorOrOthers || item.doctorId != null) ...[
                        const SizedBox(height: 6),
                        _detailRow(
                          Icons.person_outline,
                          item.clinicType == 'Others' ? "Specialist" : "Doctor",
                          item.doctor?['doctor_name'] ?? item.doctorContact?['partner_doctor_name'] ?? item.clinicName ?? "Specialist",
                        ),
                        const SizedBox(height: 6),
                        _detailRow(
                          Icons.medical_services_outlined,
                          "Specialty",
                          item.doctor?['doctor_specialist'] ?? item.doctorContact?['partner_doctor_specialist'] ?? (item.clinicType == 'Others' ? "Allied Care" : "General Physician"),
                        ),
                      ],
                      if (item.testId != null) ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.biotech_outlined, "Test", item.test?['test_name'] ?? "Diagnostic Test", isHighlighted: true),
                        if (item.test?['test_type'] != null) ...[
                          const SizedBox(height: 6),
                          _detailRow(Icons.category_outlined, "Type", item.test?['test_type']),
                        ],
                      ],
                      const SizedBox(height: 6),
                      _detailRow(Icons.location_on_outlined, "Location", _getClinicAddress(item)),
                      if ((item.paymentAmount ?? '').isNotEmpty && item.paymentAmount != 'null') ...[
                        const SizedBox(height: 6),
                        _detailRow(
                          Icons.payments_outlined,
                          "Fee",
                          "₹${item.paymentAmount}${item.paymentStatus != null ? ' (${item.paymentStatus!.toUpperCase()})' : ''}",
                          isHighlighted: true,
                        ),
                      ],
                      if ((item.userInquiry ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _detailRow(Icons.notes_rounded, "Notes", item.userInquiry!.trim()),
                      ],
                    ],
                  ),
                ),

                if (isUpcoming && isVideo) ...[
                  const SizedBox(height: 14),
                  item.isWindowOpen()
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(modalCtx);
                              _startVideoCall(item);
                            },
                            icon: const Icon(Icons.videocam_rounded, size: 20),
                            label: const Text("Join Video Consultation", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined, color: Colors.blueGrey[400], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Video Call: ${item.getWindowStartFormatted()}",
                                style: TextStyle(color: Colors.blueGrey[700], fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                ],

                if (isUpcoming) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _modernActionButton(Icons.check_circle_outline, "Complete", Colors.green, () {
                          Navigator.pop(modalCtx);
                          _handleAction(item.id, 'Complete');
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _modernActionButton(Icons.cancel_outlined, "Cancel", Colors.red, () {
                          Navigator.pop(modalCtx);
                          _handleAction(item.id, 'Cancel');
                        }),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    final Color valueColor = isHighlighted ? const Color(0xFF1565C0) : const Color(0xFF455A64);
    final Color labelColor = isHighlighted ? const Color(0xFF1565C0).withAlpha(180) : Colors.blueGrey[400]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: isHighlighted ? const Color(0xFF1565C0) : Colors.blueGrey[300]),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: TextStyle(fontSize: 12, color: labelColor, fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(35), width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(30), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
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
      case 'Confirmed':
      case 'confirmed': return const Color(0xFF0D9488);
      case 'Upcoming':
      case 'upcoming':
      case 'Pending':
      case 'pending': return Colors.orange[700]!;
      case 'Completed':
      case 'completed': return Colors.green[700]!;
      case 'Cancelled':
      case 'cancelled': return Colors.red[700]!;
      default: return Colors.blueGrey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'OPD': return Icons.local_hospital_rounded;
      case 'Pathology': return Icons.biotech_rounded;
      case 'Doctor': return Icons.person_rounded;
      case 'Others': return Icons.accessibility_new_rounded;
      default: return Icons.calendar_today_rounded;
    }
  }

  String _getClinicName(AppointmentModel item) {
    String? name;
    if (item.clinicType == 'OPD') {
      name = item.opdContact?['clinic_name'];
    } else if (item.clinicType == 'Pathology') {
      name = item.pathologyContact?['clinic_name'];
    } else if (item.clinicType == 'Doctor' || item.clinicType == 'Others') {
      name = item.doctorContact?['partner_doctor_name'];
    }
    
    return name ?? item.clinicName ?? "Unknown Clinic";
  }

  String _getClinicAddress(AppointmentModel item) {
    String? address;
    if (item.clinicType == 'OPD') {
      address = item.opdContact?['clinic_address'];
    } else if (item.clinicType == 'Pathology') {
      address = item.pathologyContact?['clinic_address'];
    } else if (item.clinicType == 'Doctor' || item.clinicType == 'Others') {
      address = item.doctorContact?['partner_doctor_address'];
    }

    return address ?? "Address not provided";
  }

  int? _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final raw = timeStr.trim();
      final parts = raw.split(' ');
      final hms = parts[0].split(':');
      int h = int.parse(hms[0]);
      int m = hms.length > 1 ? int.parse(hms[1]) : 0;
      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
      }
      return h * 60 + m;
    } catch (_) {
      return null;
    }
  }

  String _formatShortTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '';
    try {
      final mins = _parseTimeToMinutes(timeStr);
      if (mins == null) return timeStr;
      final h24 = mins ~/ 60;
      final m = mins % 60;
      final period = h24 >= 12 ? 'PM' : 'AM';
      final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
      return '$h12:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return timeStr;
    }
  }

  String? _getSubSlotDetails(AppointmentModel item) {
    final int? bookingMins = _parseTimeToMinutes(item.bookingTime);
    if (bookingMins == null || item.bookingDate == null) return null;

    final rawSchedule = item.doctorContact?['visit_day_time'];
    List<dynamic> scheduleList = [];

    if (rawSchedule is List) {
      scheduleList = rawSchedule;
    } else if (rawSchedule is String && rawSchedule.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSchedule);
        if (decoded is List) scheduleList = decoded;
      } catch (_) {}
    }

    for (final entry in scheduleList) {
      if (entry is! Map) continue;
      final schedType = (entry['schedule_type'] ?? entry['type'] ?? '').toString().toLowerCase();
      final entryDate = entry['date']?.toString().trim();
      if (schedType == 'date' && entryDate == item.bookingDate!.trim()) {
        final slots = entry['slots'];
        if (slots is List) {
          for (final s in slots) {
            if (s is! Map) continue;
            final sStart = s['start_time']?.toString();
            final sEnd = s['end_time']?.toString();
            if (sStart == null) continue;
            final int? startMin = _parseTimeToMinutes(sStart);
            if (startMin == null) continue;
            int endMin = (sEnd != null ? _parseTimeToMinutes(sEnd) : null) ?? (startMin + 60);
            if (endMin <= startMin) endMin = startMin + 60;

            if (bookingMins >= startMin && bookingMins < endMin) {
              final int slotIndex = ((bookingMins - startMin) ~/ 10) + 1;
              final int subStart = startMin + (slotIndex - 1) * 10;
              final int subEnd = (subStart + 10 <= endMin) ? (subStart + 10) : endMin;

              String fmtMin(int mins) {
                final h24 = mins ~/ 60;
                final m = mins % 60;
                final period = h24 >= 12 ? 'PM' : 'AM';
                final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
                return '$h12:${m.toString().padLeft(2, '0')} $period';
              }

              return "Slot $slotIndex (${fmtMin(subStart)} - ${fmtMin(subEnd)})";
            }
          }
        }
      }
    }
    return null;
  }

  String _getSlotTimingInfo(AppointmentModel item) {
    final int? bookingMins = _parseTimeToMinutes(item.bookingTime);
    final rawSchedule = item.doctorContact?['visit_day_time'];
    List<dynamic> scheduleList = [];

    if (rawSchedule is List) {
      scheduleList = rawSchedule;
    } else if (rawSchedule is String && rawSchedule.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSchedule);
        if (decoded is List) scheduleList = decoded;
      } catch (_) {}
    }

    if (scheduleList.isNotEmpty && item.bookingDate != null) {
      for (final entry in scheduleList) {
        if (entry is! Map) continue;
        final schedType = (entry['schedule_type'] ?? entry['type'] ?? '').toString().toLowerCase();
        final entryDate = entry['date']?.toString().trim();
        if (schedType == 'date' && entryDate == item.bookingDate!.trim()) {
          final slots = entry['slots'];
          if (slots is List && slots.isNotEmpty) {
            if (bookingMins != null) {
              for (final s in slots) {
                if (s is! Map) continue;
                final sStart = s['start_time']?.toString();
                final sEnd = s['end_time']?.toString();
                final int startMin = _parseTimeToMinutes(sStart) ?? 0;
                final int endMin = _parseTimeToMinutes(sEnd) ?? 1439;
                if (bookingMins >= startMin && bookingMins <= endMin) {
                  final sId = (s['id'] ?? '').toString();
                  final sName = (s['name'] ?? (sId.isNotEmpty ? sId[0].toUpperCase() + sId.substring(1) : 'Slot')).toString();
                  if (sStart != null && sEnd != null) {
                    return "$sName (${_formatShortTime(sStart)} - ${_formatShortTime(sEnd)})";
                  }
                  return "$sName (${_formatTime(item.bookingTime)})";
                }
              }
            }
            // Fallback: list slots on that date
            final allLabels = slots.whereType<Map>().map((s) {
              final sId = (s['id'] ?? '').toString();
              final sName = (s['name'] ?? (sId.isNotEmpty ? sId[0].toUpperCase() + sId.substring(1) : 'Slot')).toString();
              final sStart = s['start_time']?.toString();
              final sEnd = s['end_time']?.toString();
              if (sStart != null && sEnd != null) {
                return "$sName (${_formatShortTime(sStart)} - ${_formatShortTime(sEnd)})";
              }
              return sName;
            }).join(', ');
            if (allLabels.isNotEmpty) return allLabels;
          }
        }
      }
    }

    if (bookingMins != null) {
      final String periodLabel = bookingMins < 12 * 60
          ? 'Morning'
          : (bookingMins < 17 * 60 ? 'Afternoon' : 'Evening');
      return "$periodLabel (${_formatTime(item.bookingTime)})";
    }

    return _formatTime(item.bookingTime);
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "N/A";
    try {
      final time = DateFormat("HH:mm:ss").parse(timeStr);
      return DateFormat("h:mm a").format(time);
    } catch (e) {
      return _formatShortTime(timeStr);
    }
  }
}

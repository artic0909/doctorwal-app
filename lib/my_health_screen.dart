import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/all_appointments_screen.dart';
import 'package:demoapp/medicalhistoryscreen.dart';
import 'package:demoapp/healthparametersscreen.dart';
import 'package:demoapp/alldoctorsscreen.dart';
import 'package:demoapp/Models/appointment_model.dart';
import 'package:demoapp/Services/apiservice.dart';

class MyHealthScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MyHealthScreen({super.key, required this.userData});

  @override
  State<MyHealthScreen> createState() => _MyHealthScreenState();
}

class _MyHealthScreenState extends State<MyHealthScreen> {
  String _memberId = '';
  String _medicalCardNo = '';

  final ApiService _apiService = ApiService();
  List<AppointmentModel> _recentAppointments = [];
  bool _isLoadingAppointments = true;

  Timer? _autoScrollTimer;
  final ScrollController _appointmentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadIds();
    _fetchCompletedAppointments();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _appointmentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadIds() async {
    String memId = widget.userData['member_id']?.toString() ??
        widget.userData['memberid']?.toString() ??
        '';
    String cardNo = widget.userData['medical_card_no']?.toString() ??
        widget.userData['medicalcardno']?.toString() ??
        '';

    try {
      final prefs = await SharedPreferences.getInstance();
      if (memId.isEmpty) {
        memId = prefs.getString('member_id') ?? '';
      }
      if (cardNo.isEmpty) {
        cardNo = prefs.getString('medical_card_no') ??
            prefs.getString('medicalcardno') ??
            '';
      }
    } catch (e) {
      debugPrint("Error loading card/member IDs: $e");
    }

    if (mounted) {
      setState(() {
        _memberId = memId.isNotEmpty ? memId : 'DW-2026';
        _medicalCardNo = cardNo.isNotEmpty ? cardNo : 'DW-CARD';
      });
    }
  }

  Future<void> _fetchCompletedAppointments() async {
    setState(() => _isLoadingAppointments = true);

    // 1. Try fetching completed appointments
    try {
      final response = await _apiService.getAppointmentsByStatus('Completed');
      if (response['status'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        final List<AppointmentModel> list =
            data.map((json) => AppointmentModel.fromJson(json)).toList();

        if (mounted) {
          setState(() {
            _recentAppointments = list.take(10).toList();
            _isLoadingAppointments = false;
          });
          _startAutoScroll();
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching completed appointments: $e");
    }

    // 2. Fallback to general appointments if completed had 0 items
    try {
      final allResponse = await _apiService.getAppointments();
      if (allResponse['status'] == true && allResponse['data'] != null) {
        final List<dynamic> data = allResponse['data'];
        final List<AppointmentModel> list =
            data.map((json) => AppointmentModel.fromJson(json)).toList();

        final completed =
            list.where((a) => (a.status ?? '').toLowerCase() == 'completed').toList();
        final toShow = completed.isNotEmpty ? completed : list;

        if (mounted) {
          setState(() {
            _recentAppointments = toShow.take(10).toList();
            _isLoadingAppointments = false;
          });
          _startAutoScroll();
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching fallback appointments: $e");
    }

    if (mounted) {
      setState(() => _isLoadingAppointments = false);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_recentAppointments.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_appointmentScrollController.hasClients) return;

      final maxScroll = _appointmentScrollController.position.maxScrollExtent;
      final currentScroll = _appointmentScrollController.offset;
      const itemWidth = 314.0; // 300 card width + 14 separator

      double targetScroll = currentScroll + itemWidth;
      if (targetScroll >= maxScroll - 5) {
        targetScroll = 0.0;
      }

      _appointmentScrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  String _getClinicName(AppointmentModel item) {
    String? name;
    if (item.clinicType == 'OPD') {
      name = item.opdContact?['clinic_name'];
    } else if (item.clinicType == 'Pathology') {
      name = item.pathologyContact?['clinic_name'];
    } else if (item.clinicType == 'Doctor') {
      name = item.doctorContact?['partner_doctor_name'];
    }
    return name ?? item.clinicName ?? "Sumatra test";
  }

  String _getClinicAddress(AppointmentModel item) {
    String? address;
    if (item.clinicType == 'OPD') {
      address = item.opdContact?['clinic_address'];
    } else if (item.clinicType == 'Pathology') {
      address = item.pathologyContact?['clinic_address'];
    } else if (item.clinicType == 'Doctor') {
      address = item.doctorContact?['partner_doctor_address'];
    }
    return address ?? "Address not provided";
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "N/A";
    try {
      final time = DateFormat("HH:mm:ss").parse(timeStr);
      return DateFormat("h:mm a").format(time);
    } catch (_) {
      try {
        final time = DateFormat("HH:mm").parse(timeStr);
        return DateFormat("h:mm a").format(time);
      } catch (_) {
        return timeStr;
      }
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'OPD':
        return Icons.local_hospital_rounded;
      case 'Pathology':
        return Icons.biotech_rounded;
      case 'Doctor':
        return Icons.person_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentName =
        widget.userData['name'] ?? widget.userData['user_name'] ?? 'Saklin Mustak';
    final String? currentImg = widget.userData['image']?.toString();
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. FIXED TOP HEADER (Doctorwala Signature Blue, fixed at top)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, topPadding, 18, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1), // Doctorwala Deep Navy Blue
                  Color(0xFF1565C0), // Royal Blue
                  Color(0xFF1976D2), // Accent Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x330D47A1),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Title + Member ID Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "My Health",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(70), width: 0.9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "ID: $_memberId",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // User Row: Avatar + Name + Portal Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(45),
                        border: Border.all(color: Colors.white.withAlpha(140), width: 1.5),
                      ),
                      child: ClipOval(
                        child: (currentImg != null &&
                                currentImg.isNotEmpty &&
                                currentImg.startsWith('http'))
                            ? Image.network(
                                currentImg,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Name & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            "Personal Health Portal",
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // PROMINENT HIGHLIGHTED MEDICAL CARD PLATE
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _medicalCardNo));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text("Card number copied: $_medicalCardNo"),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF0D47A1),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Card Icon Box
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Card Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "MEDICAL CARD NO",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "Active",
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _medicalCardNo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0D47A1),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Copy Icon Button
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SCROLLABLE CONTENT (Using ClampingScrollPhysics - NOT Spring / Bouncing)
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Solid, non-spring scroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Action Cards List (Sequence 1 to 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // 1. View My Appointments
                        _buildActionCard(
                          context: context,
                          icon: Icons.event_available_rounded,
                          iconColor: const Color(0xFF059669), // Emerald Green
                          iconBgColor: const Color(0xFFECFDF5),
                          title: "View My Appointments",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AllAppointmentsScreen(userData: widget.userData),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // 2. View Medical Reports
                        _buildActionCard(
                          context: context,
                          icon: Icons.medical_information_rounded,
                          iconColor: const Color(0xFFD97706), // Warm Amber
                          iconBgColor: const Color(0xFFFFFBEB),
                          title: "View Medical Reports",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MedicalHistoryScreen(initialTabIndex: 0),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // 3. View Doctor Prescriptions
                        _buildActionCard(
                          context: context,
                          icon: Icons.medication_rounded,
                          iconColor: const Color(0xFF2563EB), // Medical Blue
                          iconBgColor: const Color(0xFFEFF6FF),
                          title: "View Doctor Prescriptions",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MedicalHistoryScreen(initialTabIndex: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // 4. View Health Vitals Records
                        _buildActionCard(
                          context: context,
                          icon: Icons.monitor_heart_rounded,
                          iconColor: const Color(0xFFE11D48), // Vital Pulse Red
                          iconBgColor: const Color(0xFFFFF1F2),
                          title: "View Health Vitals Records",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HealthParametersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title: Recent Appointments (with View All link)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Recent Appointments",
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AllAppointmentsScreen(userData: widget.userData),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "View All",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 11, color: Color(0xFF1565C0)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Horizontal Scrollable Cards (Auto-scrolls latest completed appointments with full details)
                  SizedBox(
                    height: 188,
                    child: _buildAppointmentsSection(context),
                  ),

                  // Bottom padding for curved floating nav bar
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Rounded icon box with colored tint
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection(BuildContext context) {
    if (_isLoadingAppointments) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => _buildSkeletonCard(),
      );
    }

    if (_recentAppointments.isEmpty) {
      return ListView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildEmptyAppointmentCard(context),
        ],
      );
    }

    return ListView.separated(
      controller: _appointmentScrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentAppointments.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final item = _recentAppointments[index];
        return _buildAppointmentCard(context, item);
      },
    );
  }

  // Appointment Card preserving the exact beautiful background design with ALL details matching AllAppointmentsScreen
  Widget _buildAppointmentCard(BuildContext context, AppointmentModel item) {
    final String clinicName = _getClinicName(item);
    final String clinicAddress = _getClinicAddress(item);
    final String? doctorName =
        item.doctor?['doctor_name'] ?? item.doctorContact?['partner_doctor_name'];
    final String? specialist =
        item.doctor?['doctor_specialist'] ?? item.doctorContact?['partner_doctor_specialist'];
    final String? testName = item.test?['test_name'];
    final String formattedTime = _formatTime(item.bookingTime);
    final String type = item.clinicType?.toUpperCase() ?? "OPD";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AllAppointmentsScreen(userData: widget.userData),
          ),
        );
      },
      child: Container(
        width: 300,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFF0FDF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF90CAF9).withAlpha(120), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circle watermark
            Positioned(
              right: -10,
              top: -10,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF1565C0).withAlpha(15),
                child: Icon(
                  _getTypeIcon(item.clinicType),
                  size: 28,
                  color: const Color(0xFF1565C0).withAlpha(40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Top Row: Type Pill + Status Badge + ID
                  Row(
                    children: [
                      // Type Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status Badge (COMPLETED)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF059669).withAlpha(60), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF059669), size: 10),
                            const SizedBox(width: 3),
                            Text(
                              item.status?.toUpperCase() ?? "COMPLETED",
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // ID badge
                      Text(
                        "#${item.id}",
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),

                  // 2. Main Clinic / OPD / Hospital Name
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      clinicName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D47A1),
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 3. Location Row
                  _cardDetailRow(
                    icon: Icons.location_on_outlined,
                    label: "Location",
                    value: clinicAddress,
                  ),

                  // 4. Doctor Row
                  if (doctorName != null && doctorName.isNotEmpty)
                    _cardDetailRow(
                      icon: Icons.person_outline_rounded,
                      label: "Doctor",
                      value: doctorName,
                      isPrimary: true,
                    ),

                  // 5. Specialist Row
                  if (specialist != null && specialist.isNotEmpty)
                    _cardDetailRow(
                      icon: Icons.medical_services_outlined,
                      label: "Specialist",
                      value: specialist,
                    ),

                  // 6. Test Row (if test present)
                  if (testName != null && testName.isNotEmpty)
                    _cardDetailRow(
                      icon: Icons.biotech_outlined,
                      label: "Test",
                      value: testName,
                    ),

                  // 7. Bottom Date & Time bar (matching Image 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 5),
                        Text(
                          item.bookingDate ?? "N/A",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 12.5,
            color: isPrimary ? const Color(0xFF1565C0) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 11,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                color: isPrimary ? const Color(0xFF1565C0) : const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton Card while loading appointments
  Widget _buildSkeletonCard() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withAlpha(120),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF90CAF9).withAlpha(80), width: 1),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        ),
      ),
    );
  }

  // Empty state card preserving the same background design
  Widget _buildEmptyAppointmentCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllDoctorsScreen(userData: widget.userData),
          ),
        );
      },
      child: Container(
        width: 300,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFF0FDF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF90CAF9).withAlpha(120), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFF1565C0).withAlpha(15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "APPOINTMENTS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No completed appointments yet",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Book appointments with top verified specialists easily.",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "Book Doctor Appointment →",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

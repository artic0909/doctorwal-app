import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/all_appointments_screen.dart';
import 'package:demoapp/medicalhistoryscreen.dart';
import 'package:demoapp/healthparametersscreen.dart';
import 'package:demoapp/alldoctorsscreen.dart';
import 'package:demoapp/allavailablepathologyscreen.dart';

class MyHealthScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MyHealthScreen({super.key, required this.userData});

  @override
  State<MyHealthScreen> createState() => _MyHealthScreenState();
}

class _MyHealthScreenState extends State<MyHealthScreen> {
  String _memberId = '';
  String _medicalCardNo = '';

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<void> _loadIds() async {
    // 1. Initial check from widget.userData
    String memId = widget.userData['member_id']?.toString() ??
        widget.userData['memberid']?.toString() ??
        '';
    String cardNo = widget.userData['medical_card_no']?.toString() ??
        widget.userData['medicalcardno']?.toString() ??
        '';

    // 2. Fetch from SharedPreferences if empty
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

  @override
  Widget build(BuildContext context) {
    final String currentName = widget.userData['name'] ?? widget.userData['user_name'] ?? 'Saklin Mustak';
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
                        child: (currentImg != null && currentImg.isNotEmpty && currentImg.startsWith('http'))
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
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                builder: (context) => AllAppointmentsScreen(userData: widget.userData),
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
                                builder: (context) => const MedicalHistoryScreen(initialTabIndex: 0),
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
                                builder: (context) => const MedicalHistoryScreen(initialTabIndex: 1),
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
                                builder: (context) => const HealthParametersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title for Horizontal Banner
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Health Check For You",
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Horizontal Banners (ClampingScrollPhysics - NOT Spring, manual scroll)
                  SizedBox(
                    height: 168,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(), // Solid, non-spring scroll
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Banner 1: Listen to your body / Health Check
                        _buildHealthCheckBanner(context),
                        const SizedBox(width: 14),

                        // Banner 2: Online Doctor Consultation
                        _buildDoctorConsultBanner(context),
                        const SizedBox(width: 14),

                        // Banner 3: Full Body Screening
                        _buildFullBodyCheckupBanner(context),
                      ],
                    ),
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

  Widget _buildHealthCheckBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllAvailablePathologyScreen(userData: widget.userData),
          ),
        );
      },
      child: Container(
        width: 290,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFF0FDF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF90CAF9).withAlpha(120), width: 1),
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
            Positioned(
              right: -15,
              top: -15,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFF1565C0).withAlpha(15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D47A1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 4),
                            Text(
                              "HEALTH CHECK",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LISTEN TO YOUR BODY",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              "GET A HEALTH CHECK",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0D47A1),
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Starting at just",
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "₹ 1,699/-*",
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.biotech_rounded,
                              size: 30,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "Book Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "USE CODE: HEALTH10 • Get extra 10% off",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1),
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

  Widget _buildDoctorConsultBanner(BuildContext context) {
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
        width: 290,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Fever, cold & flu?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 12),
                        SizedBox(width: 3),
                        Text(
                          "Instant",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Online Doctor Consultation",
                style: TextStyle(
                  color: Color(0xFFB3E5FC),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 13),
                  SizedBox(width: 5),
                  Text(
                    "Consult from the comfort of home",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello Doctor",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "Doctor On Call",
                        style: TextStyle(
                          color: Color(0xFF81D4FA),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      "Consult Now",
                      style: TextStyle(
                        color: Color(0xFF0D47A1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullBodyCheckupBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllAvailablePathologyScreen(userData: widget.userData),
          ),
        );
      },
      child: Container(
        width: 290,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Full Body Checkup",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "40% OFF",
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "60+ Vital Health Parameters Tested",
                style: TextStyle(
                  color: Color(0xFFDBEAFE),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.home_work_outlined, color: Colors.white70, size: 13),
                  SizedBox(width: 5),
                  Text(
                    "Free Sample Collection from Home",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Only ₹ 999/-",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      "Book Test",
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

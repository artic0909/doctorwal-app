import 'dart:math' as math;
import 'package:demoapp/allopdscreen.dart';
import 'package:demoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alldoctorsscreen.dart';
import 'allavailablepathologyscreen.dart';
import 'package:demoapp/notificationscreen.dart';
import 'profileeditscreen.dart';
import 'package:demoapp/healthparametersscreen.dart';
import 'package:demoapp/medicalhistoryscreen.dart';
import 'package:demoapp/bmr.dart';
import 'package:demoapp/search_screen.dart';
import 'package:demoapp/all_appointments_screen.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:demoapp/bottom_nav.dart';
import 'package:demoapp/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoryHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CategoryHomeScreen({super.key, required this.userData});

  @override
  State<CategoryHomeScreen> createState() => _CategoryHomeScreenState();
}

class _CategoryHomeScreenState extends State<CategoryHomeScreen> {
  String name = '';
  String email = '';
  String memberId = '';
  String medicalCardNo = '';
  String profileImg = '';
  bool isGeneratingCard = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  String? _userCity;

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    _syncUserId(); // Background sync
    _fetchCity();
    
    // Discovery Animation: Peek at scrollable content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_horizontalScrollController.hasClients) {
          _horizontalScrollController.animateTo(
            40,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          ).then((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_horizontalScrollController.hasClients) {
                _horizontalScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.elasticOut,
                );
              }
            });
          });
        }
      });
    });
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name =
          prefs.getString('name') ??
          widget.userData['name'] ??
          widget.userData['user_name'] ??
          'User';
      email =
          prefs.getString('email') ??
          widget.userData['email'] ??
          widget.userData['user_email'] ??
          '';

      // Aggressive key checking for memberId
      memberId = prefs.getString('member_id') ?? '';
      if (memberId.trim().isEmpty) memberId = prefs.getString('memberid') ?? '';
      if (memberId.trim().isEmpty) {
        memberId = widget.userData['member_id']?.toString() ?? '';
      }
      if (memberId.trim().isEmpty) {
        memberId = widget.userData['memberid']?.toString() ?? '';
      }
      if (memberId.trim().isEmpty) memberId = 'DW-2026-CARD';

      // Aggressive key checking for medicalCardNo
      medicalCardNo = prefs.getString('medical_card_no') ?? '';
      if (medicalCardNo.trim().isEmpty) {
        medicalCardNo = prefs.getString('medicalcardno') ?? '';
      }
      if (medicalCardNo.trim().isEmpty) {
        medicalCardNo = widget.userData['medical_card_no']?.toString() ?? '';
      }
      if (medicalCardNo.trim().isEmpty) {
        medicalCardNo = widget.userData['medicalcardno']?.toString() ?? '';
      }
      if (medicalCardNo.trim().isEmpty) medicalCardNo = 'DW26 0000 00';

      profileImg =
          prefs.getString('image') ??
          widget.userData['image']?.toString() ??
          '';
    });
  }

  Future<void> _fetchCity({BuildContext? context}) async {
    final city = await LocationService.getUserCity(context: context);
    if (mounted) {
      setState(() {
        _userCity = city;
      });
    }
  }

  Future<void> _syncUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? currentId = prefs.getString('id');

    // If ID is already present, no need to sync
    if (currentId != null && currentId.isNotEmpty) return;

    // Fetch profile to get the ID
    final apiService = ApiService();
    final profile = await apiService.getProfile();

    if (profile['status'] == true && profile['data'] != null) {
      final user = profile['data'];
      final String fetchedId = (user['id'] ?? '').toString();

      if (fetchedId.isNotEmpty) {
        await prefs.setString('id', fetchedId);
        // Also update local state if needed (though userData is final in widget)
        debugPrint("User ID synced successfully: $fetchedId");
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://doctorwala.info/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${response.body}')),
        );
      }
    } catch (e) {
      // If error (e.g. 401), just clear and go back
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _generateMedicalCard() async {
    setState(() => isGeneratingCard = true);
    try {
      final apiService = ApiService();
      final result = await apiService.generateMedicalCard();

      if (result['status'] == true && result['data'] != null) {
        final data = result['data'];
        final String newMemberId = data['member_id']?.toString() ?? '';
        final String newCardNo = data['medical_card_no']?.toString() ?? '';

        if (newMemberId.isNotEmpty && newCardNo.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('member_id', newMemberId);
          await prefs.setString('medical_card_no', newCardNo);

          setState(() {
            memberId = newMemberId;
            medicalCardNo = newCardNo;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical card generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to generate card'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isGeneratingCard = false);
    }
  }

  Future<void> _callAmbulance() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Colors.red, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Emergency Ambulance Service",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                ),
                const SizedBox(height: 6),
                Text(
                  "Immediate 24/7 emergency dispatch helpline",
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  tileColor: const Color(0xFFFEEBEE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Icons.phone_in_talk_rounded, color: Colors.red, size: 28),
                  title: const Text("National Ambulance (108)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: const Text("Toll-free emergency medical response"),
                  trailing: const Icon(Icons.call_rounded, color: Colors.red),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse('tel:108'));
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: const Color(0xFFF0F4FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF1565C0), size: 28),
                  title: const Text("Doctorwala Emergency Desk", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  subtitle: const Text("+91 6292237207 (24x7 Helpline)"),
                  trailing: const Icon(Icons.call_rounded, color: Color(0xFF1565C0)),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse('tel:+916292237207'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMyBills() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF57F17), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  "My Bills & Payment Invoices",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                ),
                const SizedBox(height: 6),
                Text(
                  "All consultation and diagnostic invoices are synced with your records",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  tileColor: const Color(0xFFF8FAFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF1565C0)),
                  title: const Text("Appointment Invoices", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("View paid and upcoming consultation fees"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllAppointmentsScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: const Color(0xFFF8FAFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Icons.assignment_rounded, color: Color(0xFF2E7D32)),
                  title: const Text("Diagnostic & Test Invoices", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("View test receipts and digital bills"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicalHistoryScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use local state if it's available, otherwise fallback to widget data
    final String currentName =
        name.isNotEmpty && name != 'User'
            ? name
            : (widget.userData['name'] ??
                widget.userData['user_name'] ??
                'Guest');

    // Member ID Fallback logic
    String dispMemberId = memberId;
    if (dispMemberId.trim().isEmpty ||
        dispMemberId == 'DW-0000-000' ||
        dispMemberId == 'DW-2026-CARD') {
      dispMemberId =
          (widget.userData['member_id'] ??
                  widget.userData['memberid'] ??
                  'DW-2026-CARD')
              .toString();
    }

    // Card No Fallback logic
    String dispCardNo = medicalCardNo;
    if (dispCardNo.trim().isEmpty ||
        dispCardNo == 'DW00 0000 00' ||
        dispCardNo == 'DW01 0001 001' ||
        dispCardNo == 'DW26 0000 00') {
      dispCardNo =
          (widget.userData['medical_card_no'] ??
                  widget.userData['medicalcardno'] ??
                  '')
              .toString();
    }

    bool hasCard = dispMemberId.isNotEmpty &&
        dispMemberId != 'DW-0000-000' &&
        dispMemberId != 'DW-2026-CARD' &&
        dispCardNo.isNotEmpty &&
        dispCardNo != 'DW00 0000 00' &&
        dispCardNo != 'DW01 0001 001' &&
        dispCardNo != 'DW26 0000 00';

    final String currentProfileImg =
        profileImg.isNotEmpty
            ? profileImg
            : (widget.userData['image']?.toString() ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => BottomNavScreen.globalScaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final city = await LocationService.getUserCity(context: context);
                      if (mounted && city != null) {
                        setState(() {
                          _userCity = city;
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFE53935),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _userCity ?? "Kolkata",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Hi! $currentName",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // --- Notification Bell ---
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.blueGrey[600],
                    size: 24,
                  ),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Hero(
              tag: 'profile',
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProfileEditScreen(userData: widget.userData),
                      ),
                    ).then((_) => loadUserData()),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1565C0).withAlpha(38),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueGrey[50],
                    backgroundImage:
                        currentProfileImg.isNotEmpty
                            ? NetworkImage(_getImageUrl(currentProfileImg))
                            : null,
                    child:
                        currentProfileImg.isEmpty
                            ? const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: Color(0xFF1565C0),
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.of(context).viewPadding.bottom + 25,
        ),
        children: [
          // 1. Search Bar (Matching reference screenshot)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(userData: widget.userData),
                ),
              ),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.blueGrey.withAlpha(25)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF90A4AE),
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: "Search for "),
                            TextSpan(
                              text: "Doctor, Clinic, Test...",
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF78909C),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Categories Title
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Text(
              "Categories",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ),

          // 3. Categories Grid: 4 x 2 layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // Row 1: Doctor Consultation, Pathology Tests, Chambers (OPD), Appointments
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Doctor Consultation
                    _categoryCircleItem(
                      title: "Doctor\nConsultation",
                      color: const Color(0xFF1565C0),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.person_rounded, color: Color(0xFF1565C0), size: 24),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0D47A1), size: 11),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllDoctorsScreen(userData: widget.userData),
                        ),
                      ),
                    ),
                    // 2. Pathology Tests
                    _categoryCircleItem(
                      title: "Pathology\nTests",
                      color: const Color(0xFF00897B),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.biotech_rounded, color: Color(0xFF00897B), size: 24),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.science_rounded, color: Color(0xFF004D40), size: 10),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllAvailablePathologyScreen(userData: widget.userData),
                        ),
                      ),
                    ),
                    // 3. Chambers (OPD)
                    _categoryCircleItem(
                      title: "Chambers\n(OPD)",
                      color: const Color(0xFFE53935),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.domain_rounded, color: Color(0xFFE53935), size: 23),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFC62828), size: 11),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllAvailableOPDScreen(userData: widget.userData),
                        ),
                      ),
                    ),
                    // 4. Appointments
                    _categoryCircleItem(
                      title: "Appointments\n ",
                      color: const Color(0xFF6A1B9A),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF6A1B9A), size: 23),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 11),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllAppointmentsScreen(userData: widget.userData),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Row 2: Prescriptions, Reports, Pay Your Bills, Call Ambulance
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 5. Prescriptions
                    _categoryCircleItem(
                      title: "Prescriptions\n ",
                      color: const Color(0xFF0288D1),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: Color(0xFF0288D1), size: 23),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.medication_rounded, color: Color(0xFFE53935), size: 11),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicalHistoryScreen(initialTabIndex: 1),
                        ),
                      ),
                    ),
                    // 6. Reports
                    _categoryCircleItem(
                      title: "Reports\n ",
                      color: const Color(0xFFE65100),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.assignment_rounded, color: Color(0xFFE65100), size: 23),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.checklist_rounded, color: Color(0xFF2E7D32), size: 11),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicalHistoryScreen(initialTabIndex: 0),
                        ),
                      ),
                    ),
                    // 7. Pay Your Bills
                    _categoryCircleItem(
                      title: "Pay Your\nBills",
                      color: const Color(0xFFF57F17),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFF57F17), size: 23),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF2E7D32), size: 10),
                            ),
                          ),
                        ],
                      ),
                      onTap: _showMyBills,
                    ),
                    // 8. Call Ambulance
                    _categoryCircleItem(
                      title: "Call\nAmbulance",
                      color: const Color(0xFFD32F2F),
                      customIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.airport_shuttle_rounded, color: Color(0xFFD32F2F), size: 24),
                          Positioned(
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.emergency_rounded, color: Color(0xFFE53935), size: 10),
                            ),
                          ),
                        ],
                      ),
                      onTap: _callAmbulance,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Instant Video Consult Card (From reference image)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildInstantVideoConsultCard(),
          ),

          const SizedBox(height: 14),

          // 5. Need Help? Card (From reference image)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildNeedHelpBanner(),
          ),

          const SizedBox(height: 24),

          // 6. Dynamic Virtual Medical Card (Creation Card if not generated)
          if (!hasCard) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withAlpha(90),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.credit_card_off_rounded,
                    color: Colors.white54,
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Virtual Medical Card",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Generate your digital health card for instant clinic check-in",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: isGeneratingCard ? null : _generateMedicalCard,
                    icon: isGeneratingCard
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Color(0xFF1565C0),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add_card_rounded, size: 18),
                    label: Text(
                      isGeneratingCard ? "Generating..." : "Generate Card Now",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 7. Quick Services Slider (BMR, Health Vitals, etc.)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Health & Vitals Trackers",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _eyeCatchyBox(
                        title: "BMR Calculator",
                        subtitle: "Daily calories",
                        icon: Icons.monitor_weight_rounded,
                        gradient: [
                          const Color(0xFFFF8A65),
                          const Color(0xFFD84315),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BMRCalculatorScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _eyeCatchyBox(
                        title: "Health Vitals",
                        subtitle: "Track metrics",
                        icon: Icons.monitor_heart_rounded,
                        gradient: [
                          const Color(0xFF5C6BC0),
                          const Color(0xFF3949AB),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthParametersScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _eyeCatchyBox(
                        title: "Digital Prescriptions",
                        subtitle: "View records",
                        icon: Icons.medication_rounded,
                        gradient: [
                          const Color(0xFF26A69A),
                          const Color(0xFF00796B),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MedicalHistoryScreen(
                              initialTabIndex: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _eyeCatchyBox(
                        title: "My Appointments",
                        subtitle: "Track visits",
                        icon: Icons.calendar_today_rounded,
                        gradient: [
                          const Color(0xFFF06292),
                          const Color(0xFFC2185B),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllAppointmentsScreen(
                              userData: widget.userData,
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

          const SizedBox(height: 24),

          // 8. Wellness Hub (Invite & Tips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWellnessHub(),
          ),
        ],
      ),
    );
  }

  Widget _categoryCircleItem({
    required String title,
    IconData? icon,
    Widget? customIcon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: color.withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.blueGrey.withAlpha(20)),
              ),
              child: Center(
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(18),
                  ),
                  child: Center(
                    child: customIcon ?? Icon(icon, color: color, size: 23),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantVideoConsultCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Instant Video Consult",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1565C0),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Connect with top verified doctors",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF546E7A),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllDoctorsScreen(userData: widget.userData),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Consult Now",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 108,
            height: 98,
            child: Image.asset(
              "assets/images/video-consult.png",
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 75,
                height: 85,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.video_camera_front_rounded,
                  color: Color(0xFF1565C0),
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0277BD), Color(0xFF00897B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0277BD).withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need Help?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "If you have any queries or need support",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:+916292237207')),
            icon: const Icon(Icons.call_rounded, size: 15, color: Color(0xFF0277BD)),
            label: const Text(
              "Call Now",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0277BD),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyeCatchyBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    // Peek effect: show roughly 3.1 cards to hint at more content, min 105 width
    final double cardWidth = math.max(105.0, (MediaQuery.of(context).size.width - 48) / 3.1);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            "Wellness Hub",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF263238),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        // Promo Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withAlpha(76),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.card_giftcard_rounded,
                  size: 80,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Invite & Earn Rewards",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Share Doctorwala with your friends and explore premium benefits together.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      SharePlus.instance.share(ShareParams(
                        text: 'Download the Doctorwala app for your health needs: https://play.google.com/store/apps/details?id=com.doctorwala.dochealth&hl=en_IN',
                        subject: 'Join Doctorwala',
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF5722),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      "Invite Now",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 25),
        
        // Health Tips Horizontal
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            "Quick Health Insights",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF455A64),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildTipCard(
                "STAY HYDRATED",
                "Drink 8 glasses of water daily for better energy.",
                Icons.water_drop_rounded,
                const Color(0xFF03A9F4),
              ),
              const SizedBox(width: 12),
              _buildTipCard(
                "DAILY WALK",
                "A 30-min walk can boost your heart health significantly.",
                Icons.directions_walk_rounded,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 12),
              _buildTipCard(
                "BETTER SLEEP",
                "Aim for 7-9 hours of restful sleep every night.",
                Icons.bedtime_rounded,
                const Color(0xFF673AB7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(String title, String desc, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: Color(0xFF37474F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;

    // Base URL must always point to the domain root
    const String domain = "https://doctorwala.info/";

    // Normalize path: remove leading slash
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // If it doesn't have storage/ prefix and it's not a full URL, add it
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }

    return domain + cleanPath;
  }
}

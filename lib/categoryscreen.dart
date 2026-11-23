import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:demoapp/allopdscreen.dart';
import 'package:demoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alldoctorsscreen.dart';
import 'allavailablepathologyscreen.dart';
import 'package:demoapp/pathologydetailsscreen.dart';
import 'package:demoapp/Models/all_available_path_model.dart';
import 'package:demoapp/notificationscreen.dart';
import 'package:demoapp/medicalhistoryscreen.dart';
import 'package:demoapp/search_screen.dart';
import 'package:demoapp/all_appointments_screen.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:http/http.dart' as http;
import 'package:demoapp/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:demoapp/bottom_nav.dart';
import 'package:demoapp/account_tab_screen.dart';
import 'package:demoapp/profileeditscreen.dart';
import 'package:demoapp/my_bills_payments_screen.dart';

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
  List<AllAvailablePathModel> _pathologyPartners = [];
  bool _isLoadingPathology = true;
  late PageController _pathologyPageController;
  int _currentPathologyIndex = 0;
  Timer? _pathologyAutoScrollTimer;
  List<String> _doctorSpecialties = [];
  bool _isLoadingSpecialties = true;

  @override
  void dispose() {
    ProfileEditScreen.profileUpdateNotifier.removeListener(loadUserData);
    _pathologyAutoScrollTimer?.cancel();
    _pathologyPageController.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    name = widget.userData['name'] ?? widget.userData['user_name'] ?? '';
    email = widget.userData['email'] ?? widget.userData['user_email'] ?? '';
    ProfileEditScreen.profileUpdateNotifier.addListener(loadUserData);
    _pathologyPageController = PageController(viewportFraction: 0.90);
    loadUserData();
    _syncUserId(); // Background sync
    _fetchCity();
    _fetchPathologyPartners();
    _fetchDoctorSpecialties();
    
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
    if (!mounted) return;
    setState(() {
      name =
          prefs.getString('name') ??
          prefs.getString('user_name') ??
          widget.userData['name'] ??
          widget.userData['user_name'] ??
          'User';
      email =
          prefs.getString('email') ??
          prefs.getString('user_email') ??
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
          prefs.getString('profile_image') ??
          prefs.getString('image') ??
          prefs.getString('user_image') ??
          widget.userData['profile_image']?.toString() ??
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

  Future<void> _fetchPathologyPartners() async {
    try {
      // Query clinics with tests first to show real available diagnostic tests
      final url = Uri.parse("https://doctorwala.info/api/api/all-pathology-contacts?query=test");
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];
        final List<AllAvailablePathModel> parsed = data.map((e) => AllAvailablePathModel.fromJson(e)).toList();

        // Filter to real clinics that actually have tests
        final withTests = parsed.where((c) => c.tests.isNotEmpty).toList();
        withTests.shuffle();

        List<AllAvailablePathModel> selected = withTests.take(10).toList();
        if (selected.length < 10) {
          final remaining = parsed.where((c) => c.tests.isEmpty).toList();
          remaining.shuffle();
          selected.addAll(remaining.take(10 - selected.length));
        }

        if (selected.isNotEmpty && mounted) {
          setState(() {
            _pathologyPartners = selected;
            _isLoadingPathology = false;
          });
          _startPathologyAutoScroll();
          return;
        }
      }
    } catch (e) {
      debugPrint("Pathology partners fetch note: $e");
    }

    // Fallback: standard page 1 without static/fake data
    try {
      final fallbackUrl = Uri.parse("https://doctorwala.info/api/api/all-pathology-contacts?page=1");
      final fallbackResponse = await http.get(fallbackUrl).timeout(const Duration(seconds: 8));
      if (fallbackResponse.statusCode == 200) {
        final jsonData = jsonDecode(fallbackResponse.body);
        final List data = jsonData['data'] ?? [];
        final List<AllAvailablePathModel> parsed = data.map((e) => AllAvailablePathModel.fromJson(e)).toList();
        parsed.shuffle();
        if (parsed.isNotEmpty && mounted) {
          setState(() {
            _pathologyPartners = parsed.take(10).toList();
            _isLoadingPathology = false;
          });
          _startPathologyAutoScroll();
          return;
        }
      }
    } catch (e) {
      debugPrint("Pathology partners fallback note: $e");
    }

    if (mounted) {
      setState(() {
        _isLoadingPathology = false;
      });
    }
  }

  void _startPathologyAutoScroll() {
    _pathologyAutoScrollTimer?.cancel();
    if (_pathologyPartners.length > 1) {
      _pathologyAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pathologyPageController.hasClients && mounted) {
          final nextIndex = (_currentPathologyIndex + 1) % _pathologyPartners.length;
          _pathologyPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  Future<void> _fetchDoctorSpecialties() async {
    final defaultSpecialties = [
      'General Physician',
      'Dentist',
      'Dermatologist',
      'Orthopedic',
      'Gynecologist',
      'Pediatrician',
      'Neurologist',
      'Ophthalmologist',
      'Cardiologist',
      'Ent surgeon',
      'Psychiatrist',
      'Physiotherapist',
      'Ayurvedic',
      'Homeopath',
      'Medicine',
    ];

    try {
      final randomPage = math.Random().nextInt(8) + 1;
      final url = Uri.parse("https://doctorwala.info/api/api/all-doctors-contacts?page=$randomPage");
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];
        final Set<String> uniqueSpecialties = {};
        for (var doc in data) {
          final spec = doc['partner_doctor_specialist'];
          if (spec != null && spec != 'null' && spec != 'NA' && spec.toString().trim().isNotEmpty) {
            final cleaned = spec.toString().trim();
            if (cleaned.length > 2) {
              uniqueSpecialties.add(cleaned);
            }
          }
        }

        final List<String> list = uniqueSpecialties.toList();
        for (var d in defaultSpecialties) {
          if (!list.any((s) => s.toLowerCase() == d.toLowerCase())) {
            list.add(d);
          }
        }

        list.shuffle(math.Random());
        final selected = list.take(10).toList();
        if (mounted && selected.isNotEmpty) {
          setState(() {
            _doctorSpecialties = selected;
            _isLoadingSpecialties = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Doctor specialties dynamic fetch note: $e");
    }

    final fallback = List<String>.from(defaultSpecialties);
    fallback.shuffle(math.Random());
    if (mounted) {
      setState(() {
        _doctorSpecialties = fallback.take(10).toList();
        _isLoadingSpecialties = false;
      });
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyBillsPaymentsScreen(userData: widget.userData),
      ),
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
                              fontWeight: FontWeight.normal,
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // --- Notification Bell ---
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              ),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFE65100),
                      size: 20,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Hero(
              tag: 'profile',
              child: GestureDetector(
                onTap: () {
                  if (BottomNavScreen.switchTab != null) {
                    BottomNavScreen.switchTab!(3);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AccountTabScreen(
                              userData: widget.userData,
                              onLogout: () {},
                            ),
                      ),
                    ).then((_) => loadUserData());
                  }
                },
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
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
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

          // 3. Categories Grid: Responsive Wrapping (4 items per line on mobile, wraps to new line)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                int count = 4;
                if (totalWidth >= 680) {
                  count = 6;
                } else if (totalWidth >= 520) {
                  count = 5;
                } else if (totalWidth < 300) {
                  count = 3;
                } else {
                  count = 4; // 4 items per row on mobile (exact same layout & styling as original)
                }
                final double itemWidth = totalWidth / count;

                final items = [
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
                        builder: (context) => AllDoctorsScreen(userData: widget.userData, filterRegistrationType: 'doctor'),
                      ),
                    ),
                  ),
                  // 2. Physiotherapist & Allied Care
                  _categoryCircleItem(
                    title: "Physiotherapy\n& Allied Care",
                    color: const Color(0xFFD97706),
                    customIcon: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.accessibility_new_rounded, color: Color(0xFFD97706), size: 24),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.healing_rounded, color: Color(0xFFB45309), size: 11),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllDoctorsScreen(
                          userData: widget.userData,
                          filterRegistrationType: 'others',
                          pageTitle: 'Physiotherapist & Allied Care',
                        ),
                      ),
                    ),
                  ),
                  // 3. Pathology Tests
                  _categoryCircleItem(
                    title: "Pathology\nTests",
                    color: const Color(0xFF2E7D32),
                    customIcon: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.biotech_rounded, color: Color(0xFF2E7D32), size: 24),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.science_rounded, color: Color(0xFF1B5E20), size: 10),
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
                  // 4. Chambers (OPD)
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
                  // 5. Appointments
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
                  // 6. Prescriptions
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
                  // 7. Reports
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
                  // 8. Pay Your Bills
                  _categoryCircleItem(
                    title: "My Bills\n& Payments",
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
                  // 9. Call Ambulance
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
                ];

                return Wrap(
                  spacing: 0,
                  runSpacing: 18,
                  children: items.map((item) => SizedBox(
                    width: itemWidth,
                    child: item,
                  )).toList(),
                );
              },
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

          // 7. Popular Health Checkups Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHealthCheckupsSection(),
          ),

          const SizedBox(height: 22),

          // 8. Find Doctor by Health Concern Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHealthConcernSection(),
          ),

          // Generous bottom spacing so bottom nav bar floating button doesn't overlap
          const SizedBox(height: 100),
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
    return GestureDetector(
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
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstantVideoConsultCard() {
    void navigateToConsult() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllDoctorsScreen(userData: widget.userData),
        ),
      );
    }

    return GestureDetector(
      onTap: navigateToConsult,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                      onPressed: navigateToConsult,
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
      ),
    );
  }

  Widget _buildNeedHelpBanner() {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('tel:+916292237207')),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF00695C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withAlpha(50),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background watermark
            Positioned(
              right: -12,
              bottom: -15,
              child: Icon(
                Icons.support_agent_rounded,
                size: 85,
                color: Colors.white.withAlpha(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Agent / Headset Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "24/7 HELPLINE",
                              style: TextStyle(
                                color: Color(0xFF86EFAC),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Need Medical Help?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          "Call our care team for instant support",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sleek Call Now Action Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_rounded, size: 13, color: Color(0xFF0D47A1)),
                        SizedBox(width: 4),
                        Text(
                          "Call Now",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
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

  // 1. Featured Pathology Partners (Auto-Scrolling 10 Data with tests & minimal details)
  Widget _buildHealthCheckupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lab Tests",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllAvailablePathologyScreen(userData: widget.userData),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "View All →",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingPathology && _pathologyPartners.isEmpty)
          Container(
            height: 146,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.blueGrey.withAlpha(20)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B), strokeWidth: 2.5),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 146,
                child: PageView.builder(
                  controller: _pathologyPageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPathologyIndex = index;
                    });
                  },
                  itemCount: _pathologyPartners.length,
                  itemBuilder: (context, index) {
                    final partner = _pathologyPartners[index];
                    return _buildPathologyPartnerCard(partner, index);
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Auto-Scroll Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pathologyPartners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: _currentPathologyIndex == index ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _currentPathologyIndex == index
                          ? const Color(0xFF00897B)
                          : Colors.blueGrey.withAlpha(45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPathologyPartnerCard(AllAvailablePathModel partner, int index) {
    // Extract ONLY actual real tests from the API
    final List<String> testsList = [];
    if (partner.tests.isNotEmpty) {
      for (var t in partner.tests) {
        if (t is Map && t['test_name'] != null) {
          final tName = t['test_name'].toString().trim();
          if (tName.isNotEmpty && !testsList.contains(tName)) {
            testsList.add(tName);
          }
        }
      }
    }

    final List<String> servicesList = [];
    if (partner.services.isNotEmpty) {
      for (var s in partner.services) {
        if (s is Map && s['service_name'] != null) {
          final sName = s['service_name'].toString().trim();
          if (sName.isNotEmpty && !servicesList.contains(sName)) {
            servicesList.add(sName);
          }
        } else if (s is String && s.trim().isNotEmpty) {
          servicesList.add(s.trim());
        }
      }
    }

    final clinicDisplayName = partner.clinicName.trim().isNotEmpty
        ? partner.clinicName.trim()
        : 'Certified Diagnostic Centre';
    final locationText = partner.clinicAddress.trim().isNotEmpty
        ? partner.clinicAddress.trim()
        : (partner.clinicCity.trim().isNotEmpty ? partner.clinicCity.trim() : 'Verified Pathology Lab');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PathologyDetailsScreen(
            pathology: partner,
            userData: widget.userData,
          ),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.withAlpha(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Lab Avatar + Clinic Name & Location + Partner Badge
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.biotech_rounded,
                    color: Color(0xFF00897B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: Color(0xFFE53935),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 10, color: Color(0xFF00897B)),
                      const SizedBox(width: 3),
                      Text(
                        testsList.isNotEmpty ? "${testsList.length} Tests" : "Verified Lab",
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // Middle: Tests Provided
            if (testsList.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science_rounded, size: 11, color: Color(0xFF00897B)),
                      const SizedBox(width: 3),
                      Text(
                        "Available Tests (${testsList.length}):",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...testsList.take(4).map((test) => Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.blueGrey.withAlpha(25)),
                              ),
                              child: Text(
                                test,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            )),
                        if (testsList.length > 4)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B).withAlpha(12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              "+${testsList.length - 4} more",
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00897B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            else if (servicesList.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services_rounded, size: 11, color: Color(0xFF00897B)),
                      const SizedBox(width: 3),
                      Text(
                        "Services (${servicesList.length}):",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...servicesList.take(4).map((svc) => Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.blueGrey.withAlpha(25)),
                              ),
                              child: Text(
                                svc,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            )),
                        if (servicesList.length > 4)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B).withAlpha(12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              "+${servicesList.length - 4} more",
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00897B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blueGrey.withAlpha(20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF64748B)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "Tap below to view full lab schedule & book tests",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 7),

            // Bottom Row: Action Button aligned right
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withAlpha(35),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Book Test",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 10.5, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Consult Doctor by Dynamic Specialties (Random 10, manual scroll)
  Widget _buildHealthConcernSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Departments",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Find & consult verified specialists",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllDoctorsScreen(userData: widget.userData),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "All Doctors →",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSpecialties)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(4, (index) => Container(
                width: 90,
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.withAlpha(25)),
                ),
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueGrey.withAlpha(70)),
                  ),
                ),
              )),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _doctorSpecialties.map((specialtyName) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllDoctorsScreen(
                        userData: widget.userData,
                        initialSearchQuery: specialtyName,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      specialtyName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
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

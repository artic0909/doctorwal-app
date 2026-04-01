import 'package:demoapp/allopdscreen.dart';
import 'package:demoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alldoctorsscreen.dart';
import 'allavailablepathologyscreen.dart';
import 'contactscreen.dart';
import 'notificationscreen.dart';
import 'profileeditscreen.dart';
import 'package:demoapp/healthparametersscreen.dart';
import 'package:demoapp/addvitalscreen.dart';
import 'package:demoapp/medicalhistoryscreen.dart';
import 'package:demoapp/addmedicalrecordscreen.dart';
import 'package:demoapp/search_screen.dart';
import 'package:demoapp/all_appointments_screen.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/privacypolicyscreen.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

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
  bool _hasScrolled = false;

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
    
    // Discovery Animation: Peek at scrollable content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_horizontalScrollController.hasClients && !_hasScrolled) {
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
      if (memberId.trim().isEmpty)
        memberId = widget.userData['member_id']?.toString() ?? '';
      if (memberId.trim().isEmpty)
        memberId = widget.userData['memberid']?.toString() ?? '';
      if (memberId.trim().isEmpty) memberId = 'DW-2026-CARD';

      // Aggressive key checking for medicalCardNo
      medicalCardNo = prefs.getString('medical_card_no') ?? '';
      if (medicalCardNo.trim().isEmpty)
        medicalCardNo = prefs.getString('medicalcardno') ?? '';
      if (medicalCardNo.trim().isEmpty)
        medicalCardNo = widget.userData['medical_card_no']?.toString() ?? '';
      if (medicalCardNo.trim().isEmpty)
        medicalCardNo = widget.userData['medicalcardno']?.toString() ?? '';
      if (medicalCardNo.trim().isEmpty) medicalCardNo = 'DW26 0000 00';

      profileImg =
          prefs.getString('image') ??
          widget.userData['image']?.toString() ??
          '';
    });
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
      Navigator.pushReplacement(
        context,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${response.body}')),
        );
      }
    } catch (e) {
      // If error (e.g. 401), just clear and go back
      await prefs.clear();
      Navigator.pushReplacement(
        context,
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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical card generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to generate card'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isGeneratingCard = false);
    }
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
      drawer: _buildPremiumDrawer(
        context,
        currentName,
        dispMemberId,
        currentProfileImg,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder:
                  (context) => GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withAlpha(12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF1565C0),
                        size: 24,
                      ),
                    ),
                  ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello,",
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currentName,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // --- Notification Bell ---
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.blueGrey[600],
                    size: 26,
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
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
      body: Column(
        children: [
          // 1. Premium Search Bar (Interactive)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchScreen(userData: widget.userData),
                    ),
                  ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF1565C0),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Search doctor, clinic, test...",
                            style: TextStyle(
                              color: Colors.blueGrey[200],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFE53935),
                            size: 18,
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withAlpha(76),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Dynamic Virtual Medical Card (Creation Card)
          if (!hasCard) ...[
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.credit_card_off_rounded,
                    color: Colors.white54,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Medical Card Not Found",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: isGeneratingCard ? null : _generateMedicalCard,
                    icon:
                        isGeneratingCard
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF1565C0),
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.add_card_rounded),
                    label: Text(
                      isGeneratingCard ? "Generating..." : "Create Now",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],

          // 3. Category List Heading (Fixed)
          // 4. One-by-One Categories (Scrollable)
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              children: [
                _newCategoryCard(
                  title: "OPD Doctors & Clinics",
                  subtitle: "Book clinical appointments instantly",
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFFE53935),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllAvailableOPDScreen(
                                userData: widget.userData,
                              ),
                        ),
                      ),
                ),
                _newCategoryCard(
                  title: "Pathology Tests & Labs",
                  subtitle: "Certified diagnostic testing at home",
                  icon: Icons.biotech_rounded,
                  color: const Color(0xFF00C853),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllAvailablePathologyScreen(
                                userData: widget.userData,
                              ),
                        ),
                      ),
                ),
                _newCategoryCard(
                  title: "Individual Specialist Doctors",
                  subtitle: "Connect with top experts in 50+ specialties",
                  icon: Icons.personal_injury_rounded,
                  color: const Color(0xFF1565C0),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllDoctorsScreen(userData: widget.userData),
                        ),
                      ),
                ),
                _newCategoryCard(
                  title: "24/7 Support",
                  subtitle: "Immediate medical assistance & help",
                  icon: Icons.support_agent_rounded,
                  color: const Color(0xFFFFAB00),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactScreen(),
                        ),
                      ),
                ),

                const SizedBox(height: 20),

                Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          if (notification.metrics.pixels > 30 && !_hasScrolled) {
                            setState(() => _hasScrolled = true);
                          }
                        }
                        return true;
                      },
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _eyeCatchyBox(
                              title: "Medical Reports",
                              subtitle: "Test results",
                              icon: Icons.assignment_rounded,
                              gradient: [
                                const Color(0xFF7E57C2),
                                const Color(0xFF512DA8),
                              ],
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const MedicalHistoryScreen(
                                            initialTabIndex: 0,
                                          ),
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            _eyeCatchyBox(
                              title: "Prescriptions",
                              subtitle: "Digital RX",
                              icon: Icons.medication_rounded,
                              gradient: [
                                const Color(0xFF26A69A),
                                const Color(0xFF00796B),
                              ],
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const MedicalHistoryScreen(
                                            initialTabIndex: 1,
                                          ),
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            _eyeCatchyBox(
                              title: "Appointments",
                              subtitle: "Track visits",
                              icon: Icons.calendar_today_rounded,
                              gradient: [
                                const Color(0xFFF06292),
                                const Color(0xFFC2185B),
                              ],
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AllAppointmentsScreen(
                                            userData: widget.userData,
                                          ),
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            _eyeCatchyBox(
                              title: "Health Parameters",
                              subtitle: "Monitor metrics",
                              icon: Icons.monitor_heart_rounded,
                              gradient: [
                                const Color(0xFF5C6BC0),
                                const Color(0xFF3949AB),
                              ],
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const HealthParametersScreen(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Animated Scroll Hint
                    if (!_hasScrolled)
                      Positioned(
                        right: 10,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: (1.0 - value).clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withAlpha(0),
                                        Colors.white.withAlpha(150),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Transform.translate(
                                      offset: Offset(-20 * (1 - value % 1), 0),
                                      child: const Icon(
                                        Icons.swipe_left_rounded,
                                        color: Color(0xFF1565C0),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildWellnessHub(),
                const SizedBox(height: 40),
              ],
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
    // Peek effect: show roughly 3.1 cards to hint at more content
    final double cardWidth = (MediaQuery.of(context).size.width - 48) / 3.1;
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

  Widget _newCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.blueGrey[100],
              size: 16,
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
                      Share.share(
                        'Download the Doctorwala app for your health needs: https://play.google.com/store/apps/details?id=com.doctorwala.dochealth&hl=en_IN',
                        subject: 'Join Doctorwala',
                      );
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

  Widget _buildPremiumDrawer(
    BuildContext context,
    String name,
    String memberId,
    String profileImg,
  ) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Premium Immersive Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            profileImg.isNotEmpty
                                ? NetworkImage(_getImageUrl(profileImg))
                                : null,
                        child:
                            profileImg.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Color(0xFF1565C0),
                                )
                                : null,
                      ),
                    ),
                    Row(
                      children: [
                        _logoutIconButton(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    memberId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _drawerItem(
                  Icons.home_rounded,
                  "Home",
                  () => Navigator.pop(context),
                  isSelected: true,
                ),
                _drawerItem(Icons.medication_rounded, "Prescriptions", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const MedicalHistoryScreen(initialTabIndex: 1),
                    ),
                  );
                }),
                _drawerItem(Icons.assignment_rounded, "Medical Reports", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const MedicalHistoryScreen(initialTabIndex: 0),
                    ),
                  );
                }),
                _drawerItem(Icons.note_add_rounded, "Add Medical Records", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMedicalRecordScreen(),
                    ),
                  );
                }),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("Health management"),
                _drawerItem(Icons.analytics_rounded, "Health Parameters", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthParametersScreen(),
                    ),
                  );
                }),
                _drawerItem(
                  Icons.add_moderator_rounded,
                  "Add Health Parameters",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddVitalScreen(),
                      ),
                    );
                  },
                ),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("appointments & notifications"),
                _drawerItem(Icons.calendar_month_rounded, "Appointments", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AllAppointmentsScreen(userData: widget.userData),
                    ),
                  );
                }),
                _drawerItem(
                  Icons.notifications_active_rounded,
                  "Notifications",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("Account & support"),
                _drawerItem(Icons.person_rounded, "My Profile", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ProfileEditScreen(userData: widget.userData),
                    ),
                  ).then((_) => loadUserData());
                }),
                _drawerItem(Icons.support_agent_rounded, "24/7 Support", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactScreen(),
                    ),
                  );
                }),
                _drawerItem(Icons.policy_rounded, "Privacy & Policy", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                }),

                const SizedBox(height: 30),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Version 2.1.2",
              style: TextStyle(
                color: Colors.blueGrey[200],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    bool isSelected = false,
  }) {
    final Color brandColor = const Color(0xFF1565C0);
    final Color iconColor =
        color ?? (isSelected ? brandColor : const Color(0xFF546E7A));
    final Color textColor = isSelected ? brandColor : const Color(0xFF263238);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? brandColor.withAlpha(20)
                    : Colors.blueGrey[50]?.withAlpha(128),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      cleanPath = 'storage/' + cleanPath;
    }

    return domain + cleanPath;
  }

  Widget _logoutIconButton() {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => logout(),
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        tooltip: "Logout",
      ),
    );
  }
}

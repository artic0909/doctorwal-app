import 'package:demoapp/allopdscreen.dart';
import 'package:demoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aboutscreen.dart';
import 'alldoctorsscreen.dart';
import 'allavailablepathologyscreen.dart';
import 'contactscreen.dart';
import 'notificationscreen.dart';
import 'profileeditscreen.dart';
import 'package:demoapp/healthparametersscreen.dart';
import 'package:demoapp/addvitalscreen.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? widget.userData['name'] ?? widget.userData['user_name'] ?? 'User';
      email = prefs.getString('email') ?? widget.userData['email'] ?? widget.userData['user_email'] ?? '';
      
      // Aggressive key checking for memberId
      memberId = prefs.getString('member_id') ?? '';
      if (memberId.trim().isEmpty) memberId = prefs.getString('memberid') ?? '';
      if (memberId.trim().isEmpty) memberId = widget.userData['member_id']?.toString() ?? '';
      if (memberId.trim().isEmpty) memberId = widget.userData['memberid']?.toString() ?? '';
      if (memberId.trim().isEmpty) memberId = 'DW-2026-CARD';

      // Aggressive key checking for medicalCardNo
      medicalCardNo = prefs.getString('medical_card_no') ?? '';
      if (medicalCardNo.trim().isEmpty) medicalCardNo = prefs.getString('medicalcardno') ?? '';
      if (medicalCardNo.trim().isEmpty) medicalCardNo = widget.userData['medical_card_no']?.toString() ?? '';
      if (medicalCardNo.trim().isEmpty) medicalCardNo = widget.userData['medicalcardno']?.toString() ?? '';
      if (medicalCardNo.trim().isEmpty) medicalCardNo = 'DW26 0000 00';

      profileImg = prefs.getString('image') ?? widget.userData['image']?.toString() ?? '';
    });
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
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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

  @override
  Widget build(BuildContext context) {
    // Use local state if it's available, otherwise fallback to widget data
    final String currentName = name.isNotEmpty && name != 'User' ? name : (widget.userData['name'] ?? widget.userData['user_name'] ?? 'Guest');
    
    // Member ID Fallback logic
    String dispMemberId = memberId;
    if (dispMemberId.trim().isEmpty || dispMemberId == 'DW-0000-000' || dispMemberId == 'DW-2026-CARD') {
      dispMemberId = (widget.userData['member_id'] ?? widget.userData['memberid'] ?? 'DW-2026-CARD').toString();
    }

    // Card No Fallback logic
    String dispCardNo = medicalCardNo;
    if (dispCardNo.trim().isEmpty || dispCardNo == 'DW00 0000 00' || dispCardNo == 'DW01 0001 001' || dispCardNo == 'DW26 0000 00') {
      dispCardNo = (widget.userData['medical_card_no'] ?? widget.userData['medicalcardno'] ?? 'DW26 0000 00').toString();
    }

    final String currentProfileImg = profileImg.isNotEmpty ? profileImg : (widget.userData['image']?.toString() ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      drawer: _buildPremiumDrawer(context, currentName, dispMemberId, currentProfileImg),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_rounded, color: Color(0xFF1565C0), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello,",
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  currentName,
                  style: const TextStyle(color: Color(0xFF263238), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Spacer(),
            // --- Notification Bell ---
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: Colors.blueGrey[600], size: 26),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
            Hero(
              tag: 'profile',
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileEditScreen(userData: widget.userData)),
                ).then((_) => loadUserData()),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1565C0).withAlpha(38), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueGrey[50],
                    backgroundImage: currentProfileImg.isNotEmpty ? NetworkImage(_getImageUrl(currentProfileImg)) : null,
                    child: currentProfileImg.isEmpty ? const Icon(Icons.person_rounded, size: 20, color: Color(0xFF1565C0)) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Search & Location Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search medical services...",
                          hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                          prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
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
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // 2. Dynamic Virtual Medical Card
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
              child: Stack(
                children: [
                  // Subtle Pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.health_and_safety_rounded, size: 150, color: Colors.white.withAlpha(25)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/logo.png', height: 30, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              "DOCTORWALA MEDICAL CARD",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            const Spacer(),
                            const Icon(Icons.nfc_rounded, color: Colors.white70, size: 20),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          dispCardNo,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: 4),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("CARD HOLDER", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                Text(currentName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("MEMBER ID", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                Text(dispMemberId, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. Category List Heading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Text(
                    "Medical Ecosystem",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                  ),
                  Spacer(),
                  Text(
                    "View All",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. One-by-One Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _newCategoryCard(
                    title: "Specialist Doctors",
                    subtitle: "Connect with top experts in 50+ specialties",
                    icon: Icons.personal_injury_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllDoctorsScreen())),
                  ),
                  _newCategoryCard(
                    title: "Advanced OPD",
                    subtitle: "Book clinical appointments instantly",
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFFE53935),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllAvailableOPDScreen(userData: widget.userData))),
                  ),
                  _newCategoryCard(
                    title: "Pathology Labs",
                    subtitle: "Certified diagnostic testing at home",
                    icon: Icons.biotech_rounded,
                    color: const Color(0xFF00C853),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllAvailablePathologyScreen(userData: widget.userData))),
                  ),
                  _newCategoryCard(
                    title: "24/7 Support",
                    subtitle: "Immediate medical assistance & help",
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFFFFAB00),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[300], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.blueGrey[100], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumDrawer(BuildContext context, String name, String memberId, String profileImg) {
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
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImg.isNotEmpty ? NetworkImage(_getImageUrl(profileImg)) : null,
                        child: profileImg.isEmpty ? const Icon(Icons.person, size: 30, color: Color(0xFF1565C0)) : null,
                      ),
                    ),
                    Row(
                      children: [
                        _logoutIconButton(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 26),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    memberId,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                _drawerItem(Icons.home_rounded, "Home", () => Navigator.pop(context), isSelected: true),
                _drawerItem(Icons.notifications_active_rounded, "Notifications", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                }),
                _drawerItem(Icons.calendar_month_rounded, "Appointments", () {}),
                
                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("Health Management"),
                _drawerItem(Icons.monitor_heart_rounded, "Health Parameters", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthParametersScreen()));
                }),
                _drawerItem(Icons.add_moderator_rounded, "Add health parameters", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVitalScreen()));
                }),
                _drawerItem(Icons.note_add_rounded, "Add Medical Records", () {}),
                _drawerItem(Icons.assignment_rounded, "Reports", () {}),
                _drawerItem(Icons.medication_rounded, "Prescriptions", () {}),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("Account & Support"),
                _drawerItem(Icons.person_rounded, "My Profile", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(userData: widget.userData))).then((_) => loadUserData());
                }),
                _drawerItem(Icons.support_agent_rounded, "24/7 Support", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen()));
                }),
                _drawerItem(Icons.info_rounded, "About", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                }),
                _drawerItem(Icons.policy_rounded, "Privacy & Policy", () {}),

                const SizedBox(height: 30),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Version 2.1.2",
              style: TextStyle(color: Colors.blueGrey[200], fontSize: 12, fontWeight: FontWeight.w500),
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
        style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color, bool isSelected = false}) {
    final Color brandColor = const Color(0xFF1565C0);
    final Color iconColor = color ?? (isSelected ? brandColor : const Color(0xFF546E7A));
    final Color textColor = isSelected ? brandColor : const Color(0xFF263238);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? brandColor.withAlpha(20) : Colors.blueGrey[50]?.withAlpha(128),
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
      decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
      child: IconButton(
        onPressed: () => logout(),
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        tooltip: "Logout",
      ),
    );
  }
}

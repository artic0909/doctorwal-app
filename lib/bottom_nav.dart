import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:demoapp/categoryscreen.dart';
import 'package:demoapp/all_appointments_screen.dart';
import 'package:demoapp/search_screen.dart';
import 'package:demoapp/medicalhistoryscreen.dart';
import 'package:demoapp/bmr.dart';
import 'package:demoapp/notificationscreen.dart';
import 'package:demoapp/profileeditscreen.dart';
import 'package:demoapp/contactscreen.dart';
import 'package:demoapp/healthparametersscreen.dart';
import 'package:demoapp/addvitalscreen.dart';
import 'package:demoapp/privacypolicyscreen.dart';
import 'package:demoapp/main.dart'; // For LoginScreen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BottomNavScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  static final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();

  const BottomNavScreen({super.key, required this.userData});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CategoryHomeScreen(userData: widget.userData),
      AllAppointmentsScreen(userData: widget.userData),
      SearchScreen(userData: widget.userData),
      const MedicalHistoryScreen(initialTabIndex: 1, isTab: true), // Prescriptions
      const MedicalHistoryScreen(initialTabIndex: 0, isTab: true), // Reports
    ];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (!mounted) return;
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
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${response.body}')),
        );
      }
    } catch (e) {
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;

    const String domain = "https://doctorwala.info/";
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
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
    const Color brandColor = Color(0xFF1565C0);
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
                        backgroundImage: profileImg.isNotEmpty ? NetworkImage(_getImageUrl(profileImg)) : null,
                        child: profileImg.isEmpty
                            ? const Icon(Icons.person, size: 30, color: Color(0xFF1565C0))
                            : null,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
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
                _drawerItem(
                  Icons.home_rounded,
                  "Home",
                  () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                  isSelected: _currentIndex == 0,
                ),
                _drawerItem(Icons.medication_rounded, "Prescriptions", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                }, isSelected: _currentIndex == 3),
                _drawerItem(Icons.assignment_rounded, "Test & Lab Reports", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                }, isSelected: _currentIndex == 4),
                _drawerItem(Icons.calculate, "BMR Calculator", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BMRCalculatorScreen()),
                  );
                }),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("appointments & notifications"),
                _drawerItem(Icons.calendar_month_rounded, "Appointments", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                }, isSelected: _currentIndex == 1),
                _drawerItem(Icons.notifications_active_rounded, "Notifications", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                }),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("Health Vitals"),
                _drawerItem(Icons.analytics_rounded, "Health Parameters", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HealthParametersScreen()),
                  );
                }),
                _drawerItem(Icons.add_moderator_rounded, "Add Health Parameters", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddVitalScreen()),
                  );
                }),

                const Divider(indent: 20, endIndent: 20),
                _drawerSectionTitle("Account & support"),
                _drawerItem(Icons.person_rounded, "My Profile", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileEditScreen(userData: widget.userData)),
                  );
                }),
                _drawerItem(Icons.support_agent_rounded, "24/7 Support", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactScreen()),
                  );
                }),
                _drawerItem(Icons.policy_rounded, "Privacy & Policy", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                }),

                const SizedBox(height: 30),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Doctorwala Patient",
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

  @override
  Widget build(BuildContext context) {
    String currentName = widget.userData['name'] ?? widget.userData['user_name'] ?? 'User';
    String dispMemberId = widget.userData['member_id']?.toString() ?? 'DW-2026-CARD';
    String currentProfileImg = widget.userData['image']?.toString() ?? '';

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: BottomNavScreen.globalScaffoldKey,
        extendBody: true,
        drawer: _buildPremiumDrawer(context, currentName, dispMemberId, currentProfileImg),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Lighter blur
            child: Container(
              height: 65, // Sufficient touch area
              padding: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(245), // More solid white, less glass
                border: Border(
                  top: BorderSide(
                    color: Colors.blueGrey.withAlpha(30),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, "Home", 0, context),
                  _buildNavItem(Icons.calendar_today_rounded, "Appts", 1, context),
                  _buildNavItem(Icons.search_rounded, "Search", 2, context),
                  _buildNavItem(Icons.medication_rounded, "Rx", 3, context),
                  _buildNavItem(Icons.assignment_rounded, "Reports", 4, context),
                  _buildNavItem(Icons.menu_rounded, "More", 5, context), // More opens drawer
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, BuildContext context) {
    bool isSelected = _currentIndex == index;
    bool isMore = index == 5;
    
    return GestureDetector(
      onTap: () {
        if (isMore) {
          BottomNavScreen.globalScaffoldKey.currentState?.openDrawer();
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected && !isMore ? const Color(0xFF1565C0).withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected && !isMore ? const Color(0xFF1565C0) : Colors.blueGrey.withAlpha(180),
              size: isSelected && !isMore ? 24 : 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected && !isMore ? const Color(0xFF1565C0) : Colors.blueGrey.withAlpha(180),
                fontSize: 9,
                fontWeight: isSelected && !isMore ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

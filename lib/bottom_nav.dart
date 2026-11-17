import 'package:flutter/material.dart';
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
import 'package:flutter/services.dart' as import_services;

class BottomNavScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  static final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();

  const BottomNavScreen({super.key, required this.userData});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const TabNavigator({super.key, required this.navigatorKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  final List<int> _tabKeys = [0, 0, 0, 0, 0];
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTabSelected(int index) {
    if (index == 5) {
      BottomNavScreen.globalScaffoldKey.currentState?.openDrawer();
      return;
    }
    setState(() {
      if (_currentIndex != index) {
        // Switch tab smoothly without destroying IndexedStack pages
        _currentIndex = index;
      } else {
        // When tapping the already-active tab, pop to root if deep in navigation
        final navState = _navigatorKeys[index].currentState;
        if (navState != null && navState.canPop()) {
          navState.popUntil((route) => route.isFirst);
        }
      }
    });
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return TabNavigator(
          key: ValueKey('tab_0_${_tabKeys[0]}'),
          navigatorKey: _navigatorKeys[0],
          child: CategoryHomeScreen(
            key: ValueKey('home_${_tabKeys[0]}'),
            userData: widget.userData,
          ),
        );
      case 1:
        return TabNavigator(
          key: ValueKey('tab_1_${_tabKeys[1]}'),
          navigatorKey: _navigatorKeys[1],
          child: AllAppointmentsScreen(
            key: ValueKey('appts_${_tabKeys[1]}'),
            userData: widget.userData,
          ),
        );
      case 2:
        return TabNavigator(
          key: ValueKey('tab_2_${_tabKeys[2]}'),
          navigatorKey: _navigatorKeys[2],
          child: SearchScreen(
            key: ValueKey('search_${_tabKeys[2]}'),
            userData: widget.userData,
          ),
        );
      case 3:
        return TabNavigator(
          key: ValueKey('tab_3_${_tabKeys[3]}'),
          navigatorKey: _navigatorKeys[3],
          child: MedicalHistoryScreen(
            key: ValueKey('prescriptions_${_tabKeys[3]}'),
            initialTabIndex: 1,
            isTab: true,
          ),
        );
      case 4:
        return TabNavigator(
          key: ValueKey('tab_4_${_tabKeys[4]}'),
          navigatorKey: _navigatorKeys[4],
          child: MedicalHistoryScreen(
            key: ValueKey('reports_${_tabKeys[4]}'),
            initialTabIndex: 0,
            isTab: true,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
                    _onTabSelected(0);
                  },
                  isSelected: _currentIndex == 0,
                ),
                _drawerItem(Icons.medication_rounded, "Prescriptions", () {
                  Navigator.pop(context);
                  _onTabSelected(3);
                }, isSelected: _currentIndex == 3),
                _drawerItem(Icons.assignment_rounded, "Test & Lab Reports", () {
                  Navigator.pop(context);
                  _onTabSelected(4);
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
                  _onTabSelected(1);
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

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Doctorwala Patient",
                style: TextStyle(
                  color: Colors.blueGrey[200],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final NavigatorState? currentNavigator = _navigatorKeys[_currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return;
        }

        if (_currentIndex != 0) {
          _onTabSelected(0);
        } else {
          // If we are on the Home tab and cannot pop the inner navigator, exit the app
          import_services.SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: BottomNavScreen.globalScaffoldKey,
        extendBody: false,
        drawer: _buildPremiumDrawer(context, currentName, dispMemberId, currentProfileImg),
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(5, _buildTab),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.blueGrey.withAlpha(25),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom,
            ),
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  Expanded(child: _buildNavItem(Icons.home_rounded, "Home", 0, context)),
                  Expanded(child: _buildNavItem(Icons.calendar_today_rounded, "Appts", 1, context)),
                  Expanded(child: _buildNavItem(Icons.search_rounded, "Search", 2, context)),
                  Expanded(child: _buildNavItem(Icons.medication_rounded, "Prescribe", 3, context)),
                  Expanded(child: _buildNavItem(Icons.assignment_rounded, "Reports", 4, context)),
                  Expanded(child: _buildNavItem(Icons.menu_rounded, "More", 5, context)),
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
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected && !isMore ? const Color(0xFF1565C0).withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected && !isMore ? const Color(0xFF1565C0) : Colors.blueGrey.withAlpha(180),
                size: isSelected && !isMore ? 22 : 20,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected && !isMore ? const Color(0xFF1565C0) : Colors.blueGrey.withAlpha(180),
                    fontSize: 9.5,
                    fontWeight: isSelected && !isMore ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

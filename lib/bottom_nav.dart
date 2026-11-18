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
import 'package:demoapp/my_health_screen.dart';
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

class _BottomNavScreenState extends State<BottomNavScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<int> _tabKeys = [0, 0, 0, 0];
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late AnimationController _notchController;
  late Animation<double> _notchAnim;

  @override
  void initState() {
    super.initState();
    _notchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _notchAnim = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _notchController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      _notchAnim = Tween<double>(
        begin: _notchAnim.value,
        end: index.toDouble(),
      ).animate(
        CurvedAnimation(parent: _notchController, curve: Curves.easeInOutCubic),
      );
      _notchController.forward(from: 0.0);
      setState(() {
        _currentIndex = index;
      });
    } else {
      final navState = _navigatorKeys[index].currentState;
      if (navState != null && navState.canPop()) {
        navState.popUntil((route) => route.isFirst);
      }
    }
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.search_rounded;
      case 2:
        return Icons.volunteer_activism_rounded;
      case 3:
        return Icons.person_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF1565C0); // Home: Royal Blue
      case 1:
        return const Color(0xFFEA580C); // Search: Vibrant Sunset Orange
      case 2:
        return const Color(0xFF00897B); // My Health: Medical Teal
      case 3:
        return const Color(0xFF7C3AED); // Account: Clinical Violet / Purple
      default:
        return const Color(0xFF1565C0);
    }
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
          child: SearchScreen(
            key: ValueKey('search_${_tabKeys[1]}'),
            userData: widget.userData,
          ),
        );
      case 2:
        return TabNavigator(
          key: ValueKey('tab_2_${_tabKeys[2]}'),
          navigatorKey: _navigatorKeys[2],
          child: MyHealthScreen(
            key: ValueKey('health_${_tabKeys[2]}'),
            userData: widget.userData,
          ),
        );
      case 3:
        return TabNavigator(
          key: ValueKey('tab_3_${_tabKeys[3]}'),
          navigatorKey: _navigatorKeys[3],
          child: AccountTabScreen(
            key: ValueKey('account_${_tabKeys[3]}'),
            userData: widget.userData,
            onLogout: logout,
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
        backgroundColor: const Color(0xFFF8FAFF),
        drawer: _buildPremiumDrawer(context, currentName, dispMemberId, currentProfileImg),
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, _buildTab),
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            // Responsive scale factor based on standard mobile width 375dp (iPhone / standard Android)
            final scale = (w / 375.0).clamp(0.92, 1.25);

            final itemWidth = w / 4;
            final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
            final barHeight = (60.0 * scale).clamp(58.0, 68.0);
            final totalHeight = barHeight + bottomPadding;

            // Responsive dimensions for active button and notch
            final activeBtnSize = (52.0 * scale).clamp(50.0, 58.0);
            final activeInnerSize = activeBtnSize - 8.0;
            final activeIconSize = (24.0 * scale).clamp(23.0, 28.0);

            final notchRadius = (activeBtnSize / 2) + 5.5;
            final shoulderRadius = (14.0 * scale).clamp(13.0, 17.0);
            final depth = (22.0 * scale).clamp(21.0, 26.0);
            final topRadius = (22.0 * scale).clamp(20.0, 26.0);

            // Responsive dimensions for inactive bar items
            final inactiveIconSize = (23.5 * scale).clamp(22.5, 27.0);
            final inactiveFontSize = (10.5 * scale).clamp(10.5, 12.5);

            return AnimatedBuilder(
              animation: _notchController,
              builder: (context, child) {
                final currentPos = _notchAnim.value;
                final cx = (currentPos + 0.5) * itemWidth;

                return SizedBox(
                  width: w,
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Smooth Custom Curved Notched Background
                      CustomPaint(
                        size: Size(w, totalHeight),
                        painter: CurvedNotchPainter(
                          centerX: cx,
                          color: Colors.white,
                          canvasBackgroundColor: const Color(0xFFF8FAFF),
                          notchRadius: notchRadius,
                          shoulderRadius: shoulderRadius,
                          depth: depth,
                          topRadius: topRadius,
                        ),
                        child: SizedBox(
                          width: w,
                          height: totalHeight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bottomPadding, top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildBarItem(
                                    Icons.home_outlined,
                                    "Home",
                                    0,
                                    iconSize: inactiveIconSize,
                                    fontSize: inactiveFontSize,
                                  ),
                                ),
                                Expanded(
                                  child: _buildBarItem(
                                    Icons.search_rounded,
                                    "Search",
                                    1,
                                    iconSize: inactiveIconSize,
                                    fontSize: inactiveFontSize,
                                  ),
                                ),
                                Expanded(
                                  child: _buildBarItem(
                                    Icons.volunteer_activism_outlined,
                                    "My Health",
                                    2,
                                    iconSize: inactiveIconSize,
                                    fontSize: inactiveFontSize,
                                  ),
                                ),
                                Expanded(
                                  child: _buildBarItem(
                                    Icons.person_outline_rounded,
                                    "Account",
                                    3,
                                    iconSize: inactiveIconSize,
                                    fontSize: inactiveFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Raised Active Circular Floating Button
                      Positioned(
                        left: cx - (activeBtnSize / 2),
                        top: -(activeBtnSize * 0.3),
                        child: GestureDetector(
                          onTap: () => _onTabSelected(_currentIndex),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: activeBtnSize,
                            height: activeBtnSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: _getTabColor(_currentIndex).withAlpha(55),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: activeInnerSize,
                                height: activeInnerSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getTabColor(_currentIndex).withAlpha(24),
                                ),
                                child: Icon(
                                  _getTabIcon(_currentIndex),
                                  color: _getTabColor(_currentIndex),
                                  size: activeIconSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarItem(
    IconData icon,
    String label,
    int index, {
    required double iconSize,
    required double fontSize,
  }) {
    final bool isSelected = _currentIndex == index;
    final tabColor = _getTabColor(index);

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isSelected ? 0.0 : 1.0,
              child: Icon(
                icon,
                color: const Color(0xFF94A3B8),
                size: iconSize,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? tabColor : const Color(0xFF64748B),
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvedNotchPainter extends CustomPainter {
  final double centerX;
  final Color color;
  final Color canvasBackgroundColor;
  final double notchRadius;
  final double shoulderRadius;
  final double depth;
  final double topRadius;

  CurvedNotchPainter({
    required this.centerX,
    this.color = Colors.white,
    this.canvasBackgroundColor = const Color(0xFFF8FAFF),
    this.notchRadius = 31.0,
    this.shoulderRadius = 14.0,
    this.depth = 22.0,
    this.topRadius = 22.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = centerX;

    // Fill the background of the notch area with the exact screen background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = canvasBackgroundColor,
    );

    final path = Path();
    path.moveTo(0, topRadius);
    path.arcToPoint(
      Offset(topRadius, 0),
      radius: Radius.circular(topRadius),
    );

    // Left flat edge up to notch entry
    final entryX = (cx - notchRadius - shoulderRadius).clamp(topRadius, w - topRadius);
    path.lineTo(entryX, 0);

    // Smooth concave dip into notch
    path.cubicTo(
      cx - notchRadius, 0,
      cx - notchRadius * 0.72, depth,
      cx, depth,
    );

    // Smooth exit from notch
    final exitX = (cx + notchRadius + shoulderRadius).clamp(topRadius, w - topRadius);
    path.cubicTo(
      cx + notchRadius * 0.72, depth,
      cx + notchRadius, 0,
      exitX, 0,
    );

    // Right flat edge
    path.lineTo(w - topRadius, 0);
    path.arcToPoint(
      Offset(w, topRadius),
      radius: Radius.circular(topRadius),
    );

    // Right, bottom, and left
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Pure neutral soft shadow without Material 3 purple/pink ambient tint
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path.shift(const Offset(0, -1.5)), shadowPaint);

    // Paint white bar
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvedNotchPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.color != color ||
      oldDelegate.canvasBackgroundColor != canvasBackgroundColor ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.shoulderRadius != shoulderRadius ||
      oldDelegate.depth != depth ||
      oldDelegate.topRadius != topRadius;
}

class AccountTabScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const AccountTabScreen({
    super.key,
    required this.userData,
    required this.onLogout,
  });

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

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1565C0),
    Color textColor = const Color(0xFF1E293B),
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (isDestructive ? Colors.red : iconColor).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: isDestructive
            ? null
            : const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 22,
              ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentName = userData['name'] ?? userData['user_name'] ?? 'User';
    final String dispMemberId = userData['member_id']?.toString() ?? 'DW-2026-CARD';
    final String currentProfileImg = userData['image']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          "Account",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Profile Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withAlpha(50),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: currentProfileImg.isNotEmpty
                        ? NetworkImage(_getImageUrl(currentProfileImg))
                        : null,
                    child: currentProfileImg.isEmpty
                        ? const Icon(Icons.person, size: 28, color: Color(0xFF1565C0))
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dispMemberId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileEditScreen(userData: userData),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Edit",
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Medical Hub
          _buildSection("Medical & Health"),
          _buildTile(
            icon: Icons.calendar_month_rounded,
            title: "My Appointments",
            iconColor: const Color(0xFF00897B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllAppointmentsScreen(userData: userData),
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.assignment_rounded,
            title: "Medical Records & Prescriptions",
            iconColor: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicalHistoryScreen(initialTabIndex: 0),
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.analytics_rounded,
            title: "Health Parameters & Vitals",
            iconColor: const Color(0xFF059669),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HealthParametersScreen(),
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.calculate_rounded,
            title: "BMR Calculator",
            iconColor: const Color(0xFFEA580C),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BMRCalculatorScreen(),
                ),
              );
            },
          ),

          // App & Support
          _buildSection("Support & Settings"),
          _buildTile(
            icon: Icons.notifications_active_rounded,
            title: "Notifications",
            iconColor: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.support_agent_rounded,
            title: "24/7 Support",
            iconColor: const Color(0xFF0284C7),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactScreen(),
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.policy_rounded,
            title: "Privacy & Policy",
            iconColor: const Color(0xFF64748B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          _buildTile(
            icon: Icons.logout_rounded,
            title: "Logout",
            isDestructive: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

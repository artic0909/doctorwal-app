import 'dart:async';
import 'package:flutter/material.dart';
import 'package:demoapp/categoryscreen.dart';
import 'package:demoapp/search_screen.dart';
import 'package:demoapp/my_health_screen.dart';
import 'package:demoapp/account_tab_screen.dart';
import 'package:demoapp/profileeditscreen.dart';
import 'package:demoapp/tab_skeleton_view.dart';
import 'package:demoapp/main.dart'; // For LoginScreen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' as import_services;

class BottomNavScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  static final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();
  static void Function(int index)? switchTab;

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
  late Map<String, dynamic> _currentUserData;
  final List<int> _tabKeys = [0, 0, 0, 0];
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Timer? _skeletonTimer;
  int? _skeletonTabIndex;

  late AnimationController _notchController;
  late Animation<double> _notchAnim;

  @override
  void initState() {
    super.initState();
    _currentUserData = Map<String, dynamic>.from(widget.userData);
    _refreshUserData();
    BottomNavScreen.switchTab = _onTabSelected;
    _notchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _notchAnim = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _notchController, curve: Curves.easeInOutCubic),
    );
  }

  Future<void> _refreshUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUserData = {
        ..._currentUserData,
        if (prefs.getString('name') != null) 'name': prefs.getString('name'),
        if (prefs.getString('user_name') != null) 'user_name': prefs.getString('user_name'),
        if (prefs.getString('email') != null) 'email': prefs.getString('email'),
        if (prefs.getString('user_email') != null) 'user_email': prefs.getString('user_email'),
        if (prefs.getString('mobile') != null) 'mobile': prefs.getString('mobile'),
        if (prefs.getString('user_mobile') != null) 'user_mobile': prefs.getString('user_mobile'),
        if (prefs.getString('profile_image') != null) 'image': prefs.getString('profile_image'),
        if (prefs.getString('image') != null) 'image': prefs.getString('image'),
        if (prefs.getString('user_image') != null) 'user_image': prefs.getString('user_image'),
        if (prefs.getString('profile_image') != null) 'profile_image': prefs.getString('profile_image'),
        if (prefs.getString('member_id') != null) 'member_id': prefs.getString('member_id'),
        if (prefs.getString('medical_card_no') != null) 'medical_card_no': prefs.getString('medical_card_no'),
        if (prefs.getString('city') != null) 'city': prefs.getString('city'),
      };
    });
  }

  @override
  void dispose() {
    if (BottomNavScreen.switchTab == _onTabSelected) {
      BottomNavScreen.switchTab = null;
    }
    _skeletonTimer?.cancel();
    _notchController.dispose();
    super.dispose();
  }

  void _triggerTabRefresh(int index) {
    _skeletonTimer?.cancel();
    setState(() {
      _tabKeys[index]++;
      _skeletonTabIndex = index;
    });

    _skeletonTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _skeletonTabIndex == index) {
        setState(() {
          _skeletonTabIndex = null;
        });
      }
    });
  }

  void _onTabSelected(int index) {
    _refreshUserData();
    ProfileEditScreen.profileUpdateNotifier.value++;

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
      _triggerTabRefresh(index);
    } else {
      _triggerTabRefresh(index);
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
    final Widget tabChild;
    switch (index) {
      case 0:
        tabChild = TabNavigator(
          key: ValueKey('tab_0_${_tabKeys[0]}'),
          navigatorKey: _navigatorKeys[0],
          child: CategoryHomeScreen(
            key: ValueKey('home_${_tabKeys[0]}'),
            userData: _currentUserData,
          ),
        );
        break;
      case 1:
        tabChild = TabNavigator(
          key: ValueKey('tab_1_${_tabKeys[1]}'),
          navigatorKey: _navigatorKeys[1],
          child: SearchScreen(
            key: ValueKey('search_${_tabKeys[1]}'),
            userData: _currentUserData,
          ),
        );
        break;
      case 2:
        tabChild = TabNavigator(
          key: ValueKey('tab_2_${_tabKeys[2]}'),
          navigatorKey: _navigatorKeys[2],
          child: MyHealthScreen(
            key: ValueKey('health_${_tabKeys[2]}'),
            userData: _currentUserData,
          ),
        );
        break;
      case 3:
        tabChild = TabNavigator(
          key: ValueKey('tab_3_${_tabKeys[3]}'),
          navigatorKey: _navigatorKeys[3],
          child: AccountTabScreen(
            key: ValueKey('account_${_tabKeys[3]}'),
            userData: _currentUserData,
            onLogout: logout,
          ),
        );
        break;
      default:
        tabChild = const SizedBox.shrink();
    }

    final bool showSkeleton = _skeletonTabIndex == index;

    return Stack(
      children: [
        tabChild,
        if (showSkeleton)
          Positioned.fill(
            child: TabSkeletonView(tabIndex: index),
          ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
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

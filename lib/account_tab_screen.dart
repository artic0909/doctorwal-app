import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/profileeditscreen.dart';
import 'package:demoapp/changepasswordscreen.dart';
import 'package:demoapp/notificationscreen.dart';
import 'package:demoapp/contactscreen.dart';
import 'package:demoapp/privacypolicyscreen.dart';
import 'package:demoapp/Services/apiservice.dart';

class AccountTabScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const AccountTabScreen({
    super.key,
    required this.userData,
    required this.onLogout,
  });

  @override
  State<AccountTabScreen> createState() => _AccountTabScreenState();
}

class _AccountTabScreenState extends State<AccountTabScreen> {
  final ApiService _apiService = ApiService();

  String _memberId = '';
  String _medicalCardNo = '';
  String _name = '';
  String _email = '';
  String _image = '';

  int _completionPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Initial load from widget.userData & SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    String name = widget.userData['name'] ??
        widget.userData['user_name'] ??
        prefs.getString('name') ??
        'Saklin Mustak';
    String email = widget.userData['email'] ?? prefs.getString('email') ?? '';
    String mobile = widget.userData['mobile'] ??
        widget.userData['phone'] ??
        prefs.getString('mobile') ??
        '';
    String memId = widget.userData['member_id']?.toString() ??
        widget.userData['memberid']?.toString() ??
        prefs.getString('member_id') ??
        '';
    String cardNo = widget.userData['medical_card_no']?.toString() ??
        widget.userData['medicalcardno']?.toString() ??
        prefs.getString('medical_card_no') ??
        prefs.getString('medicalcardno') ??
        '';
    String image = widget.userData['image']?.toString() ??
        prefs.getString('image') ??
        '';
    String city = widget.userData['city']?.toString() ??
        prefs.getString('city') ??
        '';
    String address = widget.userData['address']?.toString() ??
        prefs.getString('address') ??
        '';
    String dob = widget.userData['dob']?.toString() ??
        prefs.getString('dob') ??
        '';
    String gender = widget.userData['gender']?.toString() ??
        prefs.getString('gender') ??
        '';
    String bloodGroup = widget.userData['blood_group']?.toString() ??
        prefs.getString('blood_group') ??
        '';
    String emergency = widget.userData['emergency_contact']?.toString() ??
        prefs.getString('emergency_contact') ??
        '';

    _updateState(
      name: name,
      email: email,
      mobile: mobile,
      memId: memId,
      cardNo: cardNo,
      image: image,
      city: city,
      address: address,
      dob: dob,
      gender: gender,
      bloodGroup: bloodGroup,
      emergency: emergency,
    );

    // 2. Fetch fresh profile data from API for guaranteed accuracy
    try {
      final response = await _apiService.getProfile();
      if (response['status'] == true && response['user'] != null) {
        final user = response['user'];
        _updateState(
          name: user['name']?.toString() ?? name,
          email: user['email']?.toString() ?? email,
          mobile: user['mobile']?.toString() ?? mobile,
          memId: user['member_id']?.toString() ?? memId,
          cardNo: user['medical_card_no']?.toString() ?? cardNo,
          image: user['image']?.toString() ?? image,
          city: user['city']?.toString() ?? city,
          address: user['address']?.toString() ?? address,
          dob: user['dob']?.toString() ?? dob,
          gender: user['gender']?.toString() ?? gender,
          bloodGroup: user['blood_group']?.toString() ?? bloodGroup,
          emergency: user['emergency_contact']?.toString() ?? emergency,
        );
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    }
  }

  void _updateState({
    required String name,
    required String email,
    required String mobile,
    required String memId,
    required String cardNo,
    required String image,
    required String city,
    required String address,
    required String dob,
    required String gender,
    required String bloodGroup,
    required String emergency,
  }) {
    // 10 Key profile fields for 100% accurate percentage calculation
    final keyFields = [
      name,
      email,
      mobile,
      gender,
      dob,
      city,
      address,
      bloodGroup,
      image,
      emergency,
    ];

    int filledCount = 0;
    for (final field in keyFields) {
      if (field.trim().isNotEmpty && field.trim() != 'null') {
        filledCount++;
      }
    }

    final int calculatedPercent = ((filledCount / keyFields.length) * 100).round();

    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
        _memberId = memId.isNotEmpty ? memId : 'DW-2026';
        _medicalCardNo = cardNo.isNotEmpty ? cardNo : 'DW-CARD';
        _image = image;
        _completionPercentage = calculatedPercent;
      });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Logout Confirmation",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          "Are you sure you want to log out from Doctorwala?",
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _copyCardNumber(String cardNo) {
    Clipboard.setData(ClipboardData(text: cardNo));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text("Medical Card copied: $cardNo")),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0D47A1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 12.0;
    final String dispCardNo =
        _medicalCardNo.isNotEmpty ? _medicalCardNo : 'DW26 7205 73';
    final String dispMemberId =
        _memberId.isNotEmpty ? _memberId : 'DW-2026-073';
    final String dispName = _name.isNotEmpty ? _name : 'Saklin Mustak';

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
                // User Row: Avatar + Name + Subtitle
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
                        child: (_image.isNotEmpty && _image.startsWith('http'))
                            ? Image.network(
                                _image,
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
                            _name,
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
                            _email.isNotEmpty ? _email : "Personal Account",
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. PROMINENT EYE-CATCHY REDESIGNED MEDICAL CARD
                _buildEyeCatchyMedicalCard(
                  cardNo: dispCardNo,
                  memberId: dispMemberId,
                  holderName: dispName,
                ),
              ],
            ),
          ),

          // 2. SCROLLABLE INNER LIST TABS (ClampingScrollPhysics - Non-spring)
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // 2. Update Profile with accurate completion percentage
                        _buildProfileUpdateCard(context),
                        const SizedBox(height: 9),

                        // 3. Change Password
                        _buildActionTile(
                          icon: Icons.lock_reset_rounded,
                          iconColor: const Color(0xFFD97706), // Warm Amber
                          iconBgColor: const Color(0xFFFFFBEB),
                          title: "Change Password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangePasswordScreen(email: _email),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 9),

                        // 4. Notifications
                        _buildActionTile(
                          icon: Icons.notifications_active_rounded,
                          iconColor: const Color(0xFF2563EB), // Royal Blue
                          iconBgColor: const Color(0xFFEFF6FF),
                          title: "Notifications",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 9),

                        // 5. 24/7 Support
                        _buildActionTile(
                          icon: Icons.support_agent_rounded,
                          iconColor: const Color(0xFF0D9488), // Medical Teal
                          iconBgColor: const Color(0xFFF0FDFA),
                          title: "24/7 Support",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ContactScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 9),

                        // 6. Privacy & Policy
                        _buildActionTile(
                          icon: Icons.policy_rounded,
                          iconColor: const Color(0xFF4F46E5), // Indigo
                          iconBgColor: const Color(0xFFEEF2FF),
                          title: "Privacy & Policy",
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

                        // Logout Action Button
                        _buildLogoutTile(),
                      ],
                    ),
                  ),

                  // Bottom padding for curved bottom bar
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Update Profile Card showing accurate completion percentage
  Widget _buildProfileUpdateCard(BuildContext context) {
    final bool isComplete = _completionPercentage >= 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileEditScreen(userData: widget.userData),
              ),
            ).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Update Profile",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        "$_completionPercentage%",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isComplete
                              ? const Color(0xFF059669)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Accurate Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (_completionPercentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? const Color(0xFF059669) : const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: _confirmLogout,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFFCA5A5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEyeCatchyMedicalCard({
    required String cardNo,
    required String memberId,
    required String holderName,
  }) {
    return GestureDetector(
      onTap: () => _copyCardNumber(cardNo),
      child: Container(
        width: double.infinity,
        height: 195,
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF091E42), // Luxury dark navy
              Color(0xFF0D3B75), // Deep royal sapphire
              Color(0xFF1565C0), // Doctorwala classic blue
              Color(0xFF1E88E5), // Vivid cobalt edge
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withAlpha(70),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(110),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: const Color(0xFF1565C0).withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              // 1. Ambient Glowing Cyan Accent
              Positioned(
                right: -25,
                top: -25,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withAlpha(55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Large Translucent Shield Watermark
              Positioned(
                right: -15,
                bottom: -20,
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 155,
                  color: Colors.white.withAlpha(22),
                ),
              ),

              // 3. Subtle Holographic Sheen Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1.2, -1.2),
                      end: const Alignment(1.2, 1.2),
                      colors: [
                        Colors.white.withAlpha(35),
                        Colors.white.withAlpha(8),
                        Colors.transparent,
                        Colors.white.withAlpha(14),
                      ],
                      stops: const [0.0, 0.28, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // 4. Card Foreground Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Brand Title & Golden Chip + Contactless Wave
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(28),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withAlpha(60),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Color(0xFF67E8F9),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "DOCTORWALA",
                                  style: TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  "MEDICAL CARD",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Contactless & Metallic Gold Chip
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.contactless_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 42,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFE082),
                                    Color(0xFFFFB300),
                                    Color(0xFFFFA000),
                                    Color(0xFFFFD54F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF92400E).withAlpha(160),
                                  width: 0.7,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(45),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    bottom: 8,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Color(0xFF78350F),
                                            width: 0.5,
                                          ),
                                          bottom: BorderSide(
                                            color: Color(0xFF78350F),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    left: 12,
                                    right: 12,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Color(0xFF78350F),
                                            width: 0.5,
                                          ),
                                          right: BorderSide(
                                            color: Color(0xFF78350F),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 12,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7).withAlpha(140),
                                        borderRadius: BorderRadius.circular(2),
                                        border: Border.all(
                                          color: const Color(0xFF78350F),
                                          width: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Middle: Card Number & Copy Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            cardNo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.2,
                              shadows: [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _copyCardNumber(cardNo),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withAlpha(70),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "COPY",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Card Holder + Member ID + Active Status Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Card Holder
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "CARD HOLDER",
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              holderName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),

                        // Member ID
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MEMBER ID",
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              memberId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),

                        // Active Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F46).withAlpha(190),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: const Color(0xFF34D399).withAlpha(150),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "ACTIVE",
                                style: TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

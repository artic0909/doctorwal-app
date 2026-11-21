import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:demoapp/widgets/skeleton_loader.dart';
import 'Models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _tabIndex = 0; // 0 for Unread, 1 for Read

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('https://doctorwala.info/api/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final List list = data['data'] ?? [];
          setState(() {
            _notifications = list.map((e) => NotificationModel.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(int id, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = 'https://www.doctorwala.info/api/notifications/$id/$action';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Action successful'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _fetchNotifications();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Action failed'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int unreadCount = _notifications.where((n) => n.readStatus == 'unread').length;
    int readCount = _notifications.where((n) => n.readStatus == 'read').length;

    List<NotificationModel> filteredList = _notifications.where((n) {
      bool matchesTab = (_tabIndex == 0) ? n.readStatus == 'unread' : n.readStatus == 'read';
      bool matchesSearch = n.partnerClinicName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.doctorSpecialist.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(unreadCount),
          const SizedBox(height: 12),
          _buildSegmentedTabs(unreadCount, readCount),
          const SizedBox(height: 10),
          _buildSearchBar(),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
                ? const NotificationListSkeleton()
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: const Color(0xFF1565C0),
                    child: filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              MediaQuery.of(context).viewPadding.bottom + 90,
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) => _buildNotificationCard(filteredList[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int unread) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Manage clinic & doctor access requests",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 12),
                const SizedBox(width: 5),
                Text(
                  unread > 0 ? "$unread NEW" : "ALL CAUGHT UP",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(int unread, int read) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tabButton(
                title: "Unread",
                count: unread,
                isSelected: _tabIndex == 0,
                onTap: () => setState(() => _tabIndex = 0),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _tabButton(
                title: "Read History",
                count: read,
                isSelected: _tabIndex == 1,
                onTap: () => setState(() => _tabIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Search medical requests...",
            hintStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 19),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    String initials = notification.partnerClinicName.isNotEmpty ? notification.partnerClinicName[0] : "D";
    if (notification.partnerClinicName.split(' ').length > 1) {
      initials = notification.partnerClinicName[0] + notification.partnerClinicName.split(' ')[1][0];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.partnerClinicName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dr. ${notification.doctorName}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      Text(
                        notification.doctorSpecialist,
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.reqStatus == 'pending')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconAction(
                        Icons.check_rounded,
                        const Color(0xFF2E7D32),
                        () => _handleAction(notification.id, 'accept'),
                      ),
                      const SizedBox(width: 8),
                      _iconAction(
                        Icons.close_rounded,
                        const Color(0xFFC62828),
                        () => _handleAction(notification.id, 'reject'),
                      ),
                    ],
                  )
                else
                  _statusPill(notification.reqStatus),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _infoRow(Icons.phone_iphone_rounded, notification.partnerMobileNumber),
                      _infoRow(Icons.alternate_email_rounded, notification.partnerEmail),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _infoRow(Icons.location_on_outlined, notification.formattedAddress),
                      _infoRow(Icons.history_rounded, notification.createdAt, isDate: true),
                    ],
                  ),
                ),
              ],
            ),
            if (notification.reqStatus != 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _managePermissionButton(notification),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color color = status == 'pending'
        ? const Color(0xFFFFA000)
        : (status == 'accepted' ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _managePermissionButton(NotificationModel notification) {
    bool isOn = notification.accessStatus == 'on';
    return InkWell(
      onTap: () {
        final String nextAction = isOn ? 'permission-off' : 'permission-on';
        _handleAction(notification.id, nextAction);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFFC62828).withAlpha(12) : const Color(0xFF2E7D32).withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn ? const Color(0xFFC62828).withAlpha(40) : const Color(0xFF2E7D32).withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOn ? Icons.security_update_warning_rounded : Icons.verified_user_rounded,
              size: 14,
              color: isOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            Text(
              isOn ? "Revoke Profile Access" : "Grant Profile Access",
              style: TextStyle(
                color: isOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isDate = false}) {
    if (text.isEmpty) return const SizedBox.shrink();
    String displayText = text;

    if (isDate) {
      try {
        DateTime dt = DateTime.parse(text).toLocal();
        displayText = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (e) {
        displayText = text;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quiet for now",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "When doctors or clinics request access to your profile, you'll see them here instantly.",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

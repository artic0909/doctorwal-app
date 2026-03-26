import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
        Uri.parse('https://doctorwala.info/api/notifications'), // Universal domain
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("NOTIFICATION_RAW_DATA: ${response.body}"); // FOR DEBUGGING

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(int id, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Action is 'accept' or 'reject'
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        _fetchNotifications(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Action failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
    Widget build(BuildContext context) {
    int unreadCount = _notifications.where((n) => n.readStatus == 'unread').length;
    int readCount = _notifications.where((n) => n.readStatus == 'read').length;
    int totalCount = _notifications.length;

    List<NotificationModel> filteredList = _notifications.where((n) {
      bool matchesTab = (_tabIndex == 0) ? n.readStatus == 'unread' : n.readStatus == 'read';
      bool matchesSearch = n.partnerClinicName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          n.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.doctorSpecialist.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      body: Column(
        children: [
          _buildHeader(unreadCount, totalCount),
          _buildTabs(unreadCount, readCount),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) => _buildNotificationCard(filteredList[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int unread, int total) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Notifications",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Icon(Icons.hub_rounded, color: Colors.white70, size: 26),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _headerStat("${unread}", "Unread"),
              Container(width: 1, height: 40, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 25)),
              _headerStat("${total}", "Total"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildTabs(int unread, int read) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _tabItem("UNREAD", unread, 0),
            const SizedBox(width: 15),
            _tabItem("READ", read, 1),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int count, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withAlpha(210), // Increased opacity for visibility
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 15, offset: const Offset(0, 8))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(color: isSelected ? const Color(0xFF0D47A1) : const Color(0xFF0D47A1).withAlpha(100), fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, fontSize: 12, letterSpacing: 1),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(10)),
                  child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: "Search Medical Requests...",
            hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 13, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(initials.toUpperCase(), style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.partnerClinicName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), height: 1.1)),
                      const SizedBox(height: 2),
                      Text("Dr. ${notification.doctorName}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A237E), height: 1.1)),
                      Text(notification.doctorSpecialist, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (notification.reqStatus == 'pending')
                  Row(
                    children: [
                      _iconAction(Icons.check_circle_rounded, const Color(0xFF2E7D32), () => _handleAction(notification.id, 'accept')),
                      const SizedBox(width: 8),
                      _iconAction(Icons.cancel_rounded, const Color(0xFFC62828), () => _handleAction(notification.id, 'reject')),
                    ],
                  )
                else
                  _statusPill(notification.reqStatus),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Column(
                  children: [
                    _infoRow(Icons.phone_iphone_rounded, notification.partnerMobileNumber),
                    _infoRow(Icons.alternate_email_rounded, notification.partnerEmail),
                  ],
                )),
                Expanded(child: Column(
                  children: [
                    _infoRow(Icons.location_on_outlined, notification.formattedAddress),
                    _infoRow(Icons.history_rounded, notification.createdAt, isDate: true),
                  ],
                )),
              ],
            ),
            if (notification.reqStatus != 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 10),
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
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color color = status == 'pending' ? const Color(0xFFFFA000) : (status == 'accepted' ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFFC62828).withAlpha(15) : const Color(0xFF2E7D32).withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isOn ? const Color(0xFFC62828).withAlpha(50) : const Color(0xFF2E7D32).withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOn ? Icons.security_update_warning_rounded : Icons.verified_user_rounded, size: 14, color: isOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              isOn ? "Turn Off Access" : "Turn On Access",
              style: TextStyle(color: isOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 11),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF1976D2), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(color: Colors.blueGrey[700], fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: const Color(0xFF0D47A1).withAlpha(12), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, size: 80, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 25),
          const Text("Quiet for now", style: TextStyle(color: Color(0xFF1A237E), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "When doctors request access to your profile, you'll see them here instantly.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

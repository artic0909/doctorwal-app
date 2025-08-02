import 'package:demoapp/allopdscreen.dart';
import 'package:demoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aboutscreen.dart';
import 'allavailablepathologyscreen.dart';
import 'allcouponsscreen.dart';
import 'alldoctorsscreen.dart';
import 'blogsscreen.dart';
import 'contactscreen.dart';
import 'privacypolicyscreen.dart';
import 'profileeditscreen.dart';
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

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'User';
      email = prefs.getString('email') ?? '';
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      // No token saved, just go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Doctor ',
                          style: TextStyle(color: Color(0xFF006400)),
                        ),
                        TextSpan(
                          text: 'Wala',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('All Coupons'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllCouponsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Blog'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BlogsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.headset_mic),
              title: const Text('Contact'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ProfileEditScreen(userData: widget.userData),
                  ),
                );

                await loadUserData();
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: false,
        title: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/bg2.jpeg',
                fit: BoxFit.cover,
                height: 450,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      "Hello ",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      name.isNotEmpty
                          ? '${name[0].toUpperCase()}${name.substring(1)}'
                          : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProfileEditScreen(
                                  userData: widget.userData,
                                ),
                          ),
                        );

                        await loadUserData();
                        setState(() {});
                      },

                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25,
                        child: Icon(Icons.person, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildCard(
                      icon: Icons.biotech,
                      label: 'Available Pathology',
                      ontap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                       AllAvailablePathologyScreen(userData: widget.userData),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      icon: Icons.assignment,
                      label: 'Available OPD',
                      ontap: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllAvailableOPDScreen(userData: widget.userData),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      icon: Icons.medical_services,
                      label: 'Available Doctors',
                      ontap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllDoctorsScreen(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required VoidCallback ontap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blue[900]),
        title: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onTap: ontap,
      ),
    );
  }
}

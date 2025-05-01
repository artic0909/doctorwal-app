import 'package:demoapp/aboutscreen.dart';
import 'package:demoapp/allavailablepathologyscreen.dart';
import 'package:demoapp/allcouponsscreen.dart';
import 'package:demoapp/alldoctorsscreen.dart';
import 'package:demoapp/allopdscreen.dart';
import 'package:demoapp/blogsscreen.dart';
import 'package:demoapp/contactscreen.dart';
import 'package:demoapp/privacypolicyscreen.dart';
import 'package:demoapp/profileeditscreen.dart';
import 'package:flutter/material.dart';

class CategoryHomeScreen extends StatelessWidget {
  const CategoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Replace with your actual logo path
                    height: 40,
                  ),
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
                        ), // Deep green
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
              leading: Icon(Icons.category),
              title: Text('Category'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryHomeScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.card_giftcard),
              title: Text('All Coupons'),
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
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.article),
              title: Text('Blog'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BlogsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Privacy'),
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
              leading: Icon(Icons.headset_mic),
              title: Text('Contact'),
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
              leading: Icon(Icons.edit),
              title: Text('Edit Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
            ),
            const ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.only(
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
                const Text(
                  "Test Saklin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
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
                  context: context,
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllAvailablePathologyScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildCard(
                  icon: Icons.assignment,
                  label: 'Available OPD',
                  context: context,
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllOpdScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildCard(
                  icon: Icons.medical_services,
                  label: 'Available Doctors',
                  context: context,
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllDoctorsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required BuildContext context,
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

import 'dart:io';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/changepasswordscreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  static final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

  const ProfileEditScreen({super.key, required this.userData});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _cityController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicConditionsController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  File? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;
  bool _isFetching = true;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchProfileData();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _cityController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _allergiesController = TextEditingController();
    _chronicConditionsController = TextEditingController();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isFetching = true);
    try {
      final response = await _apiService.getProfile();
      if (response['status'] == true) {
        final user = response['user'];
        setState(() {
          _nameController.text = user['name']?.toString() ?? '';
          _emailController.text = user['email']?.toString() ?? '';
          _mobileController.text = user['mobile']?.toString() ?? '';
          _cityController.text = user['city']?.toString() ?? '';
          _dobController.text = user['dob']?.toString() ?? '';
          _addressController.text = user['address']?.toString() ?? '';
          _heightController.text = user['height']?.toString() ?? '';
          _weightController.text = user['weight']?.toString() ?? '';
          _emergencyContactController.text = user['emergency_contact']?.toString() ?? '';
          _allergiesController.text = user['allergies']?.toString() ?? '';
          _chronicConditionsController.text = user['chronic_conditions']?.toString() ?? '';
          _selectedGender = user['gender'];
          _selectedBloodGroup = user['blood_group'];
          _networkImageUrl = user['image'];

          if (_selectedGender != null && !_genders.contains(_selectedGender)) {
            _selectedGender = null;
          }
          if (_selectedBloodGroup != null && !_bloodGroups.contains(_selectedBloodGroup)) {
            _selectedBloodGroup = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1565C0),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        city: _cityController.text.trim(),
        dob: _dobController.text.trim(),
        gender: _selectedGender,
        address: _addressController.text.trim(),
        bloodGroup: _selectedBloodGroup,
        height: _heightController.text.trim(),
        weight: _weightController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        allergies: _allergiesController.text.trim(),
        chronicConditions: _chronicConditionsController.text.trim(),
        imagePath: _imageFile?.path,
      );

      if (response['status'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameController.text.trim());
        await prefs.setString('user_name', _nameController.text.trim());
        await prefs.setString('mobile', _mobileController.text.trim());
        await prefs.setString('user_mobile', _mobileController.text.trim());
        await prefs.setString('city', _cityController.text.trim());
        await prefs.setString('user_city', _cityController.text.trim());

        final String? newImage = (response['image'] ?? response['user']?['image'])?.toString();
        if (newImage != null && newImage.isNotEmpty) {
          await prefs.setString('profile_image', newImage);
          await prefs.setString('image', newImage);
          await prefs.setString('user_image', newImage);
        }

        ProfileEditScreen.profileUpdateNotifier.value++;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Profile updated successfully!'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Update failed'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyContactController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          MediaQuery.of(context).viewPadding.bottom + 90,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileImageCard(),
                              const SizedBox(height: 20),

                              // Section 1: Personal Information
                              _buildSectionTitle("Personal Information", Icons.person_rounded),
                              _buildCard([
                                _buildTextField(
                                  controller: _nameController,
                                  label: "Full Name",
                                  icon: Icons.person_outline_rounded,
                                  hint: "Enter your full name",
                                  validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null,
                                ),
                                _buildTextField(
                                  controller: _emailController,
                                  label: "Email Address (Registered)",
                                  icon: Icons.email_outlined,
                                  readOnly: true,
                                ),
                                _buildTextField(
                                  controller: _mobileController,
                                  label: "Mobile Number",
                                  icon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  hint: "10-digit mobile number",
                                  validator: (v) => (v == null || v.isEmpty) ? "Mobile is required" : null,
                                ),
                                _buildDropdownField(
                                  label: "Gender",
                                  icon: Icons.wc_rounded,
                                  value: _selectedGender,
                                  items: _genders,
                                  onChanged: (v) => setState(() => _selectedGender = v),
                                ),
                                _buildTextField(
                                  controller: _dobController,
                                  label: "Date of Birth",
                                  icon: Icons.calendar_today_rounded,
                                  hint: "YYYY-MM-DD",
                                  readOnly: true,
                                  onTap: _selectDate,
                                ),
                                _buildTextField(
                                  controller: _cityController,
                                  label: "City",
                                  icon: Icons.location_city_rounded,
                                  hint: "e.g. Kolkata, Howrah",
                                ),
                              ]),

                              const SizedBox(height: 22),

                              // Section 2: Contact Details
                              _buildSectionTitle("Contact Details", Icons.contact_mail_rounded),
                              _buildCard([
                                _buildTextField(
                                  controller: _addressController,
                                  label: "Full Residential Address",
                                  icon: Icons.home_work_outlined,
                                  hint: "Street, Landmark, City & PIN",
                                  maxLines: 2,
                                ),
                                _buildTextField(
                                  controller: _emergencyContactController,
                                  label: "Emergency Contact Phone",
                                  icon: Icons.contact_phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  hint: "Family member / Relative phone",
                                ),
                              ]),

                              const SizedBox(height: 22),

                              // Section 3: Medical Vitals
                              _buildSectionTitle("Medical & Clinical Vitals", Icons.health_and_safety_rounded),
                              _buildCard([
                                _buildDropdownField(
                                  label: "Blood Group",
                                  icon: Icons.bloodtype_rounded,
                                  value: _selectedBloodGroup,
                                  items: _bloodGroups,
                                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _heightController,
                                        label: "Height (cm)",
                                        icon: Icons.height_rounded,
                                        keyboardType: TextInputType.number,
                                        hint: "e.g. 170",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _weightController,
                                        label: "Weight (kg)",
                                        icon: Icons.monitor_weight_outlined,
                                        keyboardType: TextInputType.number,
                                        hint: "e.g. 65",
                                      ),
                                    ),
                                  ],
                                ),
                                _buildTextField(
                                  controller: _allergiesController,
                                  label: "Known Allergies",
                                  icon: Icons.warning_amber_rounded,
                                  maxLines: 2,
                                  hint: "e.g. Penicillin, Peanuts, Pollen, or None",
                                ),
                                _buildTextField(
                                  controller: _chronicConditionsController,
                                  label: "Chronic Health Conditions",
                                  icon: Icons.history_edu_rounded,
                                  maxLines: 2,
                                  hint: "e.g. Diabetes, Hypertension, Asthma, or None",
                                ),
                              ]),

                              const SizedBox(height: 30),
                              _buildUpdateButton(),
                              const SizedBox(height: 14),
                              _buildChangePasswordButton(),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  "Edit Medical Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Keep your health & personal info up to date",
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  "PROFILE",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1565C0).withAlpha(40),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withAlpha(20),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                          ? NetworkImage(_networkImageUrl!)
                          : null) as ImageProvider?,
                  child: (_imageFile == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                      ? const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: Color(0xFF94A3B8),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : "User Profile",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _emailController.text.isNotEmpty ? _emailController.text : "Verified Patient",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                width: 1.1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              maxLines: maxLines,
              onTap: onTap,
              validator: validator,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: readOnly ? const Color(0xFF64748B) : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13, fontWeight: FontWeight.w500),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 10, right: 8),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    icon,
                    color: readOnly ? const Color(0xFF94A3B8) : const Color(0xFF1565C0),
                    size: 18,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: value,
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 10, right: 8),
                  padding: const EdgeInsets.all(6),
                  child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "SAVE PROFILE CHANGES",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(email: _emailController.text),
            ),
          );
        },
        icon: const Icon(Icons.lock_reset_rounded, size: 16, color: Color(0xFF1565C0)),
        label: const Text(
          "Update Account Security & Password",
          style: TextStyle(
            color: Color(0xFF1565C0),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

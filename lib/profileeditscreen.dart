import 'dart:io';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/changepasswordscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

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
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

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
          
          // Fallback if dropdown values don't match exactly
          if (_selectedGender != null && !_genders.contains(_selectedGender)) _selectedGender = null;
          if (_selectedBloodGroup != null && !_bloodGroups.contains(_selectedBloodGroup)) _selectedBloodGroup = null;
        });
        
        // Update local prefs with latest core data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameController.text);
        await prefs.setString('email', _emailController.text);
        await prefs.setString('mobile', _mobileController.text);
        await prefs.setString('city', _cityController.text);
        if (_networkImageUrl != null) await prefs.setString('image', _networkImageUrl!);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Image Source",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF546E7A))),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Color(0xFF263238),
            ),
          ),
          child: child!,
        );
      },
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
        name: _nameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        city: _cityController.text,
        dob: _dobController.text,
        gender: _selectedGender,
        address: _addressController.text,
        bloodGroup: _selectedBloodGroup,
        height: _heightController.text,
        weight: _weightController.text,
        emergencyContact: _emergencyContactController.text,
        allergies: _allergiesController.text,
        chronicConditions: _chronicConditionsController.text,
        imagePath: _imageFile?.path,
      );

      if (response['status'] == true) {
        // Update local prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameController.text);
        await prefs.setString('mobile', _mobileController.text);
        await prefs.setString('city', _cityController.text);
        if (response['image'] != null) {
          await prefs.setString('image', response['image']);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Update failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
      appBar: _buildAppBar(),
      body: _isFetching 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
        : Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileImage(),
                      const SizedBox(height: 30),
                      
                      _buildSectionTitle("Personal Information", Icons.person_rounded),
                      _buildCard([
                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.badge_outlined,
                          validator: (v) => v!.isEmpty ? "Name is required" : null,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          readOnly: true,
                        ),
                        _buildTextField(
                          controller: _mobileController,
                          label: "Mobile Number",
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? "Mobile is required" : null,
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
                          readOnly: true,
                          onTap: _selectDate,
                        ),
                        _buildTextField(
                          controller: _cityController,
                          label: "City",
                          icon: Icons.location_city_rounded,
                        ),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Contact Details", Icons.contact_emergency_rounded),
                      _buildCard([
                        _buildTextField(
                          controller: _addressController,
                          label: "Full Address",
                          icon: Icons.home_work_outlined,
                          maxLines: 2,
                        ),
                        _buildTextField(
                          controller: _emergencyContactController,
                          label: "Emergency Contact",
                          icon: Icons.contact_phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Medical Details", Icons.health_and_safety_rounded),
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
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTextField(
                                controller: _weightController,
                                label: "Weight (kg)",
                                icon: Icons.monitor_weight_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(
                          controller: _allergiesController,
                          label: "Allergies",
                          icon: Icons.warning_amber_rounded,
                          maxLines: 2,
                          hint: "List any drug or food allergies",
                        ),
                        _buildTextField(
                          controller: _chronicConditionsController,
                          label: "Chronic Conditions",
                          icon: Icons.history_edu_rounded,
                          maxLines: 2,
                          hint: "Diabetes, Hypertension, etc.",
                        ),
                      ]),

                      const SizedBox(height: 40),
                      _buildUpdateButton(),
                      
                      const SizedBox(height: 20),
                      _buildChangePasswordButton(),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: const Text(
        "Edit Medical Profile",
        style: TextStyle(color: Color(0xFF263238), fontSize: 18, fontWeight: FontWeight.w900),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1565C0).withAlpha(51), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                      ? NetworkImage(_networkImageUrl!)
                      : null) as ImageProvider?,
              child: (_imageFile == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                  ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFFB0BEC5))
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF546E7A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF263238)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0).withAlpha(153), size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0).withAlpha(153), size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _updateProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: const Color(0xFF1565C0).withAlpha(102),
      ),
      child: const Text(
        "UPDATE MEDICAL PROFILE",
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(email: _emailController.text),
          ),
        );
      },
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: "Need to update credentials? ",
              style: TextStyle(color: Color(0xFF546E7A), fontSize: 14),
            ),
            TextSpan(
              text: "Change Password",
              style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

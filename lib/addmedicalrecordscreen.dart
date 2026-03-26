import 'dart:io';
import 'package:demoapp/Services/apiservice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class AddMedicalRecordScreen extends StatefulWidget {
  final Map<String, dynamic>? recordData; // If null, we are in Add mode
  final String? initialType; // 'report' or 'prescription'

  const AddMedicalRecordScreen({super.key, this.recordData, this.initialType});

  @override
  State<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _headingController;
  late TextEditingController _dateController;
  
  String _selectedType = 'report';
  List<File> _newImages = [];
  List<String> _existingImages = [];
  List<String> _deletedExistingImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.recordData?['type'] ?? widget.initialType ?? 'report';
    _headingController = TextEditingController(text: widget.recordData?['heading']);
    
    String initialDate = widget.recordData?['date_of_report'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateController = TextEditingController(text: initialDate);
    
    if (widget.recordData != null && widget.recordData!['images'] != null) {
      _existingImages = List<String>.from(widget.recordData!['images']);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImages() async {
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
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _newImages.addAll(images.map((x) => File(x.path)));
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
        if (image != null) {
          setState(() {
            _newImages.add(File(image.path));
          });
        }
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

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      String path = _existingImages.removeAt(index);
      // We need to send the relative path for deletion to the backend
      // Backend expects relative paths in medical_histories/ID/...
      // formatRecord appends asset('storage/'), so we need to strip it if possible
      // or rely on the backend to handle the full URL if sent (but backend usually expects storage path)
      
      // Extract relative path from URL: .../storage/medical_histories/95/file.jpg -> medical_histories/95/file.jpg
      String relativePath = path;
      if (path.contains('/storage/')) {
        relativePath = path.split('/storage/').last;
      }
      
      _deletedExistingImages.add(relativePath);
    });
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach at least one image/document"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      FormData formData = FormData.fromMap({
        'type': _selectedType,
        'heading': _headingController.text,
        'date_of_report': _dateController.text,
      });

      // Add new images
      for (var file in _newImages) {
        formData.files.add(MapEntry(
          widget.recordData == null ? 'images[]' : 'new_images[]',
          await MultipartFile.fromFile(file.path, filename: p.basename(file.path)),
        ));
      }

      // Add deleted images if editing
      if (widget.recordData != null && _deletedExistingImages.isNotEmpty) {
        for (int i = 0; i < _deletedExistingImages.length; i++) {
          formData.fields.add(MapEntry('deleted_images[$i]', _deletedExistingImages[i]));
        }
      }

      Map<String, dynamic> response;
      if (widget.recordData == null) {
        response = await _apiService.addMedicalHistory(formData);
      } else {
        response = await _apiService.editMedicalHistory(widget.recordData!['id'], formData);
      }

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Record saved!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to save'), backgroundColor: Colors.red),
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
    _headingController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.recordData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          isEdit ? "Update Medical Record" : "New Medical Record",
          style: const TextStyle(color: Color(0xFF263238), fontSize: 17, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 25),
                  
                  _buildInputField(
                    controller: _headingController,
                    label: "Record Heading",
                    hint: "e.g., Blood Test Report, Dental Prescription",
                    icon: Icons.title_rounded,
                    validator: (v) => v!.isEmpty ? "Heading is required" : null,
                  ),
                  const SizedBox(height: 15),
                  
                  _buildInputField(
                    controller: _dateController,
                    label: "Date of Report",
                    readOnly: true,
                    onTap: _selectDate,
                    icon: Icons.calendar_today_rounded,
                  ),
                  
                  const SizedBox(height: 30),
                  const Text(
                    "ATTACHMENTS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF546E7A), letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  
                  _buildImageGrid(),
                  
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      shadowColor: const Color(0xFF1565C0).withAlpha(102),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? "UPDATE RECORD" : "SAVE RECORD",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeBtn('report', 'Report', Icons.assignment_rounded)),
        const SizedBox(width: 15),
        Expanded(child: _typeBtn('prescription', 'Prescription', Icons.medication_rounded)),
      ],
    );
  }

  Widget _typeBtn(String type, String label, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: isSelected ? const Color(0xFF1565C0).withAlpha(77) : Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.blueGrey[100]!, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF1565C0), size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF263238), fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey[50]!),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _existingImages.length + _newImages.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index < _existingImages.length) {
                return _imageItem(imagePath: _existingImages[index], isExisting: true, onRemove: () => _removeExistingImage(index));
              } else if (index < _existingImages.length + _newImages.length) {
                int newIdx = index - _existingImages.length;
                return _imageItem(imageFile: _newImages[newIdx], isExisting: false, onRemove: () => _removeNewImage(newIdx));
              } else {
                return _addMoreBtn();
              }
            },
          ),
          if (_existingImages.isEmpty && _newImages.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text("Select images of your report or prescription", style: TextStyle(color: Colors.blueGrey[200], fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _imageItem({String? imagePath, File? imageFile, required bool isExisting, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey[50]!),
            image: DecorationImage(
              image: isExisting ? NetworkImage(imagePath!) as ImageProvider : FileImage(imageFile!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
            ),
          ),
        ),
        if (isExisting)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: const Text("SAVED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _addMoreBtn() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1565C0).withAlpha(51), style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.add_a_photo_rounded, color: Color(0xFF1565C0), size: 30),
             SizedBox(height: 4),
             Text("ADD", style: TextStyle(color: Color(0xFF1565C0), fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

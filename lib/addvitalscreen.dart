import 'package:demoapp/Services/apiservice.dart';
import 'package:flutter/material.dart';

class AddVitalScreen extends StatefulWidget {
  final Map<String, dynamic>? vitalData; // If null, we are in Add mode

  const AddVitalScreen({super.key, this.vitalData});

  @override
  State<AddVitalScreen> createState() => _AddVitalScreenState();
}

class _AddVitalScreenState extends State<AddVitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  late TextEditingController _heartRateController;
  late TextEditingController _bpController;
  late TextEditingController _tempController;
  late TextEditingController _spo2Controller;
  late TextEditingController _sugarController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _bmiController;

  String? _selectedBloodGroup;
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _heartRateController = TextEditingController(text: widget.vitalData?['heart_rate']?.toString());
    _bpController = TextEditingController(text: widget.vitalData?['blood_pressure']?.toString());
    _tempController = TextEditingController(text: widget.vitalData?['temparature']?.toString());
    _spo2Controller = TextEditingController(text: widget.vitalData?['spo']?.toString());
    _sugarController = TextEditingController(text: widget.vitalData?['blood_sugar']?.toString());
    _weightController = TextEditingController(text: widget.vitalData?['weight']?.toString());
    _heightController = TextEditingController(text: widget.vitalData?['height']?.toString());
    _bmiController = TextEditingController(text: widget.vitalData?['bmi']?.toString());
    _selectedBloodGroup = widget.vitalData?['blood_group'];
  }

  void _calculateBMI() {
    double? weight = double.tryParse(_weightController.text);
    double? height = double.tryParse(_heightController.text);

    if (weight != null && height != null && height > 0) {
      // BMI = weight(kg) / (height(m)^2)
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      setState(() {
        _bmiController.text = bmi.toStringAsFixed(1);
      });
    }
  }

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final Map<String, dynamic> data = {
      'heart_rate': _heartRateController.text,
      'blood_pressure': _bpController.text,
      'temparature': _tempController.text,
      'spo': _spo2Controller.text,
      'blood_sugar': _sugarController.text,
      'weight': _weightController.text,
      'height': _heightController.text,
      'bmi': _bmiController.text,
      'blood_group': _selectedBloodGroup,
    };

    try {
      Map<String, dynamic> response;
      if (widget.vitalData == null) {
        response = await _apiService.addVitals(data);
      } else {
        response = await _apiService.editVitals(widget.vitalData!['id'], data);
      }

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Saved successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Operation failed'), backgroundColor: Colors.red),
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
    _heartRateController.dispose();
    _bpController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _sugarController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.vitalData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          isEdit ? "Edit Health Parameters" : "Add Health Parameters",
          style: const TextStyle(color: Color(0xFF263238), fontSize: 18, fontWeight: FontWeight.w900),
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
                  _buildHeader(isEdit),
                  const SizedBox(height: 30),
                  
                  _buildSectionTitle("Cardiovascular & O2", Icons.favorite_rounded),
                  _buildFormCard([
                    Row(
                      children: [
                        Expanded(child: _buildInputField(
                          controller: _heartRateController, 
                          label: "Heart Rate", 
                          icon: Icons.monitor_heart_rounded, 
                          hint: "BPM", 
                          keyboardType: TextInputType.number
                        )),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(
                          controller: _bpController, 
                          label: "Blood Pressure", 
                          icon: Icons.speed_rounded, 
                          hint: "120/80",
                        )),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(
                          controller: _tempController, 
                          label: "Temperature", 
                          icon: Icons.thermostat_rounded, 
                          hint: "°C", 
                          keyboardType: TextInputType.number
                        )),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(
                          controller: _spo2Controller, 
                          label: "SpO2 (%)", 
                          icon: Icons.bloodtype_outlined, 
                          hint: "98", 
                          keyboardType: TextInputType.number
                        )),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("Metabolic & Body", Icons.accessibility_new_rounded),
                  _buildFormCard([
                    _buildInputField(
                      controller: _sugarController, 
                      label: "Blood Sugar", 
                      icon: Icons.opacity_rounded, 
                      hint: "mg/dL", 
                      keyboardType: TextInputType.number
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(
                          controller: _heightController, 
                          label: "Height (cm)", 
                          icon: Icons.height_rounded, 
                          hint: "170", 
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateBMI(),
                        )),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(
                          controller: _weightController, 
                          label: "Weight (kg)", 
                          icon: Icons.monitor_weight_rounded, 
                          hint: "70", 
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateBMI(),
                        )),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(
                          controller: _bmiController, 
                          label: "BMI", 
                          icon: Icons.calculate_rounded, 
                          hint: "24.2", 
                          readOnly: true,
                        )),
                        const SizedBox(width: 15),
                        Expanded(child: _buildDropdownField(
                          label: "Blood Group", 
                          icon: Icons.bloodtype_rounded, 
                          value: _selectedBloodGroup, 
                          items: _bloodGroups, 
                          onChanged: (val) => setState(() => _selectedBloodGroup = val)
                        )),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveVitals,
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
                          isEdit ? "UPDATE PARAMETERS" : "SAVE HEALTH PARAMETERS",
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEdit ? "Refine Your Parameters" : "New Parameters Entry",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
        ),
        const SizedBox(height: 8),
        Text(
          isEdit ? "Keep your health history accurate." : "Logging vitals regularly helps track your progress.",
          style: const TextStyle(color: Color(0xFF546E7A), fontSize: 14),
        ),
      ],
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
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF546E7A), letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0).withAlpha(153), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0).withAlpha(153), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

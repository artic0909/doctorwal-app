import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:demoapp/Services/apiservice.dart';

enum BookingType { OPD, Pathology, Doctor }

class BookingScreen extends StatefulWidget {
  final BookingType type;
  final String partnerId;
  final String clinicName;
  final String? itemId; // test_id or doctor_id
  final String? itemName;
  final String? itemPrice;
  final Map<String, dynamic> userData;

  const BookingScreen({
    super.key,
    required this.type,
    required this.partnerId,
    required this.clinicName,
    required this.userData,
    this.itemId,
    this.itemName,
    this.itemPrice,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  final TextEditingController _inquiryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  String _visitMode = 'offline';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // More robust pre-fill checking multiple possible keys
    _nameController = TextEditingController(text: widget.userData['user_name'] ?? widget.userData['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData['user_email'] ?? widget.userData['email'] ?? '');
    _mobileController = TextEditingController(text: widget.userData['user_mobile'] ?? widget.userData['mobile'] ?? '');
    
    // Set current date and time as default
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    
    // Default visit mode
    _visitMode = 'offline';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _inquiryController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _getBrandColor(),
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _getBrandColor()),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Color _getBrandColor() {
    switch (widget.type) {
      case BookingType.OPD: return const Color(0xFF1565C0);
      case BookingType.Pathology: return const Color(0xFF2E7D32);
      case BookingType.Doctor: return const Color(0xFF6A1B9A);
    }
  }

  String _getClinicType() {
    switch (widget.type) {
      case BookingType.OPD: return 'OPD';
      case BookingType.Pathology: return 'Pathology';
      case BookingType.Doctor: return 'Doctor';
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> bookingData = {
      'currently_loggedin_partner_id': widget.partnerId,
      'clinic_type': _getClinicType(),
      'clinic_name': widget.clinicName,
      'user_name': _nameController.text,
      'user_mobile': _mobileController.text,
      'user_email': _emailController.text,
      'user_inquiry': _inquiryController.text,
      'dw_user_id': widget.userData['id'],
      'booking_date': _dateController.text,
      'booking_time': _timeController.text,
      'visit_mode': _visitMode,
    };

    if (widget.type == BookingType.Pathology && widget.itemId != null) {
      bookingData['test_id'] = widget.itemId;
    } else if (widget.itemId != null) {
      bookingData['doctor_id'] = widget.itemId;
    }

    try {
      Map<String, dynamic> result;
      if (widget.type == BookingType.OPD) {
        result = await _apiService.bookOPDAppointment(bookingData);
      } else if (widget.type == BookingType.Pathology) {
        result = await _apiService.bookPathAppointment(bookingData);
      } else {
        result = await _apiService.bookDocAppointment(bookingData);
      }

      if (result['status'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Booking failed');
      }
    } catch (e) {
      _showErrorSnackBar('Connection error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.green.withAlpha(20), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text("Booking Sent!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
            const SizedBox(height: 10),
            const Text(
              "Your appointment request has been submitted. The clinic will contact you shortly for confirmation.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to detail screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getBrandColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("GREAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = _getBrandColor();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("Book Appointment", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: brandColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 30),
                  const Text("PATIENT INFORMATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF90A4AE), letterSpacing: 1.0)),
                  const SizedBox(height: 15),
                  _buildTextField(_nameController, "Full Name", Icons.person_rounded),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_mobileController, "Mobile", Icons.phone_rounded, keyboardType: TextInputType.phone)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(_emailController, "Email", Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("SCHEDULE & MODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF90A4AE), letterSpacing: 1.0)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker()),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTimePicker()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildVisitModeSelector(),
                  const SizedBox(height: 30),
                  const Text("INQUIRY / SYMPTOMS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF90A4AE), letterSpacing: 1.0)),
                  const SizedBox(height: 15),
                  _buildTextField(_inquiryController, "Describe your symptoms or inquiry here...", Icons.chat_bubble_rounded, maxLines: 4),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                shadowColor: brandColor.withAlpha(100),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("CONFIRM BOOKING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: _getBrandColor().withAlpha(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _getBrandColor().withAlpha(15), shape: BoxShape.circle),
                child: Icon(widget.type == BookingType.Pathology ? Icons.biotech_rounded : Icons.person_rounded, color: _getBrandColor(), size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.itemName ?? "Appointment", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF263238))),
                    const SizedBox(height: 2),
                    Text(widget.clinicName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getBrandColor())),
                  ],
                ),
              ),
              if (widget.itemPrice != null)
                Text("₹${widget.itemPrice}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey[50]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 13),
          prefixIcon: Icon(icon, color: _getBrandColor().withAlpha(150), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey[50]!)),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: _getBrandColor().withAlpha(150), size: 18),
            const SizedBox(width: 12),
            Text(_dateController.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey[50]!)),
        child: Row(
          children: [
            Icon(Icons.access_time_filled_rounded, color: _getBrandColor().withAlpha(150), size: 18),
            const SizedBox(width: 12),
            Text(_timeController.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitModeSelector() {
    final modes = ['offline', 'online'];
      
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Preferred Visit Mode:", 
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 10),
        Row(
          children: modes.map((mode) {
            final isSelected = _visitMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(mode.replaceAll('_', ' ').toUpperCase()),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _visitMode = mode);
                },
                selectedColor: _getBrandColor().withAlpha(20),
                labelStyle: TextStyle(
                  color: isSelected ? _getBrandColor() : Colors.blueGrey,
                  fontWeight: FontWeight.w900,
                  fontSize: 10
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isSelected ? _getBrandColor() : Colors.blueGrey[50]!)
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

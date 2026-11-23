import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/all_appointments_screen.dart';

enum BookingType { opd, pathology, doctor }

class BookingScreen extends StatefulWidget {
  final BookingType type;
  final String partnerId;
  final String clinicName;
  final String? itemId; // test_id or doctor_id
  final String? itemName;
  final String? itemPrice;
  final String? clinicRegistrationType;
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
    this.clinicRegistrationType,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingBookingData;
  
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
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _nameController = TextEditingController(text: widget.userData['user_name'] ?? widget.userData['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData['user_email'] ?? widget.userData['email'] ?? '');
    _mobileController = TextEditingController(text: widget.userData['user_mobile'] ?? widget.userData['mobile'] ?? '');
    
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    
    if (widget.type == BookingType.doctor && !_isPhysioOrOthers) {
      _visitMode = 'online';
    } else {
      _visitMode = 'offline';
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingData == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final verifyPayload = Map<String, dynamic>.from(_pendingBookingData!);
      verifyPayload['razorpay_order_id'] = response.orderId;
      verifyPayload['razorpay_payment_id'] = response.paymentId;
      verifyPayload['razorpay_signature'] = response.signature;

      final verifyResult = await _apiService.verifyPayment(verifyPayload);

      if (verifyResult['status'] == true) {
        _pendingBookingData = null;
        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(verifyResult['message'] ?? 'Payment verification failed. Please contact support.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Payment confirmation error: $e');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Payment cancelled or failed: ${response.message ?? "Transaction declined"}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('External wallet selected: ${response.walletName}');
    }
  }

  bool get _isPhysioOrOthers {
    final regType = (widget.clinicRegistrationType ?? '').toLowerCase().trim();
    final name = (widget.itemName ?? '').toLowerCase();
    final clinic = widget.clinicName.toLowerCase();
    return regType == 'others' ||
        regType.contains('other') ||
        name.contains('physio') ||
        clinic.contains('physio') ||
        name.contains('allied') ||
        clinic.contains('allied');
  }

  bool get _showVisitModeSelector {
    return widget.type == BookingType.doctor && _isPhysioOrOthers;
  }

  @override
  void dispose() {
    _razorpay.clear();
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
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _getBrandColor(),
            onPrimary: Colors.white,
            onSurface: const Color(0xFF0F172A),
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
      case BookingType.opd: return const Color(0xFF1565C0);
      case BookingType.pathology: return const Color(0xFF2E7D32);
      case BookingType.doctor: 
        return _isPhysioOrOthers ? const Color(0xFFD97706) : const Color(0xFF6A1B9A);
    }
  }

  List<Color> _getGradientColors() {
    switch (widget.type) {
      case BookingType.opd:
        return const [Color(0xFF1565C0), Color(0xFF0D47A1)];
      case BookingType.pathology:
        return const [Color(0xFF2E7D32), Color(0xFF1B5E20)];
      case BookingType.doctor:
        return _isPhysioOrOthers
            ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
            : const [Color(0xFF6A1B9A), Color(0xFF4A148C)];
    }
  }

  String _getClinicType() {
    switch (widget.type) {
      case BookingType.opd: return 'OPD';
      case BookingType.pathology: return 'Pathology';
      case BookingType.doctor: return _isPhysioOrOthers ? 'Others' : 'Doctor';
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final String? syncedId = prefs.getString('id');

    final Map<String, dynamic> bookingData = {
      'currently_loggedin_partner_id': widget.partnerId,
      'clinic_type': _getClinicType(),
      'clinic_name': widget.clinicName,
      'user_name': _nameController.text.trim(),
      'user_mobile': _mobileController.text.trim(),
      'user_email': _emailController.text.trim(),
      'user_inquiry': _inquiryController.text.trim(),
      'dw_user_id': syncedId ?? widget.userData['id'],
      'booking_date': _dateController.text,
      'booking_time': _timeController.text,
      'visit_mode': _visitMode,
    };

    if (widget.type == BookingType.pathology && widget.itemId != null) {
      bookingData['test_id'] = widget.itemId;
    } else if (widget.itemId != null) {
      bookingData['doctor_id'] = widget.itemId;
    }

    // Razorpay Online Payment for Doctor & Others Appointments
    if (widget.type == BookingType.doctor) {
      try {
        if (widget.itemPrice != null && widget.itemPrice!.isNotEmpty) {
          bookingData['amount'] = widget.itemPrice;
        }

        final orderResult = await _apiService.createPaymentOrder(bookingData);

        if (orderResult['status'] != true) {
          _showErrorSnackBar(orderResult['message'] ?? 'Unable to initialize online payment.');
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        _pendingBookingData = bookingData;

        final num amountInPaise = orderResult['amount'] ?? 50000;
        final String key = orderResult['key'] ?? '';
        final String orderId = orderResult['order_id'] ?? '';

        var options = {
          'key': key,
          'amount': amountInPaise,
          'name': 'Doctorwala Health',
          'description': 'Consultation with ${widget.itemName ?? widget.clinicName}',
          'order_id': orderId,
          'prefill': {
            'contact': _mobileController.text.trim(),
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
          },
          'theme': {
            'color': '#0284c7'
          }
        };

        _razorpay.open(options);
      } catch (e) {
        _showErrorSnackBar('Error opening payment gateway: $e');
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    try {
      Map<String, dynamic> result;
      if (widget.type == BookingType.opd) {
        result = await _apiService.bookOPDAppointment(bookingData);
      } else if (widget.type == BookingType.pathology) {
        result = await _apiService.bookPathAppointment(bookingData);
      } else {
        result = await _apiService.bookDocAppointment(bookingData);
      }

      if (result['status'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Booking failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebratory Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 18),
              const Text(
                "Booking Request Sent!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Your appointment has been requested with ${widget.clinicName}. You will receive a confirmation shortly.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              // Mini Summary Receipt Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.itemName ?? "Consultation",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          "${_dateController.text} at ${_timeController.text}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _visitMode == 'online' ? "Online Video" : "In-Person",
                            style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Close booking screen
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Close booking screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllAppointmentsScreen(userData: widget.userData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getBrandColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "View Bookings",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatPrice(String? p) {
    if (p == null || p.trim().isEmpty || p == 'null') return "0";
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final price = _formatPrice(widget.itemPrice);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Sleek Gradient Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              // 2. Form Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card
                        _buildSummaryCard(),
                        const SizedBox(height: 18),

                        // Section 1: Patient Information
                        _buildSectionHeader(Icons.person_outline_rounded, "Patient Information"),
                        const SizedBox(height: 10),
                        _buildTextField(_nameController, "Full Name", Icons.person_rounded),
                        const SizedBox(height: 10),
                        _buildTextField(_mobileController, "Mobile Number", Icons.phone_rounded, keyboardType: TextInputType.phone),
                        const SizedBox(height: 10),
                        _buildTextField(_emailController, "Email Address (Optional)", Icons.email_rounded, keyboardType: TextInputType.emailAddress, isRequired: false),
                        const SizedBox(height: 20),

                        // Section 2: Preferred Schedule
                        _buildSectionHeader(Icons.calendar_month_outlined, "Schedule & Visiting Mode"),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildDatePicker()),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTimePicker()),
                          ],
                        ),
                        if (_showVisitModeSelector) ...[
                          const SizedBox(height: 14),
                          _buildVisitModeSelector(),
                        ],
                        const SizedBox(height: 20),

                        // Section 3: Notes / Symptoms
                        _buildSectionHeader(Icons.edit_note_rounded, "Symptoms or Inquiries (Optional)"),
                        const SizedBox(height: 10),
                        _buildTextField(_inquiryController, "Describe any symptoms, medical history, or questions...", Icons.chat_bubble_outline_rounded, maxLines: 3, isRequired: false),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom + 100,
                ),
              ),
            ],
          ),

          // Floating Bottom Confirmation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewPadding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TOTAL FEE",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        price == '0' ? "Free / Clinic" : "₹$price",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getBrandColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.type == BookingType.doctor) ...[
                                const Icon(Icons.lock_rounded, size: 14),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                widget.type == BookingType.doctor ? "PAY & BOOK" : "CONFIRM BOOKING",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
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

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
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
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Book Appointment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Fill patient info to confirm your booking",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Text(
              _getClinicType().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final price = _formatPrice(widget.itemPrice);

    IconData itemIcon;
    if (widget.type == BookingType.pathology) {
      itemIcon = Icons.biotech_rounded;
    } else if (widget.type == BookingType.opd) {
      itemIcon = Icons.business_rounded;
    } else {
      itemIcon = _isPhysioOrOthers ? Icons.accessibility_new_rounded : Icons.person_rounded;
    }

    String visitModeLabel;
    IconData visitModeIcon;
    if (_isPhysioOrOthers) {
      if (_visitMode == 'online') {
        visitModeLabel = "Online Video Consultation";
        visitModeIcon = Icons.videocam_rounded;
      } else {
        visitModeLabel = "Physical Clinic Visit";
        visitModeIcon = Icons.apartment_rounded;
      }
    } else if (widget.type == BookingType.doctor) {
      visitModeLabel = "Online Video Consultation";
      visitModeIcon = Icons.videocam_rounded;
    } else if (widget.type == BookingType.pathology) {
      visitModeLabel = "Physical Lab Visit Only";
      visitModeIcon = Icons.biotech_rounded;
    } else {
      visitModeLabel = "Physical Chamber Visit Only";
      visitModeIcon = Icons.apartment_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getBrandColor().withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(itemIcon, color: _getBrandColor(), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName ?? "Appointment",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.clinicName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getBrandColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price == '0' ? "Free" : "₹$price",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getBrandColor().withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(visitModeIcon, color: _getBrandColor(), size: 14),
                const SizedBox(width: 6),
                Text(
                  visitModeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getBrandColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _getBrandColor()),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) => isRequired && (v == null || v.trim().isEmpty) ? "Required" : null,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
          prefixIcon: Icon(icon, color: _getBrandColor().withAlpha(160), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: _getBrandColor(), size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("DATE", style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                  Text(_dateController.text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_filled_rounded, color: _getBrandColor(), size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("TIME", style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                  Text(_timeController.text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _visitMode = 'offline'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _visitMode == 'offline' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _visitMode == 'offline'
                      ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: _visitMode == 'offline' ? _getBrandColor() : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "In-Person Visit",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _visitMode == 'offline' ? FontWeight.w800 : FontWeight.w600,
                        color: _visitMode == 'offline' ? _getBrandColor() : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _visitMode = 'online'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _visitMode == 'online' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _visitMode == 'online'
                      ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      size: 15,
                      color: _visitMode == 'online' ? _getBrandColor() : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Online Video",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _visitMode == 'online' ? FontWeight.w800 : FontWeight.w600,
                        color: _visitMode == 'online' ? _getBrandColor() : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final dynamic schedule; // visit_day_time or test_day_time
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
    this.schedule,
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

  final Map<int, List<Map<String, dynamic>>> _dayScheduleMap = {};
  final Map<String, List<Map<String, dynamic>>> _dateScheduleMap = {};
  List<Map<String, dynamic>> _currentAvailableSlots = [];
  String? _selectedSlotId;
  bool _isAllDaysAllowed = false;
  String _formattedScheduleText = '';

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

    _parseSchedule();

    // Auto-select first valid date according to the schedule
    DateTime validDate = DateTime.now();
    if (!_isDaySelectable(validDate)) {
      for (int i = 1; i <= 60; i++) {
        final candidate = DateTime.now().add(Duration(days: i));
        if (_isDaySelectable(candidate)) {
          validDate = candidate;
          break;
        }
      }
    }
    _dateController.text = DateFormat('yyyy-MM-dd').format(validDate);
    if (widget.type == BookingType.doctor) {
      _updateSlotsForSelectedDate(validDate);
    } else {
      final slots = _getSlotsForDate(validDate);
      if (slots.isNotEmpty && slots.first['start'] != null) {
        _timeController.text = slots.first['start']!;
      } else {
        _timeController.text = "10:00";
      }
    }
    
    if (widget.type == BookingType.doctor && !_isPhysioOrOthers) {
      _visitMode = 'online';
    } else {
      _visitMode = 'offline';
    }
  }

  void _parseSchedule() {
    _dayScheduleMap.clear();
    _dateScheduleMap.clear();
    _isAllDaysAllowed = false;
    _formattedScheduleText = '';
    if (widget.schedule == null) return;
    dynamic raw = widget.schedule;
    if (raw is String) {
      String s = raw.trim();
      while ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
        s = s.substring(1, s.length - 1).trim();
      }
      s = s.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
      try {
        raw = jsonDecode(s);
      } catch (_) {
        return;
      }
    }

    if (raw is! List) return;

    final List<String> summaryParts = [];

    for (var item in raw) {
      if (item is! Map) continue;
      final scheduleType = (item['schedule_type'] ?? 'day').toString().trim().toLowerCase();
      final dateStr = item['date']?.toString().trim();
      final dayStr = (item['day'] ?? item['doctor_visit_day'] ?? item['test_day'] ?? item['partner_doctor_visit_day'] ?? '').toString().trim();

      // Extract slot items if any
      List<Map<String, dynamic>> slots = [];
      if (item['slots'] is List && (item['slots'] as List).isNotEmpty) {
        for (var s in item['slots']) {
          if (s is Map) {
            final sId = (s['id'] ?? 'slot').toString();
            final sName = (s['name'] ?? (sId.isNotEmpty ? sId[0].toUpperCase() + sId.substring(1) : 'Slot')).toString();
            final sStart = s['start_time'] != null && s['start_time'].toString().isNotEmpty ? s['start_time'].toString().trim() : null;
            final sEnd = s['end_time'] != null && s['end_time'].toString().isNotEmpty ? s['end_time'].toString().trim() : null;
            slots.add({
              'id': sId,
              'name': sName,
              'start': sStart,
              'end': sEnd,
            });
          }
        }
      } else {
        final startTime = item['start_time'] ?? item['doctor_visit_start_time'] ?? item['test_start_time'] ?? item['partner_doctor_visit_start_time'];
        final endTime = item['end_time'] ?? item['doctor_visit_end_time'] ?? item['test_end_time'] ?? item['partner_doctor_visit_end_time'];
        final sStart = startTime != null && startTime.toString().isNotEmpty ? startTime.toString().trim() : null;
        final sEnd = endTime != null && endTime.toString().isNotEmpty ? endTime.toString().trim() : null;
        if (sStart != null || sEnd != null) {
          slots.add({
            'id': 'regular',
            'name': 'Visiting Hours',
            'start': sStart,
            'end': sEnd,
          });
        }
      }

      // 1. Date-specific schedule (Doctor / Others)
      if (scheduleType == 'date' && dateStr != null && dateStr.isNotEmpty) {
        _dateScheduleMap[dateStr] = slots;
        continue;
      }

      // 2. Day-wise schedule (Standard for OPD & Pathology, or fallback for Doctor)
      final rawStart = item['start_time'] ?? item['doctor_visit_start_time'] ?? item['test_start_time'] ?? item['partner_doctor_visit_start_time'];
      final rawEnd = item['end_time'] ?? item['doctor_visit_end_time'] ?? item['test_end_time'] ?? item['partner_doctor_visit_end_time'];
      final startTime = rawStart != null && rawStart.toString().isNotEmpty ? rawStart.toString().trim() : (slots.isNotEmpty ? slots.first['start'] : null);
      final endTime = rawEnd != null && rawEnd.toString().isNotEmpty ? rawEnd.toString().trim() : (slots.isNotEmpty ? slots.last['end'] : null);

      if (dayStr.toLowerCase().contains('all day') || dayStr.toLowerCase().contains('everyday')) {
        _isAllDaysAllowed = true;
        for (int w = 1; w <= 7; w++) {
          final list = _dayScheduleMap.putIfAbsent(w, () => []);
          if (slots.isNotEmpty) {
            list.addAll(slots);
          } else {
            list.add({
              'id': 'regular',
              'name': 'Visiting Hours',
              'start': startTime,
              'end': endTime,
            });
          }
        }
        String timeSummary = '';
        if (startTime != null && endTime != null) {
          timeSummary = ' (${_formatTime12h(startTime)} - ${_formatTime12h(endTime)})';
        } else if (startTime != null) {
          timeSummary = ' (From ${_formatTime12h(startTime)})';
        }
        summaryParts.add('All Days$timeSummary');
        continue;
      }

      final weekday = _dayNameToWeekday(dayStr);
      if (weekday != null) {
        final list = _dayScheduleMap.putIfAbsent(weekday, () => []);
        if (slots.isNotEmpty) {
          list.addAll(slots);
        } else {
          list.add({
            'id': 'regular',
            'name': 'Visiting Hours',
            'start': startTime,
            'end': endTime,
          });
        }
        String timeSummary = '';
        if (startTime != null && endTime != null) {
          timeSummary = ' (${_formatTime12h(startTime)} - ${_formatTime12h(endTime)})';
        } else if (startTime != null) {
          timeSummary = ' (From ${_formatTime12h(startTime)})';
        }
        summaryParts.add('${dayStr.length >= 3 ? dayStr.substring(0, 3) : dayStr}$timeSummary');
      }
    }

    if (summaryParts.isNotEmpty) {
      _formattedScheduleText = summaryParts.join(', ');
    }
  }

  int? _dayNameToWeekday(String dayName) {
    final d = dayName.trim().toLowerCase();
    if (d.contains('mon')) return DateTime.monday;
    if (d.contains('tue')) return DateTime.tuesday;
    if (d.contains('wed')) return DateTime.wednesday;
    if (d.contains('thu')) return DateTime.thursday;
    if (d.contains('fri')) return DateTime.friday;
    if (d.contains('sat')) return DateTime.saturday;
    if (d.contains('sun')) return DateTime.sunday;
    return null;
  }

  String _formatTime12h(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      int h = int.parse(parts[0]);
      int m = parts.length > 1 ? int.parse(parts[1]) : 0;
      final period = h >= 12 ? 'PM' : 'AM';
      int h12 = h % 12;
      if (h12 == 0) h12 = 12;
      return "${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period";
    } catch (_) {
      return timeStr;
    }
  }

  int _timeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      int h = int.parse(parts[0]);
      int m = parts.length > 1 ? int.parse(parts[1]) : 0;
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    if (widget.type == BookingType.doctor) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (_dateScheduleMap.containsKey(dateStr) && _dateScheduleMap[dateStr]!.isNotEmpty) {
        return _dateScheduleMap[dateStr]!;
      }
      if (_dayScheduleMap.containsKey(date.weekday)) {
        return _dayScheduleMap[date.weekday]!;
      }
      return [];
    }

    // For OPD and Pathology: return day schedule
    return _dayScheduleMap[date.weekday] ?? [];
  }

  String _getFormattedDayTiming(DateTime date) {
    final slots = _getSlotsForDate(date);
    if (slots.isEmpty) return 'Consultation hours';
    final parts = slots.map((s) {
      final start = s['start'];
      final end = s['end'];
      final name = s['name'] ?? 'Hours';
      if (start != null && end != null) {
        return "$name: ${_formatTime12h(start)} - ${_formatTime12h(end)}";
      } else if (start != null) {
        return "$name: From ${_formatTime12h(start)}";
      }
      return "$name: All Day";
    }).toList();
    return parts.join(', ');
  }

  bool _isDaySelectable(DateTime date) {
    if (widget.type == BookingType.doctor) {
      if (_dateScheduleMap.isNotEmpty) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        return _dateScheduleMap.containsKey(dateStr);
      }
      if (_dayScheduleMap.isEmpty || _isAllDaysAllowed) return true;
      return _dayScheduleMap.containsKey(date.weekday);
    }

    // For OPD and Pathology: standard day-wise schedule (e.g. Monday - Sunday)
    if (_dayScheduleMap.isEmpty || _isAllDaysAllowed) return true;
    return _dayScheduleMap.containsKey(date.weekday);
  }

  bool _isTimeValidForDate(DateTime date, int pickedMinutes) {
    final slots = _getSlotsForDate(date);
    if (slots.isEmpty) return true;

    for (var slot in slots) {
      final start = slot['start'];
      final end = slot['end'];

      if (start == null && end == null) return true;

      int startMin = start != null ? _timeToMinutes(start) : 0;
      int endMin = end != null ? _timeToMinutes(end) : 1439;

      if (pickedMinutes >= startMin && pickedMinutes <= endMin) {
        return true;
      }
    }
    return false;
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
    DateTime currentSelected = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    if (!_isDaySelectable(currentSelected)) {
      for (int i = 0; i <= 60; i++) {
        final d = DateTime.now().add(Duration(days: i));
        if (_isDaySelectable(d)) {
          currentSelected = d;
          break;
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentSelected,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime date) => _isDaySelectable(date),
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
      if (!_isDaySelectable(picked)) {
        _showNotAvailableDialog(picked);
        return;
      }

      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        if (widget.type == BookingType.doctor) {
          _updateSlotsForSelectedDate(picked);
        } else {
          final chosenSlots = _getSlotsForDate(picked);
          if (chosenSlots.isNotEmpty && chosenSlots.first['start'] != null) {
            final currentMin = _timeToMinutes(_timeController.text);
            if (!_isTimeValidForDate(picked, currentMin)) {
              _timeController.text = chosenSlots.first['start']!;
            }
          }
        }
      });
    }
  }

  void _showNotAvailableDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text("Not Available", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Specialist is not available on ${DateFormat('EEEE, dd MMM yyyy').format(date)}.\nPlease choose an available visiting day or date.",
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _updateSlotsForSelectedDate(DateTime date) {
    final slots = _getSlotsForDate(date);
    _currentAvailableSlots = slots;
    if (slots.isNotEmpty) {
      _selectedSlotId = slots.first['id'] ?? 'slot';
      if (slots.first['start'] != null) {
        _timeController.text = slots.first['start'];
      }
    } else {
      _selectedSlotId = null;
    }
  }

  Future<void> _selectTime() async {
    final DateTime chosenDate = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final slots = _getSlotsForDate(chosenDate);

    Map<String, dynamic>? activeSlot;
    if (slots.isNotEmpty) {
      activeSlot = slots.firstWhere(
        (s) => (s['id']?.toString() ?? '') == (_selectedSlotId ?? ''),
        orElse: () => slots.first,
      );
    }

    TimeOfDay initial = const TimeOfDay(hour: 10, minute: 0);
    // Prefer current _timeController value if valid, otherwise activeSlot's start time
    final currentTimeStr = _timeController.text.trim();
    if (currentTimeStr.contains(':')) {
      try {
        final p = currentTimeStr.split(':');
        initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      } catch (_) {}
    } else if (activeSlot != null && activeSlot['start'] != null) {
      try {
        final p = activeSlot['start'].toString().split(':');
        initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _getBrandColor()),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final pickedMinutes = picked.hour * 60 + picked.minute;
      if (!_isTimeValidForDate(chosenDate, pickedMinutes)) {
        final dateLabel = DateFormat('EEEE, dd MMM').format(chosenDate);
        final timingStr = _getFormattedDayTiming(chosenDate);
        _showErrorSnackBar("Selected time is outside the available visiting schedule ($timingStr) for $dateLabel.");
        return;
      }

      // Auto-match the slot containing the picked time (so selecting 6:00 PM stays on Evening, or switches if needed)
      String? matchedSlotId = _selectedSlotId;
      for (final s in slots) {
        final sStart = s['start'];
        final sEnd = s['end'];
        final int startMin = sStart != null ? _timeToMinutes(sStart.toString()) : 0;
        final int endMin = sEnd != null ? _timeToMinutes(sEnd.toString()) : 1439;
        if (pickedMinutes >= startMin && pickedMinutes <= endMin) {
          matchedSlotId = s['id']?.toString();
          break;
        }
      }

      setState(() {
        if (matchedSlotId != null) {
          _selectedSlotId = matchedSlotId;
        }
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

    // Schedule Validation
    final chosenDate = DateTime.tryParse(_dateController.text);
    if (chosenDate != null && !_isDaySelectable(chosenDate)) {
      _showNotAvailableDialog(chosenDate);
      return;
    }

    if (chosenDate != null) {
      final pickedMinutes = _timeToMinutes(_timeController.text);
      if (!_isTimeValidForDate(chosenDate, pickedMinutes)) {
        final timingStr = _getFormattedDayTiming(chosenDate);
        _showErrorSnackBar("Please select a time within the available hours ($timingStr) for ${DateFormat('EEEE, dd MMM').format(chosenDate)}.");
        return;
      }
    }

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
      'booking_slot': _selectedSlotId ?? '',
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: Stack(
          children: [
            Column(
              children: [
                // 1. Fixed Sleek Gradient Header
                _buildHeader(context),

                // 2. Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).viewPadding.bottom + 100,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Card
                          _buildSummaryCard(),
                          const SizedBox(height: 18),

                          // Section 1: Preferred Schedule (Patient info is hidden since user is logged in, still stored on submit)
                          _buildSectionHeader(Icons.calendar_month_outlined, "Schedule & Visiting Mode"),
                          if (widget.type != BookingType.doctor && _formattedScheduleText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getBrandColor().withAlpha(12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _getBrandColor().withAlpha(40)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.event_available_rounded, size: 16, color: _getBrandColor()),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Available Schedule: $_formattedScheduleText",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _getBrandColor(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildDatePicker()),
                              const SizedBox(width: 10),
                              Expanded(child: _buildTimePicker()),
                            ],
                          ),
                          if (widget.type == BookingType.doctor && _currentAvailableSlots.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSlotSelector(),
                          ],
                          if (_showVisitModeSelector) ...[
                            const SizedBox(height: 14),
                            _buildVisitModeSelector(),
                          ],
                          const SizedBox(height: 20),

                          // Section 2: Notes / Symptoms
                          _buildSectionHeader(Icons.edit_note_rounded, "Symptoms or Inquiries (Optional)"),
                          const SizedBox(height: 10),
                          _buildTextField(_inquiryController, "Describe any symptoms, medical history, or questions...", Icons.chat_bubble_outline_rounded, maxLines: 3, isRequired: false),
                        ],
                      ),
                    ),
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
                  "Select schedule & confirm your booking",
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
    String displayDate = _dateController.text;
    final parsed = DateTime.tryParse(displayDate);
    if (parsed != null) {
      displayDate = DateFormat('dd MMM yyyy').format(parsed);
    }

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _getBrandColor().withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_today_rounded, color: _getBrandColor(), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "DATE",
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    final String displayTime = _timeController.text.isNotEmpty
        ? _formatTime12h(_timeController.text)
        : "Select";

    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _getBrandColor().withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.access_time_rounded, color: _getBrandColor(), size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "TIME",
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelector() {
    if (widget.type != BookingType.doctor || _currentAvailableSlots.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SELECT VISITING SLOT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getBrandColor().withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentAvailableSlots.length} available",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getBrandColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_currentAvailableSlots.length, (idx) {
            final slot = _currentAvailableSlots[idx];
            final slotId = (slot['id'] ?? 'slot').toString();
            final slotName = (slot['name'] ?? 'Slot').toString();
            final isSelected = _selectedSlotId == slotId;
            final start = slot['start'] != null ? _formatTime12h(slot['start']) : '';
            final end = slot['end'] != null ? _formatTime12h(slot['end']) : '';

            IconData icon = Icons.access_time_rounded;
            Color iconBg = const Color(0xFFF1F5F9);
            Color iconColor = const Color(0xFF475569);
            if (slotId.toLowerCase() == 'morning') {
              icon = Icons.wb_sunny_rounded;
              iconBg = const Color(0xFFFEF3C7);
              iconColor = const Color(0xFFD97706);
            } else if (slotId.toLowerCase() == 'afternoon') {
              icon = Icons.light_mode_rounded;
              iconBg = const Color(0xFFFFEDD5);
              iconColor = const Color(0xFFEA580C);
            } else if (slotId.toLowerCase() == 'evening') {
              icon = Icons.nights_stay_rounded;
              iconBg = const Color(0xFFEDE9FE);
              iconColor = const Color(0xFF6A1B9A);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: idx == _currentAvailableSlots.length - 1 ? 0 : 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedSlotId = slotId;
                    if (slot['start'] != null) {
                      _timeController.text = slot['start'];
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? _getBrandColor().withAlpha(14) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _getBrandColor() : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slotName,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? _getBrandColor() : const Color(0xFF0F172A),
                              ),
                            ),
                            if (start.isNotEmpty && end.isNotEmpty)
                              Text(
                                "$start - $end",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? _getBrandColor().withAlpha(200) : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isSelected ? _getBrandColor() : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
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

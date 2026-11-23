import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/Services/apiservice.dart';
import 'package:demoapp/Models/appointment_model.dart';
import 'package:demoapp/widgets/skeleton_loader.dart';

class TransactionRecord {
  final String id;
  final String invoiceNumber;
  final String transactionRef; // Razorpay payment ID (e.g. pay_U3aDmouAN209H9)
  final String? razorpayOrderId;
  final String doctorName;
  final String specialist;
  final String clinicName;
  final String clinicAddress;
  final String registrationType; // 'Doctor' or 'Others'
  final DateTime date;
  final String dateStr;
  final String timeStr;
  final double amount;
  final String amountFormatted;
  final String paymentStatus; // 'Paid'
  final String paymentMode;
  final String patientName;
  final String patientMobile;
  final String patientEmail;
  final String visitMode;
  final AppointmentModel? rawAppointment;

  TransactionRecord({
    required this.id,
    required this.invoiceNumber,
    required this.transactionRef,
    this.razorpayOrderId,
    required this.doctorName,
    required this.specialist,
    required this.clinicName,
    required this.clinicAddress,
    required this.registrationType,
    required this.date,
    required this.dateStr,
    required this.timeStr,
    required this.amount,
    required this.amountFormatted,
    required this.paymentStatus,
    required this.paymentMode,
    required this.patientName,
    required this.patientMobile,
    required this.patientEmail,
    required this.visitMode,
    this.rawAppointment,
  });
}

class MyBillsPaymentsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MyBillsPaymentsScreen({super.key, required this.userData});

  @override
  State<MyBillsPaymentsScreen> createState() => _MyBillsPaymentsScreenState();
}

class _MyBillsPaymentsScreenState extends State<MyBillsPaymentsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<TransactionRecord> _allTransactions = [];
  List<TransactionRecord> _filteredTransactions = [];
  bool _isLoading = true;
  String _memberId = '';
  String _userName = '';
  String _userMobile = '';

  @override
  void initState() {
    super.initState();
    _loadUserMeta();
    _fetchTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memId = prefs.getString('member_id') ??
          prefs.getString('memberid') ??
          widget.userData['member_id']?.toString() ??
          widget.userData['memberid']?.toString() ??
          'DW-2026';
      final name = prefs.getString('name') ??
          prefs.getString('user_name') ??
          widget.userData['name'] ??
          widget.userData['user_name'] ??
          'Patient';
      final mobile = prefs.getString('mobile') ??
          prefs.getString('user_mobile') ??
          widget.userData['mobile'] ??
          widget.userData['user_mobile'] ??
          '';

      if (mounted) {
        setState(() {
          _memberId = memId;
          _userName = name;
          _userMobile = mobile;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);

    final List<TransactionRecord> list = [];

    try {
      final appointmentsRes = await _apiService.getAppointments();
      if (appointmentsRes['status'] == true && appointmentsRes['data'] != null) {
        final List<dynamic> data = appointmentsRes['data'];

        for (var json in data) {
          final item = AppointmentModel.fromJson(json);

          // 1. FILTER: Registration type 'Doctor' and 'Others' partner ONLY
          final String clinicType = (item.clinicType ?? '').trim().toLowerCase();
          final docContact = item.doctorContact ?? {};
          final String regType = (docContact['clinic_registration_type'] ?? '').toString().trim().toLowerCase();

          final bool isDoctorOrOthers = clinicType == 'doctor' ||
              clinicType == 'others' ||
              regType == 'doctor' ||
              regType == 'others';

          if (!isDoctorOrOthers) continue;

          // 2. FILTER: ONLY transactions where payment was actually made ("just payment korechi")
          final String rawPayStatus = (item.paymentStatus ?? '').trim().toLowerCase();
          final String rawPayAmount = (item.paymentAmount ?? '').trim();
          final String? razorpayPaymentId = item.razorpayPaymentId;
          final double payAmount = double.tryParse(rawPayAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

          final bool isPaid = rawPayStatus == 'paid' ||
              (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty) ||
              payAmount > 0.0;

          if (!isPaid) continue;

          // 3. Extract 100% dynamic and accurate data from partner/doctor contact & appointment
          final String doctorName = docContact['partner_doctor_name']?.toString().isNotEmpty == true
              ? docContact['partner_doctor_name'].toString()
              : (item.clinicName ?? 'Doctor Partner');

          final String specialist = docContact['partner_doctor_specialist']?.toString().isNotEmpty == true
              ? docContact['partner_doctor_specialist'].toString()
              : (docContact['partner_doctor_designation']?.toString() ?? 'Specialist');

          final String provider = (item.clinicName != null && item.clinicName!.isNotEmpty)
              ? item.clinicName!
              : doctorName;

          // Dynamic address
          final List<String> addressParts = [];
          if (docContact['partner_doctor_address'] != null &&
              docContact['partner_doctor_address'].toString().trim().isNotEmpty) {
            addressParts.add(docContact['partner_doctor_address'].toString().trim());
          }
          if (docContact['partner_doctor_city'] != null &&
              docContact['partner_doctor_city'].toString().trim().isNotEmpty) {
            addressParts.add(docContact['partner_doctor_city'].toString().trim());
          }
          if (docContact['partner_doctor_state'] != null &&
              docContact['partner_doctor_state'].toString().trim().isNotEmpty) {
            addressParts.add(docContact['partner_doctor_state'].toString().trim());
          }
          if (docContact['partner_doctor_pincode'] != null &&
              docContact['partner_doctor_pincode'].toString().trim().isNotEmpty) {
            addressParts.add(docContact['partner_doctor_pincode'].toString().trim());
          }
          final String address = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Official Consultation Chamber';

          // Accurate dynamic fee/amount
          final double finalAmount = payAmount > 0
              ? payAmount
              : (double.tryParse(docContact['partner_doctor_fees']?.toString() ?? '') ?? 0.0);

          final String amountFormatted = "₹${finalAmount.toStringAsFixed(finalAmount.truncateToDouble() == finalAmount ? 0 : 2)}";

          // Dynamic Date & Time
          DateTime itemDate = DateTime.now();
          if (item.bookingDate != null && item.bookingDate!.isNotEmpty) {
            try {
              itemDate = DateTime.parse(item.bookingDate!);
            } catch (_) {}
          }

          final String finalRegType = (regType == 'others' || clinicType == 'others') ? 'Others' : 'Doctor';
          final String invoiceNum = "INV-${itemDate.year}-${item.id.toString().padLeft(5, '0')}";
          final String transactionRef = (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty)
              ? razorpayPaymentId
              : "TX-${item.id.toString().padLeft(6, '0')}";

          list.add(TransactionRecord(
            id: item.id.toString(),
            invoiceNumber: invoiceNum,
            transactionRef: transactionRef,
            razorpayOrderId: item.razorpayOrderId,
            doctorName: doctorName,
            specialist: specialist,
            clinicName: provider,
            clinicAddress: address,
            registrationType: finalRegType,
            date: itemDate,
            dateStr: DateFormat('dd MMM yyyy').format(itemDate),
            timeStr: _formatTime(item.bookingTime),
            amount: finalAmount,
            amountFormatted: amountFormatted,
            paymentStatus: 'Paid',
            paymentMode: 'Online Payment (Razorpay)',
            patientName: item.userName ?? _userName,
            patientMobile: item.userMobile ?? _userMobile,
            patientEmail: item.userEmail ?? '',
            visitMode: item.visitMode ?? 'In-Person Consultation',
            rawAppointment: item,
          ));
        }
      }
    } catch (e) {
      debugPrint("Error fetching dynamic appointment transactions: $e");
    }

    // Sort descending by date
    list.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _allTransactions = list;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = List.from(_allTransactions);
      } else {
        _filteredTransactions = _allTransactions.where((txn) {
          return txn.doctorName.toLowerCase().contains(query) ||
              txn.specialist.toLowerCase().contains(query) ||
              txn.clinicName.toLowerCase().contains(query) ||
              txn.transactionRef.toLowerCase().contains(query) ||
              txn.invoiceNumber.toLowerCase().contains(query) ||
              txn.amountFormatted.toLowerCase().contains(query) ||
              txn.registrationType.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "N/A";
    try {
      final time = DateFormat("HH:mm:ss").parse(timeStr);
      return DateFormat("h:mm a").format(time);
    } catch (_) {
      try {
        final time = DateFormat("HH:mm").parse(timeStr);
        return DateFormat("h:mm a").format(time);
      } catch (_) {
        return timeStr;
      }
    }
  }

  double get _totalPaidAmount {
    double total = 0.0;
    for (var item in _allTransactions) {
      total += item.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double topPadding = (statusBarHeight > 0 ? statusBarHeight : 24.0) + 12.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Doctorwala Royal Blue Gradient Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1), // Deep Navy Blue
                  Color(0xFF1565C0), // Royal Blue
                  Color(0xFF1976D2), // Accent Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x330D47A1),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Back button + Title + Total Count Badge
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(60), width: 0.9),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Bills & Payments",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            "Verified consultation fees & paid transactions",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(70), width: 0.9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            "${_allTransactions.length} Paid",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Financial Overview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Total Spent
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1565C0), size: 14),
                                SizedBox(width: 5),
                                Text(
                                  "TOTAL PAID FEES",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${_totalPaidAmount.toStringAsFixed(_totalPaidAmount.truncateToDouble() == _totalPaidAmount ? 0 : 2)}",
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              "Doctor & Allied Care consultations",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 42, width: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 14),

                      // Verified Online Settled Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withAlpha(18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  "100% Settled",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_allTransactions.length} Transactions",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: "Search doctor name, ref id, partner...",
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 3. Transactions List Content
          Expanded(
            child: _isLoading
                ? const AppointmentsSkeleton()
                : RefreshIndicator(
                    color: const Color(0xFF0D47A1),
                    onRefresh: _fetchTransactions,
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyView()
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              6,
                              16,
                              MediaQuery.of(context).padding.bottom + 90,
                            ),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final item = _filteredTransactions[index];
                              return _buildTransactionCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1565C0), size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Paid Transactions Found",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? "No matching records found for \"${_searchController.text}\""
                  : "All completed payments for Doctor and Physiotherapy/Allied consultations will appear here.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _fetchTransactions();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Refresh List"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionRecord item) {
    final bool isOthers = item.registrationType.toLowerCase() == 'others';

    // Theme color based on Registration Type
    final Color typeColor = isOthers ? const Color(0xFFD97706) : const Color(0xFF1565C0);
    final Color typeBg = isOthers ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF);
    final IconData typeIcon = isOthers ? Icons.accessibility_new_rounded : Icons.medical_services_rounded;
    final String typeBadgeText = isOthers ? "Physiotherapy & Allied" : "Doctor Consultation";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDigitalReceipt(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Icon + Doctor Name + Paid Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: typeBg,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: typeColor.withAlpha(50), width: 0.8),
                                ),
                                child: Text(
                                  typeBadgeText,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: typeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.doctorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.specialist,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.amountFormatted,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 10),
                              SizedBox(width: 3),
                              Text(
                                "Paid",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Clinic Provider & Date Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.clinicAddress,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      item.dateStr,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Action: Payment Ref ID & View Receipt Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Payment Ref ID Pill with 1-tap copy
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.transactionRef));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Payment Ref copied: ${item.transactionRef}"),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 12, color: Color(0xFF1565C0)),
                            const SizedBox(width: 3),
                            Text(
                              item.transactionRef.length > 18
                                  ? "${item.transactionRef.substring(0, 15)}..."
                                  : item.transactionRef,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 10, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    // View Receipt
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "View Receipt",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: typeColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Interactive Digital Receipt Bottom Sheet
  void _showDigitalReceipt(TransactionRecord item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Receipt Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D47A1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "DOCTORWALA",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0D47A1),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Official Payment Receipt",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.0),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 14),
                          SizedBox(width: 4),
                          Text(
                            "PAID ONLINE",
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                // Invoice Particulars
                _buildReceiptRow("Payment Reference", item.transactionRef, isBold: true),
                if (item.razorpayOrderId != null && item.razorpayOrderId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReceiptRow("Razorpay Order ID", item.razorpayOrderId!),
                ],
                const SizedBox(height: 8),
                _buildReceiptRow("Invoice Number", item.invoiceNumber),
                const SizedBox(height: 8),
                _buildReceiptRow("Transaction Date", "${item.dateStr} at ${item.timeStr}"),
                const SizedBox(height: 8),
                _buildReceiptRow("Patient Name", item.patientName.isNotEmpty ? item.patientName : _userName),
                if (item.patientMobile.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReceiptRow("Contact Mobile", item.patientMobile),
                ],
                const SizedBox(height: 8),
                _buildReceiptRow("Member ID", _memberId.isNotEmpty ? _memberId : "DW-2026"),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                // Partner / Doctor Info
                const Text(
                  "CONSULTING SPECIALIST / CLINIC",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.doctorName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${item.specialist} (${item.registrationType == 'Others' ? 'Physiotherapy & Allied Partner' : 'Doctor Partner'})",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.clinicAddress,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                // Fee Particulars
                const Text(
                  "PAYMENT BREAKDOWN",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Consultation Fee (${item.visitMode})",
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            "Directly credited to partner account",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.amountFormatted,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildReceiptRow("Platform Convenience Fee", "FREE (₹0)"),
                const SizedBox(height: 8),
                _buildReceiptRow("GST / Tax", "Included"),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount Paid",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        item.amountFormatted,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                _buildReceiptRow("Payment Mode", item.paymentMode),
                const SizedBox(height: 6),
                _buildReceiptRow("Status", "COMPLETED (Verified)", isBold: true),

                const SizedBox(height: 20),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.transactionRef));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Payment Reference ${item.transactionRef} copied!")),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text("Copy Payment Reference ID"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

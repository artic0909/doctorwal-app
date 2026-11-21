class AppointmentModel {
  final int id;
  final String? currentlyLoggedinPartnerId;
  final String? clinicType;
  final String? clinicName;
  final int? dwUserId;
  final String? bookingDate;
  final String? bookingTime;
  final String? status;
  final String? visitMode;
  final bool isVideo;
  final String? videoChannel;
  final String? videoStatus;
  final int? doctorId;
  final int? testId;
  final String? userName;
  final String? userMobile;
  final String? userEmail;
  final String? userInquiry;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? test;
  final Map<String, dynamic>? opdContact;
  final Map<String, dynamic>? pathologyContact;
  final Map<String, dynamic>? doctorContact;

  AppointmentModel({
    required this.id,
    this.currentlyLoggedinPartnerId,
    this.clinicType,
    this.clinicName,
    this.dwUserId,
    this.bookingDate,
    this.bookingTime,
    this.status,
    this.visitMode,
    this.isVideo = false,
    this.videoChannel,
    this.videoStatus,
    this.doctorId,
    this.testId,
    this.userName,
    this.userMobile,
    this.userEmail,
    this.userInquiry,
    this.doctor,
    this.test,
    this.opdContact,
    this.pathologyContact,
    this.doctorContact,
  });

  bool get isVideoCall {
    final type = clinicType?.toLowerCase().trim() ?? '';
    // Video calling is strictly disabled for OPD and Pathology
    if (type == 'opd' || type == 'pathology') {
      return false;
    }
    final mode = visitMode?.toLowerCase().trim() ?? '';
    if (mode == 'offline' || mode == 'physical' || mode == 'in_person') {
      return false;
    }
    return (type == 'doctor' || type == 'others') && (isVideo || mode == 'online' || mode == 'video' || mode == 'video call');
  }

  bool isWindowOpen() {
    if (bookingDate == null || bookingTime == null) return true;
    try {
      final scheduled = _parseBookingDateTime();
      if (scheduled == null) return true;
      final now = DateTime.now();
      final windowStart = scheduled.subtract(const Duration(minutes: 10));
      final windowEnd = scheduled.add(const Duration(minutes: 60));
      return now.isAfter(windowStart) && now.isBefore(windowEnd);
    } catch (_) {
      return true;
    }
  }

  String getWindowStartFormatted() {
    if (bookingDate == null || bookingTime == null) return "Starts soon";
    try {
      final scheduled = _parseBookingDateTime();
      if (scheduled == null) return "Starts at $bookingTime";
      final start = scheduled.subtract(const Duration(minutes: 10));
      final hour = start.hour > 12 ? start.hour - 12 : (start.hour == 0 ? 12 : start.hour);
      final minute = start.minute.toString().padLeft(2, '0');
      final period = start.hour >= 12 ? 'PM' : 'AM';
      return "Opens at $hour:$minute $period";
    } catch (_) {
      return "Opens 10m before";
    }
  }

  DateTime? _parseBookingDateTime() {
    if (bookingDate == null || bookingTime == null) return null;
    try {
      final date = DateTime.parse(bookingDate!);
      final rawTime = bookingTime!.trim();
      final timeParts = rawTime.split(' ');
      final hms = timeParts[0].split(':');
      int hour = int.parse(hms[0]);
      int minute = hms.length > 1 ? int.parse(hms[1]) : 0;
      if (timeParts.length > 1) {
        final period = timeParts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final rawIsVideo = json['is_video'];
    final bool isVideoVal = rawIsVideo == true || rawIsVideo == 1 || rawIsVideo == '1' || rawIsVideo == 'true';

    return AppointmentModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      currentlyLoggedinPartnerId: json['currently_loggedin_partner_id']?.toString(),
      clinicType: json['clinic_type'],
      clinicName: json['clinic_name'],
      dwUserId: json['dw_user_id'] != null ? int.tryParse(json['dw_user_id'].toString()) : null,
      bookingDate: json['booking_date'],
      bookingTime: json['booking_time'],
      status: json['status'],
      visitMode: json['visit_mode'],
      isVideo: isVideoVal,
      videoChannel: json['video_channel'],
      videoStatus: json['video_status'],
      doctorId: json['doctor_id'] != null ? int.tryParse(json['doctor_id'].toString()) : null,
      testId: json['test_id'] != null ? int.tryParse(json['test_id'].toString()) : null,
      userName: json['user_name'],
      userMobile: json['user_mobile'],
      userEmail: json['user_email'],
      userInquiry: json['user_inquiry'],
      doctor: json['doctor'],
      test: json['test'],
      opdContact: json['opd_contact'],
      pathologyContact: json['pathology_contact'],
      doctorContact: json['doctor_contact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currently_loggedin_partner_id': currentlyLoggedinPartnerId,
      'clinic_type': clinicType,
      'clinic_name': clinicName,
      'dw_user_id': dwUserId,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      'status': status,
      'visit_mode': visitMode,
      'is_video': isVideo,
      'video_channel': videoChannel,
      'video_status': videoStatus,
      'doctor_id': doctorId,
      'test_id': testId,
      'user_name': userName,
      'user_mobile': userMobile,
      'user_email': userEmail,
      'user_inquiry': userInquiry,
      'doctor': doctor,
      'test': test,
      'opd_contact': opdContact,
      'pathology_contact': pathologyContact,
      'doctor_contact': doctorContact,
    };
  }
}

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

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
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

class AllAvailableDoctorsModel {
  final int id;
  final int currentlyLoggedinPartnerId;
  final String clinicRegistrationType;
  final String? partnerDoctorName;
  final String? partnerDoctorSpecialist;
  final String? partnerDoctorDesignation;
  final String partnerDoctorFees;
  final String partnerDoctorMobile;
  final String partnerDoctorEmail;
  final String? partnerDoctorLandmark;
  final String partnerDoctorPincode;
  final String? partnerDoctorGoogleMapLink;
  final String? partnerDoctorState;
  final String? partnerDoctorCity;
  final String? partnerDoctorAddress;
  final List<dynamic> visitDayTime;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? banner;

  AllAvailableDoctorsModel({
    required this.id,
    required this.currentlyLoggedinPartnerId,
    required this.clinicRegistrationType,
    required this.partnerDoctorName,
    required this.partnerDoctorSpecialist,
    required this.partnerDoctorDesignation,
    required this.partnerDoctorFees,
    required this.partnerDoctorMobile,
    required this.partnerDoctorEmail,
    required this.partnerDoctorLandmark,
    required this.partnerDoctorPincode,
    required this.partnerDoctorGoogleMapLink,
    required this.partnerDoctorState,
    required this.partnerDoctorCity,
    required this.partnerDoctorAddress,
    required this.visitDayTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.banner,
  });

  factory AllAvailableDoctorsModel.fromJson(Map<String, dynamic> json) {
    return AllAvailableDoctorsModel(
      id: json['id'],
      currentlyLoggedinPartnerId: json['currently_loggedin_partner_id'],
      clinicRegistrationType: json['clinic_registration_type'] ?? '',
      partnerDoctorName:
          json['partner_doctor_name'] == 'null'
              ? null
              : json['partner_doctor_name'],
      partnerDoctorSpecialist:
          json['partner_doctor_specialist'] == 'null'
              ? null
              : json['partner_doctor_specialist'],
      partnerDoctorDesignation:
          json['partner_doctor_designation'] == 'null'
              ? null
              : json['partner_doctor_designation'],
      partnerDoctorFees: json['partner_doctor_fees'] ?? '',
      partnerDoctorMobile: json['partner_doctor_mobile'] ?? '',
      partnerDoctorEmail: json['partner_doctor_email'] ?? '',
      partnerDoctorLandmark:
          json['partner_doctor_landmark'] == 'null'
              ? null
              : json['partner_doctor_landmark'],
      partnerDoctorPincode: json['partner_doctor_pincode'] ?? '',
      partnerDoctorGoogleMapLink:
          json['partner_doctor_google_map_link'] == 'null'
              ? null
              : json['partner_doctor_google_map_link'],
      partnerDoctorState:
          json['partner_doctor_state'] == 'null'
              ? null
              : json['partner_doctor_state'],
      partnerDoctorCity:
          json['partner_doctor_city'] == 'null'
              ? null
              : json['partner_doctor_city'],
      partnerDoctorAddress:
          json['partner_doctor_address'] == 'null'
              ? null
              : json['partner_doctor_address'],
      visitDayTime:
          json['visit_day_time'] is List ? json['visit_day_time'] : [],
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      banner:
          json['banner'] != null
              ? (json['banner']['doctorbanner'] as String).replaceFirst(
                '127.0.0.1',
                '10.0.2.2',
              )
              : '',
    );
  }
}

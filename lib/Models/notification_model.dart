class NotificationModel {
  final int id;
  final int dwUserId;
  final int doctorId;
  final String partnerClinicName;
  final String partnerContactPersonName;
  final String partnerMobileNumber;
  final String partnerEmail;
  final String partnerState;
  final String partnerCity;
  final String partnerLandmark;
  final String partnerPincode;
  final String reqStatus;
  final String accessStatus;
  final String readStatus;
  final String createdAt;
  final String doctorName;
  final String doctorSpecialist;

  NotificationModel({
    required this.id,
    required this.dwUserId,
    required this.doctorId,
    required this.partnerClinicName,
    required this.partnerContactPersonName,
    required this.partnerMobileNumber,
    required this.partnerEmail,
    required this.partnerState,
    required this.partnerCity,
    required this.partnerLandmark,
    required this.partnerPincode,
    required this.reqStatus,
    required this.accessStatus,
    required this.readStatus,
    required this.createdAt,
    required this.doctorName,
    required this.doctorSpecialist,
  });

  String get formattedAddress {
    List<String> parts = [];
    if (partnerCity.isNotEmpty) parts.add(partnerCity);
    if (partnerState.isNotEmpty) parts.add(partnerState);
    if (partnerPincode.isNotEmpty) parts.add(partnerPincode);
    return parts.join(', ');
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] ?? {};
    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      dwUserId: int.tryParse(json['dw_user_id']?.toString() ?? '0') ?? 0,
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '0') ?? 0,
      partnerClinicName: json['partner_clinic_name']?.toString() ?? 'Unknown Clinic',
      partnerContactPersonName: json['partner_contact_person_name']?.toString() ?? '',
      partnerMobileNumber: json['partner_mobile_number']?.toString() ?? '',
      partnerEmail: json['partner_email']?.toString() ?? '',
      partnerState: json['partner_state']?.toString() ?? '',
      partnerCity: json['partner_city']?.toString() ?? '',
      partnerLandmark: json['partner_landmark']?.toString() ?? '',
      partnerPincode: json['partner_pincode']?.toString() ?? '',
      reqStatus: json['req_status']?.toString() ?? '',
      accessStatus: json['access_status']?.toString() ?? '',
      readStatus: json['read_status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      doctorName: doctor['doctor_name']?.toString() ?? 'Unknown Doctor',
      doctorSpecialist: doctor['doctor_specialist']?.toString() ?? 'General Specialist',
    );
  }
}

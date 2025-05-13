class AllAvailableOPDModel {
  final String contactPersonName;
  final String clinicName;
  final String clinicGstin;
  final String clinicMobileNumber;
  final String clinicEmail;
  final String clinicLandmark;
  final String clinicPincode;
  final String clinicState;
  final String clinicCity;
  final String clinicGoogleMapLink;
  final String clinicAddress;
  final String bannerImage;
  final List<dynamic> doctors;
  final List<dynamic> services;

  AllAvailableOPDModel({
    required this.contactPersonName,
    required this.clinicName,
    required this.clinicGstin,
    required this.clinicMobileNumber,
    required this.clinicEmail,
    required this.clinicLandmark,
    required this.clinicPincode,
    required this.clinicState,
    required this.clinicCity,
    required this.clinicGoogleMapLink,
    required this.clinicAddress,
    required this.bannerImage,
    required this.doctors,
    required this.services,
  });

  factory AllAvailableOPDModel.fromJson(Map<String, dynamic> json) {
    final contact = json['opdContact'] ?? {};
    final banner = contact['banner'];

    return AllAvailableOPDModel(
      contactPersonName: contact['clinic_contact_person_name'] ?? '',
      clinicName: contact['clinic_name'] ?? '',
      clinicGstin: contact['clinic_gstin'] ?? '',
      clinicMobileNumber: contact['clinic_mobile_number'] ?? '',
      clinicEmail: contact['clinic_email'] ?? '',
      clinicLandmark: contact['clinic_landmark'] ?? '',
      clinicPincode: contact['clinic_pincode'] ?? '',
      clinicState: contact['clinic_state'] ?? '',
      clinicCity: contact['clinic_city'] ?? '',
      clinicGoogleMapLink: contact['clinic_google_map_link'] ?? '',
      clinicAddress: contact['clinic_address'] ?? '',
      bannerImage: (banner != null && banner['opdbanner'] != null)
          ? banner['opdbanner'].toString().replaceFirst('127.0.0.1', '10.0.2.2')
          : '',
      doctors: json['doctors'] ?? [],
      services: json['services'] ?? [],
    );
  }
}

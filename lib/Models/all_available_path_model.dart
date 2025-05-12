class AllAvailablePathModel {
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

  AllAvailablePathModel({
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
  });

  factory AllAvailablePathModel.fromJson(Map<String, dynamic> json) {
    return AllAvailablePathModel(
      contactPersonName: json['contact_person_name'] ?? '',
      clinicName: json['clinic_name'] ?? '',
      clinicGstin: json['clinic_gstin'] ?? '',
      clinicMobileNumber: json['clinic_mobile_number'] ?? '',
      clinicEmail: json['clinic_email'] ?? '',
      clinicLandmark: json['clinic_landmark'] ?? '',
      clinicPincode: json['clinic_pincode'] ?? '',
      clinicState: json['clinic_state'] ?? '',
      clinicCity: json['clinic_city'] ?? '',
      clinicGoogleMapLink: json['clinic_google_map_link'] ?? '',
      clinicAddress: json['clinic_address'] ?? '',
      bannerImage:
          (json['banner'] != null && json['banner']['pathologybanner'] != null)
              ? json['banner']['pathologybanner'].toString().replaceFirst(
                '127.0.0.1',
                '10.0.2.2',
              )
              : '',
    );
  }
}

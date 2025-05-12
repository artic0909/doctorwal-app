class AllCouponsModel {
  final String couponCode;
  final String couponAmount;
  final String couponStartDate;
  final String couponEndDate;

  AllCouponsModel({
    required this.couponCode,
    required this.couponAmount,
    required this.couponStartDate,
    required this.couponEndDate,
  });

  factory AllCouponsModel.fromJson(Map<String, dynamic> json) {
    return AllCouponsModel(
      couponCode: json['coupon_code'],
      couponAmount: json['coupon_amount'],
      couponStartDate: json['coupon_start_date'],
      couponEndDate: json['coupon_end_date'],
    );
  }
}

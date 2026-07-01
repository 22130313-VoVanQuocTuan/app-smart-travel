class VoucherCreateRequest {
  final String code;
  final double discountAmount;
  final String expiryDate;
  final bool isActive;
  final int usageLimit;
  final int pointsRequired;

  VoucherCreateRequest({
    required this.code,
    required this.discountAmount,
    required this.expiryDate,
    required this.isActive,
    required this.usageLimit,
    required this.pointsRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountAmount': discountAmount,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'usageLimit': usageLimit,
      'pointsRequired': pointsRequired,
    };
  }
}

class VoucherCreateParams {
  final String code;
  final double discountAmount;
  final DateTime expiryDate;
  final bool isActive;
  final int usageLimit;
  final int pointsRequired;

  VoucherCreateParams({
    required this.code,
    required this.discountAmount,
    required this.expiryDate,
    required this.isActive,
    required this.usageLimit,
    required this.pointsRequired,
  });

  Map<String, dynamic> toJson() => {
    "code": code,
    "discountAmount": discountAmount,
    "expiryDate": expiryDate.toIso8601String(),
    "isActive": isActive,
    "usageLimit": usageLimit,
    "pointsRequired": pointsRequired,
  };
}

class VoucherUpdateParams {
  final int id;
  final String code;
  final double discountAmount;
  final DateTime expiryDate;
  final bool isActive;
  final int usageLimit;
  final int pointsRequired;

  VoucherUpdateParams({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.expiryDate,
    required this.isActive,
    required this.usageLimit,
    required this.pointsRequired,
  });

  Map<String, dynamic> toJson() => {
    "code": code,
    "discountAmount": discountAmount,
    "expiryDate": expiryDate.toIso8601String(),
    "isActive": isActive,
    "usageLimit": usageLimit,
    "pointsRequired": pointsRequired,
  };
}

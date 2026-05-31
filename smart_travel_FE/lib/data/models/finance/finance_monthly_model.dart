class FinanceMonthlyModel {
  final String label;
  final double totalRevenue;
  final double commissionRevenue;
  final double homestayRevenue;
  final int bookingCount;

  FinanceMonthlyModel({
    required this.label,
    required this.totalRevenue,
    required this.commissionRevenue,
    required this.homestayRevenue,
    required this.bookingCount,
  });

  factory FinanceMonthlyModel.fromJson(Map<String, dynamic> json) {
    return FinanceMonthlyModel(
      label: json['label'] ?? '',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      commissionRevenue: (json['commissionRevenue'] ?? 0).toDouble(),
      homestayRevenue: (json['homestayRevenue'] ?? 0).toDouble(),
      bookingCount: json['bookingCount'] ?? 0,
    );
  }
}

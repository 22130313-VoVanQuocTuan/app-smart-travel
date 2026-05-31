class FinanceSummaryModel {
  final double totalRevenue;
  final double totalCommission;
  final double totalHomestayRevenue;
  final int totalInvoices;
  final int totalBookings;

  FinanceSummaryModel({
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalHomestayRevenue,
    required this.totalInvoices,
    required this.totalBookings,
  });

  factory FinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinanceSummaryModel(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      totalHomestayRevenue: (json['totalHomestayRevenue'] ?? 0).toDouble(),
      totalInvoices: json['totalInvoices'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
    );
  }
}
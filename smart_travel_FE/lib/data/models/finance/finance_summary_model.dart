class FinanceSummaryModel {
  final int reportYear;
  final int reportMonth;
  final double totalRevenue;
  final double totalCommission;
  final double totalHomestayRevenue;
  final double monthlyCompletedRevenue;
  final double monthlyOnlineRevenue;
  final double monthlyCashRevenue;
  final double monthlyHostPayoutAmount;
  final double monthlyCashCommissionReceivable;
  final int totalInvoices;
  final int totalBookings;

  FinanceSummaryModel({
    required this.reportYear,
    required this.reportMonth,
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalHomestayRevenue,
    required this.monthlyCompletedRevenue,
    required this.monthlyOnlineRevenue,
    required this.monthlyCashRevenue,
    required this.monthlyHostPayoutAmount,
    required this.monthlyCashCommissionReceivable,
    required this.totalInvoices,
    required this.totalBookings,
  });

  factory FinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinanceSummaryModel(
      reportYear: json['reportYear'] ?? 0,
      reportMonth: json['reportMonth'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      totalHomestayRevenue: (json['totalHomestayRevenue'] ?? 0).toDouble(),
      monthlyCompletedRevenue: (json['monthlyCompletedRevenue'] ?? 0).toDouble(),
      monthlyOnlineRevenue: (json['monthlyOnlineRevenue'] ?? 0).toDouble(),
      monthlyCashRevenue: (json['monthlyCashRevenue'] ?? 0).toDouble(),
      monthlyHostPayoutAmount: (json['monthlyHostPayoutAmount'] ?? 0).toDouble(),
      monthlyCashCommissionReceivable: (json['monthlyCashCommissionReceivable'] ?? 0).toDouble(),
      totalInvoices: json['totalInvoices'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
    );
  }
}

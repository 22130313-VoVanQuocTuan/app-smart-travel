class RevenueDataPoint {
  final String label;
  final double revenue;
  final double homestayAmount;
  final double commissionAmount;
  final int invoiceCount;

  RevenueDataPoint({
    required this.label,
    required this.revenue,
    this.homestayAmount = 0,
    this.commissionAmount = 0,
    this.invoiceCount = 0,
  });

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      label: json['label'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      homestayAmount: (json['homestayAmount'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? 0).toDouble(),
      invoiceCount: json['invoiceCount'] ?? 0,
    );
  }
}

class RevenueData {
  final String type;
  final double totalRevenue;
  final List<RevenueDataPoint> dataPoints;

  RevenueData({
    required this.type,
    required this.totalRevenue,
    required this.dataPoints,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    var pointsList = json['dataPoints'] as List? ?? [];
    List<RevenueDataPoint> points = pointsList
        .map((item) => RevenueDataPoint.fromJson(item as Map<String, dynamic>))
        .toList();

    return RevenueData(
      type: json['type'] ?? 'MONTH',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      dataPoints: points,
    );
  }
}

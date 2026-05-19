class CategoryRevenueItem {
  final int homestayId;
  final String homestayName;
  final double revenue;
  final int invoiceCount;
  final double percentage;

  CategoryRevenueItem({
    required this.homestayId,
    required this.homestayName,
    required this.revenue,
    this.invoiceCount = 0,
    this.percentage = 0,
  });

  factory CategoryRevenueItem.fromJson(Map<String, dynamic> json) {
    return CategoryRevenueItem(
      homestayId: json['homestayId'] ?? 0,
      homestayName: json['homestayName'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      invoiceCount: json['invoiceCount'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class CategoryRevenueData {
  final int year;
  final int month;
  final double totalRevenue;
  final List<CategoryRevenueItem> categories;

  CategoryRevenueData({
    required this.year,
    required this.month,
    required this.totalRevenue,
    required this.categories,
  });

  factory CategoryRevenueData.fromJson(Map<String, dynamic> json) {
    var catList = json['categories'] as List? ?? [];
    List<CategoryRevenueItem> cats = catList
        .map((item) => CategoryRevenueItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return CategoryRevenueData(
      year: json['year'] ?? 2026,
      month: json['month'] ?? 1,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      categories: cats,
    );
  }
}

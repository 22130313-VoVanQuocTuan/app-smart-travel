class TopDestination {
  final int id;
  final String name;
  final int viewCount;
  final String provinceName;

  TopDestination({
    required this.id,
    required this.name,
    required this.viewCount,
    required this.provinceName,
  });

  factory TopDestination.fromJson(Map<String, dynamic> json) {
    return TopDestination(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      provinceName: json['provinceName'] ?? 'N/A',
    );
  }
}

class DashboardStats {
  final int totalUsers;
  final int totalUsersByRoleUSER;
  final int totalUsersByRoleHOST;
  final int totalUsersByRoleADMIN;
  final int totalProvinces;
  final int totalDestinations;
  final int totalHotels;
  final int totalTours;
  final int totalVouchers;
  final int todayInvoices;
  final double todayRevenue;
  final double totalRevenue;
  final List<TopDestination> topDestinations;

  DashboardStats({
    required this.totalUsers,
    this.totalUsersByRoleUSER = 0,
    this.totalUsersByRoleHOST = 0,
    this.totalUsersByRoleADMIN = 0,
    required this.totalProvinces,
    required this.totalDestinations,
    required this.totalHotels,
    required this.totalTours,
    this.totalVouchers = 0,
    this.todayInvoices = 0,
    this.todayRevenue = 0,
    this.totalRevenue = 0,
    required this.topDestinations,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    var topDestList = json['topDestinations'] as List? ?? [];
    List<TopDestination> destinations =
        topDestList
            .map(
              (item) => TopDestination.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalUsersByRoleUSER: json['totalUsersByRoleUSER'] ?? 0,
      totalUsersByRoleHOST: json['totalUsersByRoleHOST'] ?? 0,
      totalUsersByRoleADMIN: json['totalUsersByRoleADMIN'] ?? 0,
      totalProvinces: json['totalProvinces'] ?? 0,
      totalDestinations: json['totalDestinations'] ?? 0,
      totalHotels: json['totalHotels'] ?? 0,
      totalTours: json['totalTours'] ?? 0,
      totalVouchers: json['totalVouchers'] ?? 0,
      todayInvoices: json['todayInvoices'] ?? 0,
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      topDestinations: destinations,
    );
  }

  int get totalEntities =>
      totalProvinces + totalDestinations + totalHotels + totalTours;
}

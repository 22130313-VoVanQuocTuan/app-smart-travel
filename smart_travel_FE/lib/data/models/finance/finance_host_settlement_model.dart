class FinanceHostSettlementModel {
  final int hostId;
  final String hostName;
  final int totalCompletedBookings;
  final int onlineCompletedBookings;
  final int cashCompletedBookings;
  final double totalCompletedRevenue;
  final double onlineCompletedRevenue;
  final double cashCompletedRevenue;
  final double amountPayableToHost;
  final double amountHostMustTransfer;
  final double totalCommission;
  final int homestayCount;

  FinanceHostSettlementModel({
    required this.hostId,
    required this.hostName,
    required this.totalCompletedBookings,
    required this.onlineCompletedBookings,
    required this.cashCompletedBookings,
    required this.totalCompletedRevenue,
    required this.onlineCompletedRevenue,
    required this.cashCompletedRevenue,
    required this.amountPayableToHost,
    required this.amountHostMustTransfer,
    required this.totalCommission,
    required this.homestayCount,
  });

  factory FinanceHostSettlementModel.fromJson(Map<String, dynamic> json) {
    return FinanceHostSettlementModel(
      hostId: json['hostId'] ?? 0,
      hostName: json['hostName'] ?? '',
      totalCompletedBookings: json['totalCompletedBookings'] ?? 0,
      onlineCompletedBookings: json['onlineCompletedBookings'] ?? 0,
      cashCompletedBookings: json['cashCompletedBookings'] ?? 0,
      totalCompletedRevenue: (json['totalCompletedRevenue'] ?? 0).toDouble(),
      onlineCompletedRevenue: (json['onlineCompletedRevenue'] ?? 0).toDouble(),
      cashCompletedRevenue: (json['cashCompletedRevenue'] ?? 0).toDouble(),
      amountPayableToHost: (json['amountPayableToHost'] ?? 0).toDouble(),
      amountHostMustTransfer: (json['amountHostMustTransfer'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      homestayCount: json['homestayCount'] ?? 0,
    );
  }
}

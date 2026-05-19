import 'package:equatable/equatable.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends StatisticsEvent {
  const LoadDashboardStats();
}

class LoadHostDashboardStats extends StatisticsEvent {
  final int hostId;
  const LoadHostDashboardStats(this.hostId);
  @override
  List<Object> get props => [hostId];
}

class LoadSystemRevenue extends StatisticsEvent {
  final String type;
  final int year;
  final int month;

  const LoadSystemRevenue({required this.type, required this.year, required this.month});

  @override
  List<Object?> get props => [type, year, month];
}

class LoadHostRevenue extends StatisticsEvent {
  final int hostId;
  final String type;
  final int year;
  final int month;

  const LoadHostRevenue({required this.hostId, required this.type, required this.year, required this.month});

  @override
  List<Object?> get props => [hostId, type, year, month];
}

class LoadHostRevenueByRange extends StatisticsEvent {
  final int hostId;
  final String startDate;
  final String endDate;

  const LoadHostRevenueByRange({required this.hostId, required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [hostId, startDate, endDate];
}

class LoadHostRevenueByCategory extends StatisticsEvent {
  final int hostId;
  final int year;
  final int month;

  const LoadHostRevenueByCategory({required this.hostId, required this.year, required this.month});

  @override
  List<Object?> get props => [hostId, year, month];
}

import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/data/models/statistics/dashboard_stats.dart';
import 'package:smart_travel/data/models/statistics/revenue_data.dart';
import 'package:smart_travel/data/models/statistics/category_revenue_data.dart';

abstract class StatisticsRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();
  Future<Either<Failure, RevenueData>> getSystemRevenue(String type, int year, int month);
  Future<Either<Failure, RevenueData>> getHostRevenue(int hostId, String type, int year, int month);
  Future<Either<Failure, RevenueData>> getHostRevenueByRange(int hostId, String startDate, String endDate);
  Future<Either<Failure, CategoryRevenueData>> getHostRevenueByCategory(int hostId, int year, int month);
}

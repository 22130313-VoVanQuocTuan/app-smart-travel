import 'package:dio/dio.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/data/models/statistics/dashboard_stats.dart';
import 'package:smart_travel/data/models/statistics/revenue_data.dart';
import 'package:smart_travel/data/models/statistics/category_revenue_data.dart';

abstract class StatisticsRemoteDataSource {
  Future<DashboardStats> getDashboardStats();
  Future<RevenueData> getSystemRevenue(String type, int year, int month);
  Future<RevenueData> getHostRevenue(int hostId, String type, int year, int month);
  Future<RevenueData> getHostRevenueByRange(int hostId, String startDate, String endDate);
  Future<CategoryRevenueData> getHostRevenueByCategory(int hostId, int year, int month);
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  final DioClient dioClient;

  StatisticsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await dioClient.get(ApiConstants.adminStatistics);

      if (response.data == null) {
        throw DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminStatistics),
          message: 'Response data is null',
          type: DioExceptionType.badResponse,
        );
      }

      // Response format: { "msg": "...", "data": { ... } }
      if (response.data['data'] != null) {
        return DashboardStats.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminStatistics),
          message: 'Statistics data is null in response',
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      print('Error in getDashboardStats: $e');
      rethrow;
    }
  }

  @override
  Future<RevenueData> getSystemRevenue(String type, int year, int month) async {
    try {
      final response = await dioClient.get(
        ApiConstants.adminRevenue,
        queryParameters: {'type': type, 'year': year, 'month': month},
      );
      return RevenueData.fromJson(response.data['data']);
    } catch (e) {
      print('Error in getSystemRevenue: $e');
      rethrow;
    }
  }

  @override
  Future<RevenueData> getHostRevenue(int hostId, String type, int year, int month) async {
    try {
      final response = await dioClient.get(
        ApiConstants.hostRevenue,
        queryParameters: {'hostId': hostId, 'type': type, 'year': year, 'month': month},
      );
      return RevenueData.fromJson(response.data['data']);
    } catch (e) {
      print('Error in getHostRevenue: $e');
      rethrow;
    }
  }

  @override
  Future<RevenueData> getHostRevenueByRange(int hostId, String startDate, String endDate) async {
    try {
      final response = await dioClient.get(
        ApiConstants.hostRevenueByRange,
        queryParameters: {'hostId': hostId, 'startDate': startDate, 'endDate': endDate},
      );
      return RevenueData.fromJson(response.data['data']);
    } catch (e) {
      print('Error in getHostRevenueByRange: $e');
      rethrow;
    }
  }

  @override
  Future<CategoryRevenueData> getHostRevenueByCategory(int hostId, int year, int month) async {
    try {
      final response = await dioClient.get(
        ApiConstants.hostRevenueByCategory,
        queryParameters: {'hostId': hostId, 'year': year, 'month': month},
      );
      return CategoryRevenueData.fromJson(response.data['data']);
    } catch (e) {
      print('Error in getHostRevenueByCategory: $e');
      rethrow;
    }
  }
}

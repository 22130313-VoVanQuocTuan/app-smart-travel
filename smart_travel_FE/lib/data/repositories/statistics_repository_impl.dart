import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/data/data_sources/remote/statistics_data_source.dart';
import 'package:smart_travel/data/models/statistics/dashboard_stats.dart';
import 'package:smart_travel/data/models/statistics/revenue_data.dart';
import 'package:smart_travel/data/models/statistics/category_revenue_data.dart';
import 'package:smart_travel/domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource remoteDataSource;

  StatisticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DashboardStats>> getHostDashboardStats(int hostId) async {
    try {
      final stats = await remoteDataSource.getHostDashboardStats(hostId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    try {
      final stats = await remoteDataSource.getDashboardStats();
      return Right(stats);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RevenueData>> getSystemRevenue(String type, int year, int month) async {
    try {
      final data = await remoteDataSource.getSystemRevenue(type, year, month);
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RevenueData>> getHostRevenue(int hostId, String type, int year, int month) async {
    try {
      final data = await remoteDataSource.getHostRevenue(hostId, type, year, month);
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RevenueData>> getHostRevenueByRange(int hostId, String startDate, String endDate) async {
    try {
      final data = await remoteDataSource.getHostRevenueByRange(hostId, startDate, endDate);
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CategoryRevenueData>> getHostRevenueByCategory(int hostId, int year, int month) async {
    try {
      final data = await remoteDataSource.getHostRevenueByCategory(hostId, year, month);
      return Right(data);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lỗi server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/network/network_info.dart';
import 'package:smart_travel/data/data_sources/remote/host_booking_data_source.dart';
import 'package:smart_travel/data/models/booking/host_booking_list_model.dart';
import 'package:smart_travel/domain/repositories/host_booking_repository.dart';

class HostBookingRepositoryImpl implements HostBookingRepository {
  final HostBookingDataSource hostBookingDataSource;
  final NetworkInfo networkInfo;

  HostBookingRepositoryImpl({
    required this.hostBookingDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<HostBookingListModel>>> getHostBookings() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await hostBookingDataSource.getHostBookings();
        return Right(response);
      } on DioException catch (e) {
        if (e.error is ServerException) {
          final serverException = e.error as ServerException;
          return Left(ServerFailure(serverException.message));
        } else {
          return Left(ServerFailure('Lỗi Dio không xác định: ${e.message}'));
        }
      } catch (e) {
        return Left(ServerFailure('Lỗi không mong muốn: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('Không có kết nối mạng'));
    }
  }

  @override
  Future<Either<Failure, HostBookingListModel>> getHostBookingDetail(int bookingId) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await hostBookingDataSource.getHostBookingDetail(bookingId);
        return Right(response);
      } on DioException catch (e) {
        if (e.error is ServerException) {
          final serverException = e.error as ServerException;
          return Left(ServerFailure(serverException.message));
        } else {
          return Left(ServerFailure('Lỗi Dio không xác định: ${e.message}'));
        }
      } catch (e) {
        return Left(ServerFailure('Lỗi không mong muốn: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('Không có kết nối mạng'));
    }
  }

  @override
  Future<Either<Failure, List<HostBookingListModel>>> getHostBookingsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await hostBookingDataSource.getHostBookingsByDateRange(
          startDate,
          endDate,
          status: status,
        );
        return Right(response);
      } on DioException catch (e) {
        if (e.error is ServerException) {
          final serverException = e.error as ServerException;
          return Left(ServerFailure(serverException.message));
        } else {
          return Left(ServerFailure('Lỗi Dio không xác định: ${e.message}'));
        }
      } catch (e) {
        return Left(ServerFailure('Lỗi không mong muốn: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('Không có kết nối mạng'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(
    int bookingId,
    String newStatus, {
    String? cancellationReason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await hostBookingDataSource.updateBookingStatus(
          bookingId,
          newStatus,
          cancellationReason: cancellationReason,
        );
        return const Right(null);
      } on DioException catch (e) {
        if (e.error is ServerException) {
          final serverException = e.error as ServerException;
          return Left(ServerFailure(serverException.message));
        } else {
          return Left(ServerFailure('Lỗi Dio không xác định: ${e.message}'));
        }
      } catch (e) {
        return Left(ServerFailure('Lỗi không mong muốn: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('Không có kết nối mạng'));
    }
  }
}


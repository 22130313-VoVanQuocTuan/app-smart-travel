import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/network/network_info.dart';
import 'package:smart_travel/data/data_sources/remote/host_approval_data_source.dart';
import 'package:smart_travel/data/models/admin/host_approval_response_model.dart';
import 'package:smart_travel/domain/repositories/host_approval_repository.dart';

class HostApprovalRepositoryImpl implements HostApprovalRepository {
  final HostApprovalDataSource dataSource;
  final NetworkInfo networkInfo;

  HostApprovalRepositoryImpl({required this.dataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<HostApprovalResponseModel>>> getPendingHosts({int page = 0, int size = 10}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Không có kết nối internet'));
    }
    try {
      final result = await dataSource.getPendingHosts(page: page, size: size);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveHost(int userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Không có kết nối internet'));
    }
    try {
      await dataSource.approveHost(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectHost(int userId, String reason) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Không có kết nối internet'));
    }
    try {
      await dataSource.rejectHost(userId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}


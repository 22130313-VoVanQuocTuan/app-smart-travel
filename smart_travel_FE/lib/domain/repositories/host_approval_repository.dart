import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/data/models/admin/host_approval_response_model.dart';

abstract class HostApprovalRepository {
  Future<Either<Failure, List<HostApprovalResponseModel>>> getPendingHosts({int page, int size});
  Future<Either<Failure, void>> approveHost(int userId);
  Future<Either<Failure, void>> rejectHost(int userId, String reason);
}


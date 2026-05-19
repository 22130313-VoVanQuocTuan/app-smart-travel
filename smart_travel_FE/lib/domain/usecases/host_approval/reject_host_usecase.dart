import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/domain/repositories/host_approval_repository.dart';

class RejectHostUseCase implements UseCase<void, RejectHostParams> {
  final HostApprovalRepository repository;

  RejectHostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectHostParams params) {
    return repository.rejectHost(params.userId, params.reason);
  }
}

class RejectHostParams {
  final int userId;
  final String reason;

  const RejectHostParams({required this.userId, required this.reason});
}


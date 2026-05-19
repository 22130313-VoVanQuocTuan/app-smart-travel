import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/domain/repositories/host_approval_repository.dart';

class ApproveHostUseCase implements UseCase<void, int> {
  final HostApprovalRepository repository;

  ApproveHostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int params) {
    return repository.approveHost(params);
  }
}


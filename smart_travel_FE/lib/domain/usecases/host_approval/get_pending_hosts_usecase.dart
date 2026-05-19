import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/data/models/admin/host_approval_response_model.dart';
import 'package:smart_travel/domain/repositories/host_approval_repository.dart';

class GetPendingHostsUseCase implements UseCase<List<HostApprovalResponseModel>, PendingHostsParams> {
  final HostApprovalRepository repository;

  GetPendingHostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HostApprovalResponseModel>>> call(PendingHostsParams params) {
    return repository.getPendingHosts(page: params.page, size: params.size);
  }
}

class PendingHostsParams {
  final int page;
  final int size;

  const PendingHostsParams({this.page = 0, this.size = 10});
}


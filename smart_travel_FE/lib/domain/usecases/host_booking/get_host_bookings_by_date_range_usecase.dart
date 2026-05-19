import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/data/models/booking/host_booking_list_model.dart';
import 'package:smart_travel/domain/repositories/host_booking_repository.dart';

class GetHostBookingsByDateRangeUseCase
    implements UseCase<List<HostBookingListModel>, GetHostBookingsByDateRangeParams> {
  final HostBookingRepository repository;

  GetHostBookingsByDateRangeUseCase(this.repository);

  @override
  Future<Either<Failure, List<HostBookingListModel>>> call(
      GetHostBookingsByDateRangeParams params) {
    return repository.getHostBookingsByDateRange(
      params.startDate,
      params.endDate,
      status: params.status,
    );
  }
}

class GetHostBookingsByDateRangeParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? status;

  const GetHostBookingsByDateRangeParams({
    required this.startDate,
    required this.endDate,
    this.status,
  });
}


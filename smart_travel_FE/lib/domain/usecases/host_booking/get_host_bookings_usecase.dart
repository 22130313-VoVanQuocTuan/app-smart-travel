import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/data/models/booking/host_booking_list_model.dart';
import 'package:smart_travel/domain/repositories/host_booking_repository.dart';

class GetHostBookingsUseCase implements UseCase<List<HostBookingListModel>, NoParams> {
  final HostBookingRepository repository;

  GetHostBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HostBookingListModel>>> call(NoParams params) {
    return repository.getHostBookings();
  }
}


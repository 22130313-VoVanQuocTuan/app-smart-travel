import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/domain/repositories/host_booking_repository.dart';

class UpdateBookingStatusUseCase implements UseCase<void, UpdateBookingStatusParams> {
  final HostBookingRepository repository;

  UpdateBookingStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBookingStatusParams params) {
    return repository.updateBookingStatus(
      params.bookingId,
      params.newStatus,
      cancellationReason: params.cancellationReason,
    );
  }
}

class UpdateBookingStatusParams {
  final int bookingId;
  final String newStatus;
  final String? cancellationReason;

  const UpdateBookingStatusParams({
    required this.bookingId,
    required this.newStatus,
    this.cancellationReason,
  });
}


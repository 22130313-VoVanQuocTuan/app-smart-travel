import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/data/models/booking/host_booking_list_model.dart';

abstract class HostBookingRepository {
  Future<Either<Failure, List<HostBookingListModel>>> getHostBookings();
  Future<Either<Failure, HostBookingListModel>> getHostBookingDetail(int bookingId);
  Future<Either<Failure, List<HostBookingListModel>>> getHostBookingsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  });
  Future<Either<Failure, void>> updateBookingStatus(
    int bookingId,
    String newStatus, {
    String? cancellationReason,
  });
}


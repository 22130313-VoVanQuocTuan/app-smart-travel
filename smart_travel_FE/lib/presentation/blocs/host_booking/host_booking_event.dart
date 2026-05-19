import 'package:equatable/equatable.dart';

abstract class HostBookingEvent extends Equatable {
  const HostBookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadHostBookingsEvent extends HostBookingEvent {
  const LoadHostBookingsEvent();
}

class RefreshHostBookingsEvent extends HostBookingEvent {
  const RefreshHostBookingsEvent();
}

class FilterBookingsByStatusEvent extends HostBookingEvent {
  final String status;
  const FilterBookingsByStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class FilterBookingsByDateRangeEvent extends HostBookingEvent {
  final DateTime startDate;
  final DateTime endDate;
  const FilterBookingsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class UpdateBookingStatusEvent extends HostBookingEvent {
  final int bookingId;
  final String status;
  final String? cancellationReason;

  const UpdateBookingStatusEvent({
    required this.bookingId,
    required this.status,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [bookingId, status, cancellationReason];
}

class LoadBookingDetailEvent extends HostBookingEvent {
  final int bookingId;
  const LoadBookingDetailEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}
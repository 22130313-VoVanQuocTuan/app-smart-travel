import 'package:equatable/equatable.dart';

abstract class HostBookingEvent extends Equatable {
  const HostBookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadHostBookingsEvent extends HostBookingEvent {
  const LoadHostBookingsEvent();
}

class LoadHostBookingsByDateRangeEvent extends HostBookingEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? status;

  const LoadHostBookingsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
    this.status,
  });

  @override
  List<Object?> get props => [startDate, endDate, status];
}

class LoadHostBookingDetailEvent extends HostBookingEvent {
  final int bookingId;

  const LoadHostBookingDetailEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class UpdateBookingStatusEvent extends HostBookingEvent {
  final int bookingId;
  final String newStatus;
  final String? cancellationReason;

  const UpdateBookingStatusEvent({
    required this.bookingId,
    required this.newStatus,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [bookingId, newStatus, cancellationReason];
}

class FilterBookingsByStatusEvent extends HostBookingEvent {
  final String status;

  const FilterBookingsByStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class RefreshHostBookingsEvent extends HostBookingEvent {
  const RefreshHostBookingsEvent();
}


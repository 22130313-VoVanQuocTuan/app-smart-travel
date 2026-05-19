import 'package:equatable/equatable.dart';
import 'package:smart_travel/data/models/booking/host_booking_list_model.dart';

abstract class HostBookingState extends Equatable {
  const HostBookingState();

  @override
  List<Object?> get props => [];
}

class HostBookingInitial extends HostBookingState {}

class HostBookingLoading extends HostBookingState {}

class HostBookingLoaded extends HostBookingState {
  final List<HostBookingListModel> bookings;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? statusFilter;

  const HostBookingLoaded({
    required this.bookings,
    this.startDate,
    this.endDate,
    this.statusFilter,
  });

  HostBookingLoaded copyWith({
    List<HostBookingListModel>? bookings,
    DateTime? startDate,
    DateTime? endDate,
    String? statusFilter,
  }) {
    return HostBookingLoaded(
      bookings: bookings ?? this.bookings,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [bookings, startDate, endDate, statusFilter];
}

class HostBookingDetailLoading extends HostBookingState {}

class HostBookingDetailLoaded extends HostBookingState {
  final HostBookingListModel booking;

  const HostBookingDetailLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class HostBookingStatusUpdating extends HostBookingState {
  final int bookingId;

  const HostBookingStatusUpdating(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class HostBookingStatusUpdated extends HostBookingState {
  final int bookingId;
  final String newStatus;

  const HostBookingStatusUpdated(this.bookingId, this.newStatus);

  @override
  List<Object?> get props => [bookingId, newStatus];
}

class HostBookingError extends HostBookingState {
  final String message;

  const HostBookingError(this.message);

  @override
  List<Object?> get props => [message];
}


// lib/presentation/blocs/host_booking/host_booking_state.dart
import 'package:equatable/equatable.dart';
import 'package:smart_travel/data/models/booking/booking_model.dart';

abstract class HostBookingState extends Equatable {
  const HostBookingState();

  @override
  List<Object?> get props => [];
}

class HostBookingInitial extends HostBookingState {}

class HostBookingLoading extends HostBookingState {}

class HostBookingLoaded extends HostBookingState {
  final List<HostBooking> bookings;
  final List<HostBooking> filteredBookings;
  final String? activeFilter;

  const HostBookingLoaded({
    required this.bookings,
    required this.filteredBookings,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [bookings, filteredBookings, activeFilter];
}

class HostBookingDetailLoaded extends HostBookingState {
  final BookingDetail bookingDetail;

  const HostBookingDetailLoaded(this.bookingDetail);

  @override
  List<Object?> get props => [bookingDetail];
}

class HostBookingError extends HostBookingState {
  final String message;

  const HostBookingError(this.message);

  @override
  List<Object?> get props => [message];
}

class HostBookingStatusUpdating extends HostBookingState {}

class HostBookingStatusUpdated extends HostBookingState {
  final String message;

  const HostBookingStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}
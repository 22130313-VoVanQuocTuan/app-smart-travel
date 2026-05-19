// lib/presentation/blocs/user_booking/user_booking_state.dart
import 'package:equatable/equatable.dart';
import 'package:smart_travel/data/models/booking/cancellation_policy_response.dart';
import 'package:smart_travel/data/models/user/user_booking_model.dart';

abstract class UserBookingState extends Equatable {
  const UserBookingState();

  @override
  List<Object?> get props => [];
}

class UserBookingInitial extends UserBookingState {}

class UserBookingLoading extends UserBookingState {}

class UserBookingLoaded extends UserBookingState {
  final List<UserBooking> currentBookings;
  final List<UserBooking> bookingHistory;

  const UserBookingLoaded({
    required this.currentBookings,
    required this.bookingHistory,
  });

  @override
  List<Object?> get props => [currentBookings, bookingHistory];
}

class UserBookingDetailLoaded extends UserBookingState {
  final UserBooking booking;

  const UserBookingDetailLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class UserBookingQRFound extends UserBookingState {
  final UserBooking booking;

  const UserBookingQRFound(this.booking);

  @override
  List<Object?> get props => [booking];
}

class UserBookingOperationSuccess extends UserBookingState {
  final String message;

  const UserBookingOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserBookingError extends UserBookingState {
  final String message;

  const UserBookingError(this.message);

  @override
  List<Object?> get props => [message];
}
class CancellationPolicyLoading extends UserBookingState {
  const CancellationPolicyLoading();
}

class CancellationPolicyLoaded extends UserBookingState {
  final CancellationPolicyResponse policy;
  const CancellationPolicyLoaded(this.policy);

  @override
  List<Object?> get props => [policy];
}
class BookingCancelling extends UserBookingState {
  const BookingCancelling();
}

class BookingCancelled extends UserBookingState {
  final String message;
  const BookingCancelled(this.message);

  @override
  List<Object?> get props => [message];
}

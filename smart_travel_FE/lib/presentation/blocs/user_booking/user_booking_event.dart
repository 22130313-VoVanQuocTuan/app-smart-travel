// lib/presentation/blocs/user_booking/user_booking_event.dart
import 'package:equatable/equatable.dart';

abstract class UserBookingEvent extends Equatable {
  const UserBookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserBookingsEvent extends UserBookingEvent {
  const LoadUserBookingsEvent();
}

class LoadCurrentBookingsEvent extends UserBookingEvent {
  const LoadCurrentBookingsEvent();
}

class LoadBookingHistoryEvent extends UserBookingEvent {
  const LoadBookingHistoryEvent();
}

class CancelUserBookingEvent extends UserBookingEvent {
  final int bookingId;
  final String reason;

  const CancelUserBookingEvent({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}

class FindBookingByQREvent extends UserBookingEvent {
  final String qrData;

  const FindBookingByQREvent(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

class RefreshUserBookingsEvent extends UserBookingEvent {
  const RefreshUserBookingsEvent();
}

class GetCancellationPolicyEvent extends UserBookingEvent {
  final int bookingId;
  const GetCancellationPolicyEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class CancelUserBookingWithReasonEvent extends UserBookingEvent {
  final int bookingId;
  final String reason;
  const CancelUserBookingWithReasonEvent({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}
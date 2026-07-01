// lib/presentation/blocs/user_booking/user_booking_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_event.dart';
import 'package:smart_travel/presentation/blocs/user_booking/user_booking_state.dart';
import 'package:smart_travel/service/user_booking_service.dart';

class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
  final UserBookingService bookingService;

  UserBookingBloc({required this.bookingService}) : super(UserBookingInitial()) {
    on<LoadUserBookingsEvent>(_onLoadUserBookings);
    on<LoadCurrentBookingsEvent>(_onLoadCurrentBookings);
    on<LoadBookingHistoryEvent>(_onLoadBookingHistory);
    on<CancelUserBookingEvent>(_onCancelBooking);
    on<GetCancellationPolicyEvent>(_onGetCancellationPolicy);
    on<CancelUserBookingWithReasonEvent>(_onCancelBookingWithReason);
    on<FindBookingByQREvent>(_onFindBookingByQR);
    on<RefreshUserBookingsEvent>(_onRefreshUserBookings);
  }

  Future<void> _onLoadUserBookings(
      LoadUserBookingsEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    emit(UserBookingLoading());
    try {
      emit(await _loadBookingsState());
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<void> _onLoadCurrentBookings(
      LoadCurrentBookingsEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    emit(UserBookingLoading());
    try {
      emit(await _loadBookingsState());
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<void> _onLoadBookingHistory(
      LoadBookingHistoryEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    emit(UserBookingLoading());
    try {
      emit(await _loadBookingsState());
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
      CancelUserBookingEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    try {
      await bookingService.cancelBooking(event.bookingId, event.reason);
      emit(const UserBookingOperationSuccess('Hủy booking thành công'));
      add(const RefreshUserBookingsEvent());
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<void> _onFindBookingByQR(
      FindBookingByQREvent event,
      Emitter<UserBookingState> emit,
      ) async {
    emit(UserBookingLoading());
    try {
      final booking = await bookingService.findBookingByQR(event.qrData);
      if (booking != null) {
        emit(UserBookingQRFound(booking));
      } else {
        emit(const UserBookingError('Không tìm thấy booking'));
      }
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<void> _onRefreshUserBookings(
      RefreshUserBookingsEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    if (state is UserBookingLoaded) {
      try {
        emit(await _loadBookingsState());
      } catch (e) {
        emit(UserBookingError(e.toString()));
      }
    } else {
      add(const LoadUserBookingsEvent());
    }
  }
  Future<void> _onGetCancellationPolicy(
      GetCancellationPolicyEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    emit(const CancellationPolicyLoading());
    try {
      final policy = await bookingService.getCancellationPolicy(event.bookingId);
      emit(CancellationPolicyLoaded(policy));
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<void> _onCancelBookingWithReason(
      CancelUserBookingWithReasonEvent event,
      Emitter<UserBookingState> emit,
      ) async {
    emit(const BookingCancelling());
    try {
      await bookingService.cancelBooking(event.bookingId, event.reason);
      emit(const BookingCancelled('Hủy booking thành công'));
      add(const RefreshUserBookingsEvent());
    } catch (e) {
      emit(UserBookingError(e.toString()));
    }
  }

  Future<UserBookingLoaded> _loadBookingsState() async {
    final bookings = await bookingService.getUserBookings();
    final current =
        bookings.where((booking) => booking.isCurrentBooking).toList();
    final history =
        bookings.where((booking) => booking.isHistoryBooking).toList();

    return UserBookingLoaded(
      currentBookings: current,
      bookingHistory: history,
    );
  }
}

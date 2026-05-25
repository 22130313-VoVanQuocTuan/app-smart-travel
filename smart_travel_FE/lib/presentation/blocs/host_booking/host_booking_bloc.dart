// lib/presentation/blocs/host_booking/host_booking_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/data/models/booking/booking_model.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_event.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_state.dart';
import 'package:smart_travel/service/booking_service.dart';

class HostBookingBloc extends Bloc<HostBookingEvent, HostBookingState> {
  final BookingService bookingService;

  HostBookingBloc({required this.bookingService}) : super(HostBookingInitial()) {
    on<LoadHostBookingsEvent>(_onLoadHostBookings);
    on<RefreshHostBookingsEvent>(_onRefreshHostBookings);
    on<FilterBookingsByStatusEvent>(_onFilterByStatus);
    on<FilterBookingsByDateRangeEvent>(_onFilterByDateRange);
    on<UpdateBookingStatusEvent>(_onUpdateBookingStatus);
    on<LoadBookingDetailEvent>(_onLoadBookingDetail);
  }

  List<HostBooking> allBookings = [];

  Future<void> _onLoadHostBookings(
      LoadHostBookingsEvent event,
      Emitter<HostBookingState> emit,
      ) async {
    // Only emit loading if we don't already have data
    if (allBookings.isEmpty) {
      emit(HostBookingLoading());
    }
    try {
      final bookings = await bookingService.getHostBookings();
      allBookings = bookings;
      emit(HostBookingLoaded(
        bookings: bookings,
        filteredBookings: bookings,
        activeFilter: null,
      ));
    } catch (e) {
      emit(HostBookingError(e.toString()));
    }
  }

  Future<void> _onRefreshHostBookings(
      RefreshHostBookingsEvent event,
      Emitter<HostBookingState> emit,
      ) async {
    try {
      final bookings = await bookingService.getHostBookings();
      allBookings = bookings;

      if (state is HostBookingLoaded) {
        final currentState = state as HostBookingLoaded;
        emit(HostBookingLoaded(
          bookings: bookings,
          filteredBookings: currentState.activeFilter != null
              ? bookings.where((b) => b.status == currentState.activeFilter).toList()
              : bookings,
          activeFilter: currentState.activeFilter,
        ));
      } else {
        emit(HostBookingLoaded(
          bookings: bookings,
          filteredBookings: bookings,
          activeFilter: null,
        ));
      }
    } catch (e) {
      emit(HostBookingError(e.toString()));
    }
  }

  void _onFilterByStatus(
      FilterBookingsByStatusEvent event,
      Emitter<HostBookingState> emit,
      ) {
    // Handle case when state might not be HostBookingLoaded (e.g., after viewing detail)
    late List<HostBooking> bookings;
    
    if (state is HostBookingLoaded) {
      final currentState = state as HostBookingLoaded;
      bookings = currentState.bookings;
    } else {
      // If state is not loaded, use all bookings from memory
      bookings = allBookings;
    }

    final filtered = event.status == 'ALL'
        ? bookings
        : bookings.where((b) => b.status == event.status).toList();

    emit(HostBookingLoaded(
      bookings: bookings,
      filteredBookings: filtered,
      activeFilter: event.status == 'ALL' ? null : event.status,
    ));
  }

  void _onFilterByDateRange(
      FilterBookingsByDateRangeEvent event,
      Emitter<HostBookingState> emit,
      ) {
    // Handle case when state might not be HostBookingLoaded
    late List<HostBooking> bookings;
    
    if (state is HostBookingLoaded) {
      final currentState = state as HostBookingLoaded;
      bookings = currentState.bookings;
    } else {
      // If state is not loaded, use all bookings from memory
      bookings = allBookings;
    }

    final filtered = bookings.where((b) {
      return (b.startDate.isAfter(event.startDate) || b.startDate.isAtSameMomentAs(event.startDate)) &&
          (b.endDate.isBefore(event.endDate) || b.endDate.isAtSameMomentAs(event.endDate));
    }).toList();

    emit(HostBookingLoaded(
      bookings: bookings,
      filteredBookings: filtered,
      activeFilter: null,
    ));
  }

  Future<void> _onUpdateBookingStatus(
      UpdateBookingStatusEvent event,
      Emitter<HostBookingState> emit,
      ) async {
    emit(HostBookingStatusUpdating());
    try {
      await bookingService.updateBookingStatus(
        bookingId: event.bookingId,
        status: event.status,
        cancellationReason: event.cancellationReason,
      );

      // Refresh lại danh sách
      add(const RefreshHostBookingsEvent());
      emit(HostBookingStatusUpdated('Cập nhật trạng thái thành công'));

      // Reset state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          add(const LoadHostBookingsEvent());
        }
      });
    } catch (e) {
      emit(HostBookingError(e.toString()));
    }
  }

  Future<void> _onLoadBookingDetail(
      LoadBookingDetailEvent event,
      Emitter<HostBookingState> emit,
      ) async {
    emit(HostBookingLoading());
    try {
      final detail = await bookingService.getBookingDetail(event.bookingId);
      emit(HostBookingDetailLoaded(detail));
    } catch (e) {
      emit(HostBookingError(e.toString()));
    }
  }
}
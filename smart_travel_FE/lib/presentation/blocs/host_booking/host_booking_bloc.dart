import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/domain/usecases/host_booking/get_host_bookings_usecase.dart';
import 'package:smart_travel/domain/usecases/host_booking/get_host_bookings_by_date_range_usecase.dart';
import 'package:smart_travel/domain/usecases/host_booking/update_booking_status_usecase.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_event.dart';
import 'package:smart_travel/presentation/blocs/host_booking/host_booking_state.dart';

class HostBookingBloc extends Bloc<HostBookingEvent, HostBookingState> {
  final GetHostBookingsUseCase getHostBookingsUseCase;
  final GetHostBookingsByDateRangeUseCase getHostBookingsByDateRangeUseCase;
  final UpdateBookingStatusUseCase updateBookingStatusUseCase;

  String? currentStatusFilter;

  HostBookingBloc({
    required this.getHostBookingsUseCase,
    required this.getHostBookingsByDateRangeUseCase,
    required this.updateBookingStatusUseCase,
  }) : super(HostBookingInitial()) {
    on<LoadHostBookingsEvent>(_onLoadHostBookings);
    on<LoadHostBookingsByDateRangeEvent>(_onLoadHostBookingsByDateRange);
    on<UpdateBookingStatusEvent>(_onUpdateBookingStatus);
    on<FilterBookingsByStatusEvent>(_onFilterBookingsByStatus);
    on<RefreshHostBookingsEvent>(_onRefreshHostBookings);
  }

  Future<void> _onLoadHostBookings(
    LoadHostBookingsEvent event,
    Emitter<HostBookingState> emit,
  ) async {
    emit(HostBookingLoading());
    
    final result = await getHostBookingsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(HostBookingError(failure.toString())),
      (bookings) {
        final filtered = currentStatusFilter != null
            ? bookings.where((b) => b.status == currentStatusFilter).toList()
            : bookings;
        emit(HostBookingLoaded(bookings: filtered));
      },
    );
  }

  Future<void> _onLoadHostBookingsByDateRange(
    LoadHostBookingsByDateRangeEvent event,
    Emitter<HostBookingState> emit,
  ) async {
    emit(HostBookingLoading());
    
    final result = await getHostBookingsByDateRangeUseCase(
      GetHostBookingsByDateRangeParams(
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
      ),
    );
    
    result.fold(
      (failure) => emit(HostBookingError(failure.toString())),
      (bookings) {
        emit(HostBookingLoaded(
          bookings: bookings,
          startDate: event.startDate,
          endDate: event.endDate,
          statusFilter: event.status,
        ));
      },
    );
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatusEvent event,
    Emitter<HostBookingState> emit,
  ) async {
    emit(HostBookingStatusUpdating(event.bookingId));
    
    final result = await updateBookingStatusUseCase(
      UpdateBookingStatusParams(
        bookingId: event.bookingId,
        newStatus: event.newStatus,
        cancellationReason: event.cancellationReason,
      ),
    );
    
    result.fold(
      (failure) => emit(HostBookingError(failure.toString())),
      (_) {
        emit(HostBookingStatusUpdated(event.bookingId, event.newStatus));
        // Refresh list sau khi update
        add(const RefreshHostBookingsEvent());
      },
    );
  }

  Future<void> _onFilterBookingsByStatus(
    FilterBookingsByStatusEvent event,
    Emitter<HostBookingState> emit,
  ) async {
    currentStatusFilter = event.status;
    
    if (state is HostBookingLoaded) {
      final currentState = state as HostBookingLoaded;
      final filtered = currentState.bookings
          .where((b) => b.status == event.status)
          .toList();
      
      emit(currentState.copyWith(
        bookings: filtered,
        statusFilter: event.status,
      ));
    }
  }

  Future<void> _onRefreshHostBookings(
    RefreshHostBookingsEvent event,
    Emitter<HostBookingState> emit,
  ) async {
    add(const LoadHostBookingsEvent());
  }
}


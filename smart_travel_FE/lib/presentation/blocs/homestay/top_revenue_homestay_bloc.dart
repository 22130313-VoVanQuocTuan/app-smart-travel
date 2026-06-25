// lib/presentation/blocs/homestay/top_revenue_homestay_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_state.dart';
import 'package:smart_travel/service/homestay_service.dart';

class TopRevenueHomestayBloc extends Bloc<HomestayEvent, HomestayState> {
  final HomestayService homestayService;

  TopRevenueHomestayBloc({required this.homestayService}) : super(HomestayInitial()) {
    on<LoadTopRevenueHomestaysEvent>(_onLoadTopRevenueHomestays);
  }

  Future<void> _onLoadTopRevenueHomestays(
    LoadTopRevenueHomestaysEvent event,
    Emitter<HomestayState> emit,
  ) async {
    emit(TopRevenueHomestaysLoading());
    try {
      final homestays = await homestayService.getTopRevenueHomestays(limit: event.limit);
      emit(TopRevenueHomestaysLoaded(homestays: homestays));
    } catch (e) {
      emit(TopRevenueHomestaysError(e.toString()));
    }
  }
}

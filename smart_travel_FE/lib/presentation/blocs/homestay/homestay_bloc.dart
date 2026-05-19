// lib/presentation/blocs/homestay/homestay_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_state.dart';
import 'package:smart_travel/service/homestay_service.dart';



class HomestayBloc extends Bloc<HomestayEvent, HomestayState> {
  final HomestayService homestayService;

  HomestayBloc({required this.homestayService}) : super(HomestayInitial()) {
    on<LoadHomestaysEvent>(_onLoadHomestays);
  }

  Future<void> _onLoadHomestays(LoadHomestaysEvent event, Emitter<HomestayState> emit) async {
    emit(HomestayLoading());
    try {
      final result = await homestayService.getHomestays(
        keyword: event.keyword,
        destinationId: event.destinationId,
        minStars: event.minStars,
        maxStars: event.maxStars,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        city: event.city,
        page: event.page,
        size: event.size,
        sortBy: event.sortBy,
        sortDir: event.sortDir,
      );

      emit(HomestayLoaded(
        homestays: result['content'],
        currentPage: result['currentPage'],
        totalPages: result['totalPages'],
        totalElements: result['totalElements'],
      ));
    } catch (e) {
      emit(HomestayError(e.toString()));
    }
  }
}
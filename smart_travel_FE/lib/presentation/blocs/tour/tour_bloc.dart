// lib/presentation/blocs/tour/tour_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/tour/tour_event.dart';
import 'package:smart_travel/presentation/blocs/tour/tour_state.dart';
import 'package:smart_travel/service/tour_service.dart';

class TourBloc extends Bloc<TourEvent, TourState> {
  final TourService tourService;

  TourBloc({required this.tourService}) : super(TourInitial()) {
    on<LoadToursEvent>(_onLoadTours);
    on<CreateTourEvent>(_onCreateTour);
    on<UpdateTourEvent>(_onUpdateTour);
    on<DeleteTourEvent>(_onDeleteTour);
  }

  Future<void> _onLoadTours(LoadToursEvent event, Emitter<TourState> emit) async {
    emit(TourLoading());
    try {
      final tours = await tourService.getToursByHomestay(event.homestayId);
      emit(TourLoaded(tours));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onCreateTour(CreateTourEvent event, Emitter<TourState> emit) async {
    try {
      await tourService.createTour(event.formData);
      emit(TourSuccess('Tạo tour thành công'));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onUpdateTour(UpdateTourEvent event, Emitter<TourState> emit) async {
    try {
      await tourService.updateTour(event.id, event.formData);
      emit(TourSuccess('Cập nhật tour thành công'));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onDeleteTour(DeleteTourEvent event, Emitter<TourState> emit) async {
    try {
      await tourService.deleteTour(event.id);
      emit(TourSuccess('Xóa tour thành công'));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }
}
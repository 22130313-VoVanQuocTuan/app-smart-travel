// lib/presentation/blocs/homestay/homestay_detail_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_detail_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_detail_state.dart';
import 'package:smart_travel/service/homestay_service.dart';

class HomestayDetailBloc extends Bloc<HomestayDetailEvent, HomestayDetailState> {
  final HomestayService homestayService;

  HomestayDetailBloc({required this.homestayService}) : super(HomestayDetailInitial()) {
    on<GetHomestayDetailEvent>(_onGetHomestayDetail);
  }

  Future<void> _onGetHomestayDetail(GetHomestayDetailEvent event, Emitter<HomestayDetailState> emit) async {
    emit(HomestayDetailLoading());
    try {
      final homestay = await homestayService.getHomestayDetail(
        event.homestayId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
      );
      emit(HomestayDetailLoaded(homestay));
    } catch (e) {
      emit(HomestayDetailError(e.toString()));
    }
  }
}
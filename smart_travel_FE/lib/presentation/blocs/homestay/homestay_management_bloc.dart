// lib/presentation/blocs/homestay/homestay_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_management_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_management_state.dart';
import 'package:smart_travel/service/homestay_service.dart';


class HomestayManagementBloc extends Bloc<HomestayManagementEvent, HomestayManagementState> {
  final HomestayService homestayService;

  HomestayManagementBloc({required this.homestayService}) : super(HomestayManagementInitial()) {
    on<LoadMyHomestaysEvent>(_onLoadMyHomestays);
    on<CreateHomestayEvent>(_onCreateHomestay);
    on<UpdateHomestayEvent>(_onUpdateHomestay);
    on<DeleteHomestayEvent>(_onDeleteHomestay);
  }

  Future<void> _onLoadMyHomestays(LoadMyHomestaysEvent event, Emitter<HomestayManagementState> emit) async {
    emit(HomestayManagementLoading());
    try {
      final result = await homestayService.getMyHomestays(
        keyword: event.keyword,
        page: event.page,
        sortBy: event.sortBy,
        sortDir: event.sortDir,
      );

      emit(HomestayManagementLoaded(
        homestays: result['content'],
        currentPage: result['currentPage'],
        totalPages: result['totalPages'],
        totalElements: result['totalElements'],
      ));
    } catch (e) {
      emit(HomestayManagementError(e.toString()));
    }
  }

  Future<void> _onCreateHomestay(CreateHomestayEvent event, Emitter<HomestayManagementState> emit) async {
    emit(HomestayManagementLoading());
    try {
      await homestayService.createHomestayWithFiles(event.request);
      emit(HomestayManagementSuccess('Tạo homestay thành công'));
      add(LoadMyHomestaysEvent());
    } catch (e) {
      emit(HomestayManagementError(e.toString()));
    }
  }

  Future<void> _onUpdateHomestay(UpdateHomestayEvent event, Emitter<HomestayManagementState> emit) async {
    emit(HomestayManagementLoading());
    try {
      await homestayService.updateHomestayWithFiles(event.id, event.formData);
      emit(HomestayManagementSuccess('Cập nhật homestay thành công'));
      add(LoadMyHomestaysEvent());
    } catch (e) {
      emit(HomestayManagementError(e.toString()));
    }
  }

  Future<void> _onDeleteHomestay(DeleteHomestayEvent event, Emitter<HomestayManagementState> emit) async {
    emit(HomestayManagementLoading());
    try {
      await homestayService.deleteHomestay(event.id);
      emit(HomestayManagementSuccess('Xóa homestay thành công'));
      add(LoadMyHomestaysEvent());
    } catch (e) {
      emit(HomestayManagementError(e.toString()));
    }
  }
}
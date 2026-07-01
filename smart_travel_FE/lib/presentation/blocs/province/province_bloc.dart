import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/domain/entities/province.dart';
import 'package:smart_travel/domain/usecases/province/add_province_use_case.dart';
import 'package:smart_travel/domain/usecases/province/delete_province_use_case.dart';
import 'package:smart_travel/domain/usecases/province/get_all_province_use_case.dart';
import 'package:smart_travel/domain/usecases/province/update_province_use_case.dart';
import 'package:smart_travel/presentation/blocs/province/province_event.dart';
import 'package:smart_travel/presentation/blocs/province/province_state.dart';

class ProvinceBloc extends Bloc<ProvinceEvent, ProvinceState> {
  final GetAllProvinceUseCase getAllProvinceUseCase;
  final AddProvinceUseCase addProvinceUseCase;
  final UpdateProvinceUseCase updateProvinceUseCase;
  final DeleteProvinceUseCase deleteProvinceUseCase;
  List<ProvinceEntity> _allProvinces = [];

  ProvinceBloc({
    required this.getAllProvinceUseCase,
    required this.addProvinceUseCase,
    required this.deleteProvinceUseCase,
    required this.updateProvinceUseCase,
  }) : super(ProvinceLoading()) {
    on<LoadProvince>(_onLoadProvince);
    on<AddProvince>(_onAddProvince);
    on<DeleteProvince>(_onDeleteProvince);
    on<UpdateProvince>(_onUpdateProvince);
  }

  FutureOr<void> _onLoadProvince(
    LoadProvince event,
    Emitter<ProvinceState> emit,
  ) async {
    emit(ProvinceLoading());
    final isReady = await _ensureProvincesLoaded(
      forceRefresh: event.forceRefresh,
    );
    if (!isReady) {
      emit(const ProvinceError('Khong the tai danh sach tinh thanh'));
      return;
    }

    emit(_buildLoadedState(loadAll: event.loadAll == true));
  }

  FutureOr<void> _onAddProvince(
    AddProvince event,
    Emitter<ProvinceState> emit,
  ) async {
    emit(ProvinceAdding());
    final result = await addProvinceUseCase(event.params);
    result.fold(
      (failure) => emit(AddProvinceError(failure.message)),
      (success) => emit(ProvinceAddSuccess()),
    );
    add(LoadProvince(forceRefresh: true));
  }

  FutureOr<void> _onDeleteProvince(
    DeleteProvince event,
    Emitter<ProvinceState> emit,
  ) async {
    final result = await deleteProvinceUseCase(event.provinceId);
    result.fold(
      (failure) async {
        emit(ProvinceDeleteError(failure.message));
        add(LoadProvince(forceRefresh: true));
      },
      (success) {
        emit(ProvinceDeleteSuccess());
        add(LoadProvince(forceRefresh: true));
      },
    );
  }

  FutureOr<void> _onUpdateProvince(
    UpdateProvince event,
    Emitter<ProvinceState> emit,
  ) async {
    emit(ProvinceUpdateLoading());

    final result = await updateProvinceUseCase(event.params);

    await result.fold(
      (failure) async {
        emit(ProvinceUpdateError(failure.message));
        add(LoadProvince(forceRefresh: true));
      },
      (success) async {
        emit(ProvinceUpdateSuccess());
        add(LoadProvince(forceRefresh: true));
      },
    );
  }

  Future<bool> _ensureProvincesLoaded({bool forceRefresh = false}) async {
    if (!forceRefresh && _allProvinces.isNotEmpty) {
      return true;
    }

    final result = await getAllProvinceUseCase(const NoParams());
    return result.fold(
      (failure) => false,
      (province) {
        _allProvinces = province;
        return true;
      },
    );
  }

  ProvinceLoaded _buildLoadedState({required bool loadAll}) {
    final list = loadAll ? _allProvinces : _allProvinces.take(6).toList();
    return ProvinceLoaded(list);
  }
}

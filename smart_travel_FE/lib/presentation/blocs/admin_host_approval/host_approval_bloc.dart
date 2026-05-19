import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/domain/usecases/host_approval/approve_host_usecase.dart';
import 'package:smart_travel/domain/usecases/host_approval/get_pending_hosts_usecase.dart';
import 'package:smart_travel/domain/usecases/host_approval/reject_host_usecase.dart';
import 'package:smart_travel/presentation/blocs/admin_host_approval/host_approval_event.dart';
import 'package:smart_travel/presentation/blocs/admin_host_approval/host_approval_state.dart';

class HostApprovalBloc extends Bloc<HostApprovalEvent, HostApprovalState> {
  final GetPendingHostsUseCase getPendingHostsUseCase;
  final ApproveHostUseCase approveHostUseCase;
  final RejectHostUseCase rejectHostUseCase;

  HostApprovalBloc({
    required this.getPendingHostsUseCase,
    required this.approveHostUseCase,
    required this.rejectHostUseCase,
  }) : super(HostApprovalInitial()) {
    on<LoadPendingHosts>(_onLoadPendingHosts);
    on<ApproveHostRequested>(_onApproveHost);
    on<RejectHostRequested>(_onRejectHost);
  }

  FutureOr<void> _onLoadPendingHosts(LoadPendingHosts event, Emitter<HostApprovalState> emit) async {
    emit(HostApprovalLoading());
    final result = await getPendingHostsUseCase(PendingHostsParams(page: event.page, size: event.size));
    result.fold(
      (failure) => emit(HostApprovalError(failure.message)),
      (hosts) => emit(HostApprovalLoaded(hosts)),
    );
  }

  FutureOr<void> _onApproveHost(ApproveHostRequested event, Emitter<HostApprovalState> emit) async {
    emit(HostApprovalActionLoading());
    final result = await approveHostUseCase(event.userId);
    result.fold(
      (failure) => emit(HostApprovalError(failure.message)),
      (_) {
        emit(const HostApprovalActionSuccess('Đã duyệt HOST thành công'));
        add(const LoadPendingHosts());
      },
    );
  }

  FutureOr<void> _onRejectHost(RejectHostRequested event, Emitter<HostApprovalState> emit) async {
    emit(HostApprovalActionLoading());
    final result = await rejectHostUseCase(RejectHostParams(userId: event.userId, reason: event.reason));
    result.fold(
      (failure) => emit(HostApprovalError(failure.message)),
      (_) {
        emit(const HostApprovalActionSuccess('Đã từ chối HOST'));
        add(const LoadPendingHosts());
      },
    );
  }
}



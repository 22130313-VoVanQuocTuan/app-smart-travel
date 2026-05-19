import 'package:equatable/equatable.dart';
import 'package:smart_travel/data/models/admin/host_approval_response_model.dart';

abstract class HostApprovalState extends Equatable {
  const HostApprovalState();

  @override
  List<Object?> get props => [];
}

class HostApprovalInitial extends HostApprovalState {}

class HostApprovalLoading extends HostApprovalState {}

class HostApprovalLoaded extends HostApprovalState {
  final List<HostApprovalResponseModel> hosts;

  const HostApprovalLoaded(this.hosts);

  @override
  List<Object?> get props => [hosts];
}

class HostApprovalActionLoading extends HostApprovalState {}

class HostApprovalActionSuccess extends HostApprovalState {
  final String message;

  const HostApprovalActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class HostApprovalError extends HostApprovalState {
  final String message;

  const HostApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}


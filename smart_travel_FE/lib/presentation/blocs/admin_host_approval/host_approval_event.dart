import 'package:equatable/equatable.dart';

abstract class HostApprovalEvent extends Equatable {
  const HostApprovalEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingHosts extends HostApprovalEvent {
  final int page;
  final int size;

  const LoadPendingHosts({this.page = 0, this.size = 10});

  @override
  List<Object?> get props => [page, size];
}

class ApproveHostRequested extends HostApprovalEvent {
  final int userId;

  const ApproveHostRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RejectHostRequested extends HostApprovalEvent {
  final int userId;
  final String reason;

  const RejectHostRequested({required this.userId, required this.reason});

  @override
  List<Object?> get props => [userId, reason];
}


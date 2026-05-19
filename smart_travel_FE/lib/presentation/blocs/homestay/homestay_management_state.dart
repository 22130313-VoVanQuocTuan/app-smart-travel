// lib/presentation/blocs/homestay/homestay_management_state.dart
import 'package:equatable/equatable.dart';
import 'package:smart_travel/domain/entities/homestay.dart';

abstract class HomestayManagementState extends Equatable {
  const HomestayManagementState();

  @override
  List<Object?> get props => [];
}

class HomestayManagementInitial extends HomestayManagementState {}

class HomestayManagementLoading extends HomestayManagementState {}

class HomestayManagementLoaded extends HomestayManagementState {
  final List<Homestay> homestays;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const HomestayManagementLoaded({
    required this.homestays,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  @override
  List<Object?> get props => [homestays, currentPage, totalPages, totalElements];
}

class HomestayManagementSuccess extends HomestayManagementState {
  final String message;

  const HomestayManagementSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class HomestayManagementError extends HomestayManagementState {
  final String message;

  const HomestayManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
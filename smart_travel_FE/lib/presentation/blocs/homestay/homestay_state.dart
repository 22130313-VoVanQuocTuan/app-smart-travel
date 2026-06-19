// lib/presentation/blocs/homestay/homestay_state.dart
import 'package:equatable/equatable.dart';
import 'package:smart_travel/domain/entities/homestay.dart';

abstract class HomestayState extends Equatable {
  const HomestayState();

  @override
  List<Object?> get props => [];
}

class HomestayInitial extends HomestayState {}

class HomestayLoading extends HomestayState {}

class HomestayLoaded extends HomestayState {
  final List<Homestay> homestays;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const HomestayLoaded({
    required this.homestays,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  @override
  List<Object?> get props => [homestays, currentPage, totalPages, totalElements];
}

class HomestayError extends HomestayState {
  final String message;

  const HomestayError(this.message);

  @override
  List<Object?> get props => [message];
}

// States riêng cho Top Revenue Homestays (dùng trên HomeScreen)
class TopRevenueHomestaysLoading extends HomestayState {}

class TopRevenueHomestaysLoaded extends HomestayState {
  final List<Homestay> homestays;

  const TopRevenueHomestaysLoaded({required this.homestays});

  @override
  List<Object?> get props => [homestays];
}

class TopRevenueHomestaysError extends HomestayState {
  final String message;

  const TopRevenueHomestaysError(this.message);

  @override
  List<Object?> get props => [message];
}
// lib/presentation/blocs/homestay/homestay_detail_state.dart

import 'package:equatable/equatable.dart';
import 'package:smart_travel/domain/entities/homestay.dart';

abstract class HomestayDetailState extends Equatable {
  const HomestayDetailState();

  @override
  List<Object?> get props => [];
}

class HomestayDetailInitial extends HomestayDetailState {}

class HomestayDetailLoading extends HomestayDetailState {}

class HomestayDetailLoaded extends HomestayDetailState {
  final Homestay homestay;

  const HomestayDetailLoaded(this.homestay);

  @override
  List<Object?> get props => [homestay];
}

class HomestayDetailError extends HomestayDetailState {
  final String message;

  const HomestayDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
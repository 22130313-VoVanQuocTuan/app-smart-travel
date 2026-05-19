// lib/presentation/blocs/homestay/homestay_detail_event.dart

import 'package:equatable/equatable.dart';

abstract class HomestayDetailEvent extends Equatable {
  const HomestayDetailEvent();

  @override
  List<Object?> get props => [];
}

class GetHomestayDetailEvent extends HomestayDetailEvent {
  final int homestayId;
  final DateTime checkIn;
  final DateTime checkOut;

  const GetHomestayDetailEvent({
    required this.homestayId,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  List<Object?> get props => [homestayId, checkIn, checkOut];
}
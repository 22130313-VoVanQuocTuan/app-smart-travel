// lib/presentation/blocs/homestay/homestay_event.dart

import 'package:equatable/equatable.dart';

abstract class HomestayEvent extends Equatable {
  const HomestayEvent();

  @override
  List<Object?> get props => [];
}

// Load danh sách homestay (có filter)
class LoadHomestaysEvent extends HomestayEvent {
  final String? keyword;
  final int? destinationId;
  final int? minStars;
  final int? maxStars;
  final double? minPrice;
  final double? maxPrice;
  final String? city;
  final int page;
  final int size;
  final String sortBy;
  final String sortDir;

  const LoadHomestaysEvent({
    this.keyword,
    this.destinationId,
    this.minStars,
    this.maxStars,
    this.minPrice,
    this.maxPrice,
    this.city,
    this.page = 0,
    this.size = 10,
    this.sortBy = 'pricePerNight',
    this.sortDir = 'asc',
  });

  @override
  List<Object?> get props => [
    keyword, destinationId, minStars, maxStars,
    minPrice, maxPrice, city, page, size, sortBy, sortDir
  ];
}
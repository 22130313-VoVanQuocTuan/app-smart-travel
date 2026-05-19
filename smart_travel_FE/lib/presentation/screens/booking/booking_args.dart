import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/domain/entities/tour_selection.dart';

class BookingArgs {
  final String bookingType;
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final int? roomTypeId;
  final int roomCapacity;
  final int maxAvailableRooms;
  final List<TourBrief>? selectedTours;

  BookingArgs({
    required this.bookingType,
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.roomTypeId,
    required this.roomCapacity,
    required this.maxAvailableRooms,
    this.selectedTours,
  });
}
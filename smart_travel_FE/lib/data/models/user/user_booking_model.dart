// lib/data/models/user/user_booking_model.dart
import 'package:equatable/equatable.dart';

class UserBooking extends Equatable {
  final int id;
  final String bookingType;
  final int hotelId;
  final String hotelName;
  final String? roomTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final int nights;
  final int numberOfPeople;
  final int numberOfRooms;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final String status;
  final String? cancellationReason;
  final String hotelAddress;
  final String hotelPhone;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const UserBooking({
    required this.id,
    required this.bookingType,
    required this.hotelId,
    required this.hotelName,
    this.roomTypeName,
    required this.startDate,
    required this.endDate,
    required this.nights,
    required this.numberOfPeople,
    required this.numberOfRooms,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.status,
    this.cancellationReason,
    required this.hotelAddress,
    required this.hotelPhone,
    this.qrCode,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  factory UserBooking.fromJson(Map<String, dynamic> json) {
    return UserBooking(
      id: json['id'] ?? 0,
      bookingType: json['bookingType'] ?? 'HOMESTAY',
      hotelId: json['hotelId'] ?? 0,
      hotelName: json['hotelName'] ?? '',
      roomTypeName: json['roomTypeName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      nights: json['nights'] ?? 0,
      numberOfPeople: json['numberOfPeople'] ?? 1,
      numberOfRooms: json['numberOfRooms'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      cancellationReason: json['cancellationReason'],
      hotelAddress: json['hotelAddress'] ?? '',
      hotelPhone: json['hotelPhone'] ?? '',
      qrCode: json['qrCode'],
      createdAt: DateTime.parse(json['createdAt']),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
    );
  }

  bool get isActive => status == 'PENDING' || status == 'CONFIRMED';
  bool get isPast => status == 'COMPLETED' || status == 'CANCELLED' || endDate.isBefore(DateTime.now());
  bool get canCancel => status == 'PENDING' || status == 'CONFIRMED';
  bool get canReview => status == 'COMPLETED';

  @override
  List<Object?> get props => [id, status];
}
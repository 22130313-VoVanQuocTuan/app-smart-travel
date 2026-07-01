// lib/domain/entities/booking_info.dart
class BookingInfo {
  final int homestayId;
  final int? roomTypeId;
  final int userId;
  final double pricePerNight;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfPeople;
  final int numberOfRooms;
  final String? couponCode;
  final double discountAmount;
  final double taxRate;
  final List<TourBookingData> selectedTours;

  BookingInfo({
    required this.homestayId,
    this.roomTypeId,
    required this.userId,
    required this.pricePerNight,
    required this.startDate,
    required this.endDate,
    required this.numberOfPeople,
    required this.numberOfRooms,
    this.couponCode,
    this.discountAmount = 0,
    this.taxRate = 0,
    required this.selectedTours,
  });

  double get subtotal {
    int nights = endDate.difference(startDate).inDays;
    if (nights < 1) nights = 1;

    double total = pricePerNight * numberOfRooms * nights;
    for (final tour in selectedTours) {
      total += tour.pricePerPerson * tour.numberOfPeople;
    }
    return total;
  }

  double get amountBeforeTax {
    final amount = subtotal - discountAmount;
    return amount > 0 ? amount : 0;
  }

  double get taxAmount => amountBeforeTax * taxRate / 100;

  double get totalWithTax => amountBeforeTax + taxAmount;
}

class TourBookingData {
  final int tourId;
  final String tourName;
  final double pricePerPerson;
  final DateTime tourDate;
  final int numberOfPeople;

  TourBookingData({
    required this.tourId,
    required this.tourName,
    required this.pricePerPerson,
    required this.tourDate,
    required this.numberOfPeople,
  });
}

// lib/models/booking_model.dart
class HostBooking {
  final int id;
  final String bookingType;
  final int? hotelId;
  final String hotelName;
  final String guestName;
  final String guestPhone;
  final String? roomTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfRooms;
  final int numberOfPeople;
  final double totalPrice;
  final double finalPrice;
  final double totalWithTax;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  HostBooking({
    required this.id,
    required this.bookingType,
    this.hotelId,
    required this.hotelName,
    required this.guestName,
    required this.guestPhone,
    this.roomTypeName,
    required this.startDate,
    required this.endDate,
    required this.numberOfRooms,
    required this.numberOfPeople,
    required this.totalPrice,
    required this.finalPrice,
    required this.totalWithTax,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostBooking.fromJson(Map<String, dynamic> json) {
    return HostBooking(
      id: json['id'],
      bookingType: json['bookingType'] ?? 'HOMESTAY',
      hotelId: json['hotelId'],
      hotelName: json['hotelName'] ?? '',
      guestName: json['guestName'] ?? '',
      guestPhone: json['guestPhone'] ?? '',
      roomTypeName: json['roomTypeName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      numberOfRooms: json['numberOfRooms'] ?? 1,
      numberOfPeople: json['numberOfPeople'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      totalWithTax: (json['totalWithTax'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class BookingDetail {
  final int id;
  final String bookingType;
  final int? hotelId;
  final String hotelName;
  final int? roomTypeId;
  final String? roomTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final int nights;
  final int numberOfPeople;
  final int numberOfRooms;
  final List<TourBookingInfo> tours;
  final double hotelPrice;
  final double totalTourPrice;
  final double totalPrice;
  final double discountAmount;
  final String? couponCode;
  final double finalPrice;
  final double taxRate;
  final double taxAmount;
  final double totalWithTax;
  final String status;
  final String? paymentStatus;
  final String? paymentMethod;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? message;
  final DateTime? createdAt;
  final String? cancellationReason;

  BookingDetail({
    required this.id,
    required this.bookingType,
    this.hotelId,
    required this.hotelName,
    this.roomTypeId,
    this.roomTypeName,
    required this.startDate,
    required this.endDate,
    required this.nights,
    required this.numberOfPeople,
    required this.numberOfRooms,
    required this.tours,
    required this.hotelPrice,
    required this.totalTourPrice,
    required this.totalPrice,
    required this.discountAmount,
    this.couponCode,
    required this.finalPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.totalWithTax,
    required this.status,
    this.paymentStatus,
    this.paymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.message,
    this.createdAt,
    this.cancellationReason,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      id: json['id'] ?? 0,
      bookingType: json['bookingType'] ?? 'HOMESTAY',
      hotelId: json['hotelId'],
      hotelName: json['hotelName'] ?? '',
      roomTypeId: json['roomTypeId'],
      roomTypeName: json['roomTypeName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      nights: json['nights'] ?? 0,
      numberOfPeople: json['numberOfPeople'] ?? 1,
      numberOfRooms: json['numberOfRooms'] ?? 1,
      tours: (json['tours'] as List? ?? [])
          .map((t) => TourBookingInfo.fromJson(t))
          .toList(),
      hotelPrice: (json['hotelPrice'] ?? 0).toDouble(),
      totalTourPrice: (json['totalTourPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalWithTax: (json['totalWithTax'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      customerName: json['customerName'] ?? 'Khach hang',
      customerPhone: json['customerPhone'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      message: json['message'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      cancellationReason: json['cancellationReason'],
    );
  }
}

class TourBookingInfo {
  final int tourId;
  final String tourName;
  final DateTime tourDate;
  final int numberOfPeople;
  final double unitPrice;
  final double totalPrice;
  final String status;

  TourBookingInfo({
    required this.tourId,
    required this.tourName,
    required this.tourDate,
    required this.numberOfPeople,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
  });

  factory TourBookingInfo.fromJson(Map<String, dynamic> json) {
    return TourBookingInfo(
      tourId: json['tourId'] ?? 0,
      tourName: json['tourName'] ?? '',
      tourDate: DateTime.parse(json['tourDate']),
      numberOfPeople: json['numberOfPeople'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
    );
  }
}

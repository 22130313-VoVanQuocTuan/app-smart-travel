import 'package:smart_travel/domain/entities/invoice_detail.dart';

class InvoiceDetailModel {
  final int bookingId;
  final String? invoiceNumber;
  final String? bookingType;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final int? hotelId;
  final int? tourId;
  final String? serviceName;
  final String? roomTypeName;
  final List<String>? roomAmenities;
  final String? thumbnailUrl;
  final String? startDate;
  final String? endDate;
  final int nights;
  final int numberOfPeople;
  final String? specialRequests;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final String? paymentStatus;
  final String? paymentMethod;
  final double taxAmount;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final bool reviewed;

  InvoiceDetailModel({
    required this.bookingId,
    this.invoiceNumber,
    this.bookingType,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.hotelId,
    this.tourId,
    this.serviceName,
    this.roomTypeName,
    this.roomAmenities,
    this.thumbnailUrl,
    this.startDate,
    this.endDate,
    required this.nights,
    required this.numberOfPeople,
    this.specialRequests,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    this.paymentStatus,
    this.paymentMethod,
    required this.taxAmount,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.reviewed,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      bookingId: json['bookingId'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String?,
      bookingType: json['bookingType'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      hotelId: json['hotelId'] as int?,
      tourId: json['tourId'] as int?,
      serviceName: json['serviceName'] as String?,
      roomTypeName: json['roomTypeName'] as String?,
      roomAmenities: json['roomAmenities'] != null
          ? List<String>.from(json['roomAmenities'])
          : [],
      thumbnailUrl: json['thumbnailUrl'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      nights: json['nights'] as int? ?? 0,
      numberOfPeople: json['numberOfPeople'] as int? ?? 1,
      specialRequests: json['specialRequests'] as String?,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerEmail: json['customerEmail'] as String?,
      reviewed: json['reviewed'] as bool? ?? false,
    );
  }

  InvoiceDetail toEntity() {
    return InvoiceDetail(
      bookingId: bookingId,
      invoiceNumber: invoiceNumber ?? "Unknown",
      bookingType: bookingType ?? "SERVICE",
      status: status ?? "UNKNOWN",
      createdAt: createdAt ?? "",
      updatedAt: updatedAt ?? "",
      hotelId: hotelId,
      tourId: tourId,
      serviceName: serviceName ?? "Dịch vụ",
      roomTypeName: roomTypeName,
      roomAmenities: roomAmenities ?? [],
      thumbnailUrl: thumbnailUrl ?? "",
      startDate: startDate ?? "",
      endDate: endDate ?? "",
      nights: nights,
      numberOfPeople: numberOfPeople,
      specialRequests: specialRequests,
      totalPrice: totalPrice,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      paymentStatus: paymentStatus ?? "UNPAID",
      paymentMethod: paymentMethod ?? "UNKNOWN",
      taxAmount: taxAmount,
      customerName: customerName ?? "Khách hàng",
      customerPhone: customerPhone ?? "",
      customerEmail: customerEmail ?? "",
      reviewed: reviewed,
    );
  }
}

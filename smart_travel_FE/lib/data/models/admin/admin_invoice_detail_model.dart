import 'package:smart_travel/domain/entities/admin_invoice_detail.dart';

class AdminInvoiceDetailModel {
  final int bookingId;
  final String? invoiceNumber;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final int? hotelId;
  final int? tourId;
  final String? serviceName;
  final String? roomTypeName;
  final String? startDate;
  final String? endDate;
  final int numberOfPeople;
  final int? numberOfRooms;
  final String? specialRequests;
  final String? cancellationReason;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final double taxRate;
  final double totalWithTax;
  final String? paymentStatus;
  final String? paymentMethod;
  final double taxAmount;
  final String? refundBankName;
  final String? refundBankBranch;
  final String? refundAccountNumber;
  final String? refundAccountHolder;
  final String? refundRequestedAt;
  final String? refundApprovedAt;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  AdminInvoiceDetailModel({
    required this.bookingId,
    this.invoiceNumber,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.hotelId,
    this.tourId,
    this.serviceName,
    this.roomTypeName,
    this.startDate,
    this.endDate,
    required this.numberOfPeople,
    this.numberOfRooms,
    this.specialRequests,
    this.cancellationReason,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.taxRate,
    required this.totalWithTax,
    this.paymentStatus,
    this.paymentMethod,
    required this.taxAmount,
    this.refundBankName,
    this.refundBankBranch,
    this.refundAccountNumber,
    this.refundAccountHolder,
    this.refundRequestedAt,
    this.refundApprovedAt,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  factory AdminInvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return AdminInvoiceDetailModel(
      bookingId: json['bookingId'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      hotelId: json['hotelId'] as int?,
      tourId: json['tourId'] as int?,
      serviceName: json['serviceName'] as String?,
      roomTypeName: json['roomTypeName'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      numberOfPeople: json['numberOfPeople'] as int? ?? 1,
      numberOfRooms: json['numberOfRooms'] as int?,
      specialRequests: json['specialRequests'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      totalWithTax: (json['totalWithTax'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      refundBankName: json['refundBankName'] as String?,
      refundBankBranch: json['refundBankBranch'] as String?,
      refundAccountNumber: json['refundAccountNumber'] as String?,
      refundAccountHolder: json['refundAccountHolder'] as String?,
      refundRequestedAt: json['refundRequestedAt'] as String?,
      refundApprovedAt: json['refundApprovedAt'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerEmail: json['customerEmail'] as String?,
    );
  }

  AdminInvoiceDetail toEntity() {
    return AdminInvoiceDetail(
      bookingId: bookingId,
      invoiceNumber: invoiceNumber ?? "---",
      status: status ?? "UNKNOWN",
      createdAt: createdAt ?? "",
      updatedAt: updatedAt ?? "",
      hotelId: hotelId,
      tourId: tourId,
      serviceName: serviceName ?? "Dịch vụ không tên",
      roomTypeName: roomTypeName,
      startDate: startDate ?? "",
      endDate: endDate ?? "",
      numberOfPeople: numberOfPeople,
      numberOfRooms: numberOfRooms,
      specialRequests: specialRequests,
      cancellationReason: cancellationReason,
      totalPrice: totalPrice,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      taxRate: taxRate,
      totalWithTax: totalWithTax,
      paymentStatus: paymentStatus ?? "UNPAID",
      paymentMethod: paymentMethod ?? "UNKNOWN",
      taxAmount: taxAmount,
      refundBankName: refundBankName,
      refundBankBranch: refundBankBranch,
      refundAccountNumber: refundAccountNumber,
      refundAccountHolder: refundAccountHolder,
      refundRequestedAt: refundRequestedAt,
      refundApprovedAt: refundApprovedAt,
      customerName: customerName ?? "Khách hàng ẩn danh",
      customerPhone: customerPhone ?? "",
      customerEmail: customerEmail ?? "",
    );
  }
}

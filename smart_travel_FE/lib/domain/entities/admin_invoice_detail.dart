class AdminInvoiceDetail {
  final int bookingId;
  final String invoiceNumber;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int? hotelId;
  final int? tourId;
  final String serviceName;
  final String? roomTypeName;
  final String startDate;
  final String endDate;
  final int numberOfPeople;
  final int? numberOfRooms;
  final String? specialRequests;
  final String? cancellationReason;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final double taxRate;
  final double totalWithTax;
  final String paymentStatus;
  final String paymentMethod;
  final double taxAmount;
  final String? refundBankName;
  final String? refundBankBranch;
  final String? refundAccountNumber;
  final String? refundAccountHolder;
  final String? refundRequestedAt;
  final String? refundApprovedAt;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  const AdminInvoiceDetail({
    required this.bookingId,
    required this.invoiceNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.hotelId,
    this.tourId,
    required this.serviceName,
    this.roomTypeName,
    required this.startDate,
    required this.endDate,
    required this.numberOfPeople,
    this.numberOfRooms,
    this.specialRequests,
    this.cancellationReason,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.taxRate,
    required this.totalWithTax,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.taxAmount,
    this.refundBankName,
    this.refundBankBranch,
    this.refundAccountNumber,
    this.refundAccountHolder,
    this.refundRequestedAt,
    this.refundApprovedAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  });
}

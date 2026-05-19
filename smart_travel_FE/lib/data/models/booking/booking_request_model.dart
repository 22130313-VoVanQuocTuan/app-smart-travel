class BookingRequestModel {
  final String bookingType; // "HOMESTAY"
  final int? homestayId;    // Backend dùng 'homestayId'
  final String startDate;   // String dạng yyyy-MM-dd
  final String? endDate;    // String dạng yyyy-MM-dd
  final int numberOfPeople;
  final int numberOfRooms;
  final String? couponCode;
  final int? roomTypeId;
  final List<Map<String, dynamic>>? tours;

  BookingRequestModel({
    required this.bookingType,
    this.homestayId,
    required this.startDate,
    this.endDate,
    required this.numberOfPeople,
    required this.numberOfRooms,
    this.couponCode,
    this.roomTypeId,
    this.tours,
  });

  // Hàm này dùng để chuyển object thành JSON gửi lên Server
  Map<String, dynamic> toJson() {
    return {
      "bookingType": bookingType,
      "homestayId": homestayId,  // Backend expects 'homestayId'
      "startDate": startDate,
      "endDate": endDate,
      "numberOfPeople": numberOfPeople,
      "numberOfRooms": numberOfRooms,
      "couponCode": couponCode,
      'roomTypeId': roomTypeId,
      if (tours != null && tours!.isNotEmpty) 'tours': tours,

    };
  }
}
class HostBookingListModel {
  final int id;
  final String bookingType;
  final int? hotelId;
  final String hotelName;
  final String guestName;
  final String guestPhone;
  final String roomTypeName;
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

  HostBookingListModel({
    required this.id,
    required this.bookingType,
    required this.hotelId,
    required this.hotelName,
    required this.guestName,
    required this.guestPhone,
    required this.roomTypeName,
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

  factory HostBookingListModel.fromJson(Map<String, dynamic> json) {
    return HostBookingListModel(
      id: json['id'] as int,
      bookingType: json['bookingType'] as String? ?? '',
      hotelId: json['hotelId'] as int?,
      hotelName: json['hotelName'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      guestPhone: json['guestPhone'] as String? ?? '',
      roomTypeName: json['roomTypeName'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      numberOfRooms: json['numberOfRooms'] as int? ?? 0,
      numberOfPeople: json['numberOfPeople'] as int? ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      totalWithTax: (json['totalWithTax'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingType': bookingType,
      'hotelId': hotelId,
      'hotelName': hotelName,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'roomTypeName': roomTypeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'numberOfRooms': numberOfRooms,
      'numberOfPeople': numberOfPeople,
      'totalPrice': totalPrice,
      'finalPrice': finalPrice,
      'totalWithTax': totalWithTax,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}


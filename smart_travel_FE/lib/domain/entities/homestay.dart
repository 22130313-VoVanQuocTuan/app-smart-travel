// lib/domain/entities/homestay.dart
class Homestay {
  final int id;
  final String? name;
  final String? address;
  final String? description;
  final String? phone;
  final String? email;
  final int? stars;
  final double? rating;
  final int? numOfReviews;
  final double? pricePerNight;
  final String? thumbnail;
  final List<String>? images;
  final int? destinationId;
  final String? destinationName;
  final String? provinceName;
  final List<String>? amenities;
  final int? availableRooms;
  final int? totalRooms;
  final double? latitude;
  final double? longitude;
  final List<RoomType>? rooms;
  final List<TourBrief>? availableTours;

  Homestay({
    required this.id,
    required this.name,
    this.address,
    this.description,
    this.phone,
    this.email,
    this.stars,
    this.rating,
    this.numOfReviews,
    this.pricePerNight,
    this.thumbnail,
    this.images,
    this.destinationId,
    this.destinationName,
    this.provinceName,
    this.amenities,
    this.availableRooms,
    this.totalRooms,
    this.latitude,
    this.longitude,
    this.rooms,
    this.availableTours,
  });

  factory Homestay.fromJson(Map<String, dynamic> json) {
    return Homestay(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'],
      phone: json['phone'],
      email: json['email'],
      stars: json['stars'] ?? 0,
      rating: json['rating']?.toDouble(),
      numOfReviews: json['numOfReviews'] ?? 0,
      pricePerNight: json['pricePerNight']?.toDouble(),
      thumbnail: json['thumbnail'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      destinationId: json['destinationId'],
      destinationName: json['destinationName'],
      provinceName: json['provinceName'],
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : [],
      availableRooms: json['availableRooms'] ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      rooms: json['rooms'] != null
          ? (json['rooms'] as List).map((r) => RoomType.fromJson(r)).toList()
          : null,
      availableTours: json['availableTours'] != null
          ? (json['availableTours'] as List).map((t) => TourBrief.fromJson(t)).toList()
          : null,
    );
  }
}

class RoomType {
  final int id;
  final String name;
  final int capacity;
  final double price;
  final int totalRooms;
  final int availableRooms;
  final List<String> amenities;

  RoomType({
    required this.id,
    required this.name,
    required this.capacity,
    required this.price,
    required this.totalRooms,
    required this.availableRooms,
    required this.amenities,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : [],
    );
  }
}

class TourBrief {
  final int id;
  final String name;
  final String? description;
  final int durationDays;
  final int durationNights;
  final double pricePerPerson;
  final int maxPeople;
  final int minPeople;

  TourBrief({
    required this.id,
    required this.name,
    this.description,
    required this.durationDays,
    required this.durationNights,
    required this.pricePerPerson,
    required this.maxPeople,
    required this.minPeople,
  });

  factory TourBrief.fromJson(Map<String, dynamic> json) {
    return TourBrief(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      durationDays: json['durationDays'] ?? 0,
      durationNights: json['durationNights'] ?? 0,
      pricePerPerson: (json['pricePerPerson'] as num?)?.toDouble() ?? 0,
      maxPeople: json['maxPeople'] ?? 0,
      minPeople: json['minPeople'] ?? 1,
    );
  }
}
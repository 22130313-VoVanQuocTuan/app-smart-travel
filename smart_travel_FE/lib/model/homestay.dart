// lib/domain/entities/homestay.dart
class Homestay {
  final int id;
  final String name;
  final String address;
  final double? pricePerNight;
  final int stars;
  final double? rating;
  final int numOfReviews;
  final String? thumbnail;
  final int? destinationId;
  final String? destinationName;
  final String? phone;
  final String? email;
  final String? description;
  final List<String> amenities;
  final int totalRooms;
  final int availableRooms;
  final double? latitude;
  final double? longitude;

  Homestay({
    required this.id,
    required this.name,
    required this.address,
    this.pricePerNight,
    required this.stars,
    this.rating,
    required this.numOfReviews,
    this.thumbnail,
    this.destinationId,
    this.destinationName,
    this.phone,
    this.email,
    this.description,
    required this.amenities,
    required this.totalRooms,
    required this.availableRooms,
    this.latitude,
    this.longitude,
  });

  factory Homestay.fromJson(Map<String, dynamic> json) {
    return Homestay(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      pricePerNight: json['pricePerNight']?.toDouble(),
      stars: json['stars'] ?? 0,
      rating: json['rating']?.toDouble(),
      numOfReviews: json['numOfReviews'] ?? 0,
      thumbnail: json['thumbnail'],
      destinationId: json['destinationId'],
      destinationName: json['destinationName'],
      phone: json['phone'],
      email: json['email'],
      description: json['description'],
      amenities: (json['amenities'] as List?)?.cast<String>() ?? [],
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'minPrice': pricePerNight,
      'stars': stars,
      'rating': rating,
      'numOfReviews': numOfReviews,
      'thumbnail': thumbnail,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'phone': phone,
      'email': email,
      'description': description,
      'amenities': amenities,
      'totalRooms': totalRooms,
      'availableRooms': availableRooms,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
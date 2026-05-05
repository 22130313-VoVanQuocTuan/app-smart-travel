class AIDestinationResponse {
  final int id;
  final String name;
  final String category;
  final String address;
  final String? description;
  final double averageRating;
  final int reviewCount;
  final String? imageUrl;
  final String? provinceName;
  final double? price;
  final String? detailUrl;
  final double? latitude;
  final double? longitude;

  AIDestinationResponse({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.description,
    required this.averageRating,
    required this.reviewCount,
    this.imageUrl,
    this.provinceName,
    this.price,
    this.detailUrl,
    this.latitude,
    this.longitude,
  });

  factory AIDestinationResponse.fromJson(Map<String, dynamic> json) {
    return AIDestinationResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Chưa có tên",
      category: json['type'] ?? json['category'] ?? "DESTINATION",
      address: json['address'] ?? "",
      description: json['description']?.toString(),
      averageRating: (json['rating'] ?? json['averageRating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      imageUrl: json['image'] ?? json['imageUrl'],
      provinceName: json['provinceName'],
      price: (json['price'] ?? json['minPrice'] ?? 0.0).toDouble(),
      detailUrl: json['detailUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
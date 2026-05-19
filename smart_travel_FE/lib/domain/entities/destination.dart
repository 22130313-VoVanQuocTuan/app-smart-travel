// lib/domain/entities/destination.dart
class Destination {
  final int id;
  final String name;
  final String? description;
  final String? province;

  Destination({
    required this.id,
    required this.name,
    this.description,
    this.province,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      province: json['province']?['name'],
    );
  }
}
// lib/domain/entities/tour_selection.dart
class TourSelection {
  final int tourId;
  final String tourName;
  final double pricePerPerson;
  final int numberOfPeople;
  final DateTime tourDate;

  TourSelection({
    required this.tourId,
    required this.tourName,
    required this.pricePerPerson,
    required this.numberOfPeople,
    required this.tourDate,
  });

  TourSelection copyWith({
    int? tourId,
    String? tourName,
    double? pricePerPerson,
    int? numberOfPeople,
    DateTime? tourDate,
  }) {
    return TourSelection(
      tourId: tourId ?? this.tourId,
      tourName: tourName ?? this.tourName,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      tourDate: tourDate ?? this.tourDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId,
      'tourName': tourName,
      'pricePerPerson': pricePerPerson,
      'tourDate': tourDate.toIso8601String().split('T').first,
      'numberOfPeople': numberOfPeople,
    };
  }
}
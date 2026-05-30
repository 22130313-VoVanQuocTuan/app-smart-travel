abstract class ReviewHtdEvent {}

class LoadReviewHtd extends ReviewHtdEvent {
  final String type; // "HOTEL" | "TOUR" | "DESTINATION"
  final int serviceId;
  final int? rating;

  LoadReviewHtd({
    required this.type,
    required this.serviceId,
    this.rating,
  });
}
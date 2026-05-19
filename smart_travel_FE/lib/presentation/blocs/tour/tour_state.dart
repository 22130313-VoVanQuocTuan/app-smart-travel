// lib/presentation/blocs/tour/tour_state.dart
class TourState {}

class TourInitial extends TourState {}

class TourLoading extends TourState {}

class TourLoaded extends TourState {
  final List<dynamic> tours;
  TourLoaded(this.tours);
}

class TourSuccess extends TourState {
  final String message;
  TourSuccess(this.message);
}

class TourError extends TourState {
  final String message;
  final List<dynamic> tours;
  TourError(this.message, {this.tours = const []});
}
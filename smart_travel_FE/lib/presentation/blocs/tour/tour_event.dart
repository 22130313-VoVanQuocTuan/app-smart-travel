// lib/presentation/blocs/tour/tour_event.dart
import 'package:dio/dio.dart';

abstract class TourEvent {}

class LoadToursEvent extends TourEvent {
  final int homestayId;
  LoadToursEvent(this.homestayId);
}

class CreateTourEvent extends TourEvent {
  final FormData formData;
  CreateTourEvent(this.formData);
}

class UpdateTourEvent extends TourEvent {
  final int id;
  final FormData formData;
  UpdateTourEvent(this.id, this.formData);
}

class DeleteTourEvent extends TourEvent {
  final int id;
  DeleteTourEvent(this.id);
}

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class HomestayManagementEvent extends Equatable {
  const HomestayManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyHomestaysEvent extends HomestayManagementEvent {
  final String? keyword;
  final int page;
  final String sortBy;
  final String sortDir;

  const LoadMyHomestaysEvent({
    this.keyword,
    this.page = 0,
    this.sortBy = 'id',
    this.sortDir = 'asc',
  });

  @override
  List<Object?> get props => [keyword, page, sortBy, sortDir];
}

class CreateHomestayEvent extends HomestayManagementEvent {
  final FormData request;

  const CreateHomestayEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateHomestayEvent extends HomestayManagementEvent {
  final int id;
  final FormData formData;

  const UpdateHomestayEvent(this.id, this.formData);

  @override
  List<Object?> get props => [id, formData];
}

class DeleteHomestayEvent extends HomestayManagementEvent {
  final int id;

  const DeleteHomestayEvent(this.id);

  @override
  List<Object?> get props => [id];
}
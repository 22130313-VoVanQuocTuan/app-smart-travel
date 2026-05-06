import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/data/models/homestay/homestay_create_request.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/domain/repositories/homestay_repository.dart';

class CreateHotelUseCase extends UseCase<Hotel, HotelCreateRequest> {
  final HotelRepository repository;

  CreateHotelUseCase(this.repository);

  @override
  Future<Either<Failure, Hotel>> call(HotelCreateRequest params) async {
    return await repository.createHotel(params);
  }
}
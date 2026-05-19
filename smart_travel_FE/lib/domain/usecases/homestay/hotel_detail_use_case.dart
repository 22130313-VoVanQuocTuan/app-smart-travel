import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/usecases/usecase.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/domain/repositories/homestay_repository.dart';

class HotelDetailUseCase extends UseCase<Homestay, HotelDetailParams> {
  final HotelRepository hotelRepository;

  HotelDetailUseCase(this.hotelRepository);

  @override
  Future<Either<Failure, Homestay>> call(HotelDetailParams params) {
    return hotelRepository.getHotelDetail(
      hotelId: params.hotelId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
    );
  }
}

class HotelDetailParams {
  final int hotelId;
  final DateTime checkIn;
  final DateTime checkOut;

  HotelDetailParams({
    required this.hotelId,
    required this.checkIn,
    required this.checkOut,
  });
}

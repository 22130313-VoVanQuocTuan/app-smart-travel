// lib/data/repositories/payment_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/core/network/network_info.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import 'package:smart_travel/domain/entities/booking_info.dart';
import 'package:smart_travel/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final DioClient dioClient;
  final NetworkInfo networkInfo;

  PaymentRepositoryImpl({required this.dioClient, required this.networkInfo});

  @override
  Future<Either<Failure, String>> createOnlinePayment({
    required BookingInfo bookingInfo,
    required String paymentMethod,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Chuyển đổi BookingInfo thành JSON để gửi lên server
        final requestData = {
          'homestayId': bookingInfo.homestayId,
          'roomTypeId': bookingInfo.roomTypeId,
          'userId': bookingInfo.userId,
          'startDate': bookingInfo.startDate.toIso8601String().split('T').first,
          'endDate': bookingInfo.endDate.toIso8601String().split('T').first,
          'numberOfPeople': bookingInfo.numberOfPeople,
          'numberOfRooms': bookingInfo.numberOfRooms,
          'couponCode': bookingInfo.couponCode,
          'discountAmount': bookingInfo.discountAmount,
          'paymentMethod': paymentMethod,
          'tours': bookingInfo.selectedTours.map((tour) => {
            'tourId': tour.tourId,
            'tourName': tour.tourName,
            'pricePerPerson': tour.pricePerPerson,
            'tourDate': tour.tourDate.toIso8601String().split('T').first,
            'numberOfPeople': tour.numberOfPeople,
          }).toList(),
        };

        final response = await dioClient.post(
          ApiConstants.createOnlinePayment,
          data: requestData,
        );

        final String paymentUrl = response.data['data']['paymentUrl'];
        return Right(paymentUrl);

      } on DioException catch (e) {
        if (e.error is ServerException) {
          return Left(ServerFailure((e.error as ServerException).message));
        } else {
          return Left(ServerFailure(e.message ?? 'Lỗi kết nối'));
        }
      } catch (e) {
        return Left(ServerFailure('Lỗi: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('Không có kết nối mạng'));
    }
  }

  @override
  Future<Either<Failure, void>> confirmCashPayment({
    required BookingInfo bookingInfo,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final requestData = {
          'homestayId': bookingInfo.homestayId,
          'roomTypeId': bookingInfo.roomTypeId,
          'userId': bookingInfo.userId,
          'startDate': bookingInfo.startDate.toIso8601String().split('T').first,
          'endDate': bookingInfo.endDate.toIso8601String().split('T').first,
          'numberOfPeople': bookingInfo.numberOfPeople,
          'numberOfRooms': bookingInfo.numberOfRooms,
          'couponCode': bookingInfo.couponCode,
          'discountAmount': bookingInfo.discountAmount,
          'paymentMethod': 'CASH',
          'tours': bookingInfo.selectedTours.map((tour) => ({
            'tourId': tour.tourId,
            'tourName': tour.tourName,
            'pricePerPerson': tour.pricePerPerson,
            'tourDate': tour.tourDate.toIso8601String().split('T').first,
            'numberOfPeople': tour.numberOfPeople,
          })).toList(),
        };

        await dioClient.post(
          ApiConstants.confirmCashPayment,
          data: requestData,
        );
        return const Right(null);

      } on DioException catch (e) {
        if (e.error is ServerException) {
          return Left(ServerFailure((e.error as ServerException).message));
        } else {
          return Left(ServerFailure(e.message ?? 'Lỗi kết nối'));
        }
      } catch (e) {
        return Left(ServerFailure('Lỗi: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('Không có kết nối mạng'));
    }
  }
}
import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart'; // Thư viện của bạn
import 'package:smart_travel/data/repositories/payment_repository_impl.dart';
import 'package:smart_travel/domain/entities/booking_info.dart'; // Import DTOs

abstract class PaymentRepository {
  Future<Either<Failure, String>> createOnlinePayment({
    required BookingInfo bookingInfo,
    required String paymentMethod,
  });

  Future<Either<Failure, void>> confirmCashPayment({
    required BookingInfo bookingInfo,
  });
}
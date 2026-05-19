// lib/domain/usecases/payment/process_payment_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/domain/entities/booking_info.dart';
import 'package:smart_travel/domain/repositories/payment_repository.dart';

class ProcessPaymentUseCase {
  final PaymentRepository repository;

  ProcessPaymentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required BookingInfo bookingInfo,
    required String paymentMethod,
  }) {
    return repository.createOnlinePayment(
      bookingInfo: bookingInfo,
      paymentMethod: paymentMethod,
    );
  }
}
// lib/domain/usecases/payment/confirm_cash_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:smart_travel/core/error/failures.dart';
import 'package:smart_travel/domain/entities/booking_info.dart';
import 'package:smart_travel/domain/repositories/payment_repository.dart';

class ConfirmCashBookingUseCase {
  final PaymentRepository repository;

  ConfirmCashBookingUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required BookingInfo bookingInfo,
  }) {
    return repository.confirmCashPayment(bookingInfo: bookingInfo);
  }
}
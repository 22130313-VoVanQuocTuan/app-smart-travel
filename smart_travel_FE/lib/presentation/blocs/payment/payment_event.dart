// payment_event.dart
import 'package:equatable/equatable.dart';
import 'package:smart_travel/domain/entities/booking_info.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

// Event cho các cổng online (VNPay, MoMo)
class ProcessPaymentSubmitted extends PaymentEvent {
  final BookingInfo bookingInfo;
  final String paymentMethod;

  const ProcessPaymentSubmitted({
    required this.bookingInfo,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [bookingInfo, paymentMethod];
}

// Event cho thanh toán tiền mặt
class ConfirmCashPayment extends PaymentEvent {
  final BookingInfo bookingInfo;

  const ConfirmCashPayment({required this.bookingInfo});

  @override
  List<Object?> get props => [bookingInfo];
}
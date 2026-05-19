import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_event.dart';
import 'payment_state.dart';
import 'package:smart_travel/data/repositories/payment_repository_impl.dart';
import 'package:smart_travel/domain/usecases/payment/process_payment_usecase.dart';
import 'package:smart_travel/domain/usecases/payment/confirm_cash_usecase.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ProcessPaymentUseCase processPaymentUseCase;
  final ConfirmCashBookingUseCase confirmCashBookingUseCase;

  PaymentBloc({
    required this.processPaymentUseCase,
    required this.confirmCashBookingUseCase,
  }) : super(PaymentInitial()) {
    on<ProcessPaymentSubmitted>(_onProcessPaymentSubmitted);
    on<ConfirmCashPayment>(_onConfirmCashPayment);
  }

  //Xử lý thanh toán online (VNPay, MoMo)
  Future<void> _onProcessPaymentSubmitted(
      ProcessPaymentSubmitted event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());

    // Gọi API tạo booking + tạo link thanh toán
    final result = await processPaymentUseCase(
      bookingInfo: event.bookingInfo,
      paymentMethod: event.paymentMethod,
    );

    result.fold(
          (failure) => emit(PaymentFailure(failure.message)),
          (paymentUrl) => emit(PaymentSuccess(paymentUrl)),
    );
  }

  // Xử lý thanh toán tiền mặt
  Future<void> _onConfirmCashPayment(
      ConfirmCashPayment event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());

    // Gọi API tạo booking + xác nhận thanh toán sau
    final result = await confirmCashBookingUseCase(
      bookingInfo: event.bookingInfo,
    );

    result.fold(
          (failure) => emit(PaymentFailure(failure.message)),
          (_) => emit(PaymentCashSuccess()),
    );
  }
}
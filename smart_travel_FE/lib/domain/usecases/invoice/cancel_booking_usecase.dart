import '../../repositories/invoice_repository.dart';

class CancelBookingUseCase {
  final InvoiceRepository repository;

  CancelBookingUseCase(this.repository);

  Future<void> call({
    required int bookingId,
    required String reason,
    String? refundBankName,
    String? refundBankBranch,
    String? refundAccountNumber,
    String? refundAccountHolder,
  }) async {
    return await repository.cancelBooking(
      bookingId: bookingId,
      reason: reason,
      refundBankName: refundBankName,
      refundBankBranch: refundBankBranch,
      refundAccountNumber: refundAccountNumber,
      refundAccountHolder: refundAccountHolder,
    );
  }
}


abstract class CancelEvent {}

class SubmitCancelRequest extends CancelEvent {
  final int bookingId;
  final String reason;
  final String? refundBankName;
  final String? refundBankBranch;
  final String? refundAccountNumber;
  final String? refundAccountHolder;

  SubmitCancelRequest({
    required this.bookingId,
    required this.reason,
    this.refundBankName,
    this.refundBankBranch,
    this.refundAccountNumber,
    this.refundAccountHolder,
  });
}

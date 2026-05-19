class CancellationPolicyResponse {
  final bool canCancel;
  final int cancelBeforeHours;
  final String cancelDeadline;
  final double cancellationFeePercent;
  final double estimatedCancellationFee;
  final String message;

  CancellationPolicyResponse({
    required this.canCancel,
    required this.cancelBeforeHours,
    required this.cancelDeadline,
    required this.cancellationFeePercent,
    required this.estimatedCancellationFee,
    required this.message,
  });

  factory CancellationPolicyResponse.fromJson(Map<String, dynamic> json) {
    return CancellationPolicyResponse(
      canCancel: json['canCancel'] ?? false,
      cancelBeforeHours: json['cancelBeforeHours'] ?? 24,
      cancelDeadline: json['cancelDeadline'] ?? '',
      cancellationFeePercent: (json['cancellationFeePercent'] ?? 0).toDouble(),
      estimatedCancellationFee: (json['estimatedCancellationFee'] ?? 0).toDouble(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canCancel': canCancel,
      'cancelBeforeHours': cancelBeforeHours,
      'cancelDeadline': cancelDeadline,
      'cancellationFeePercent': cancellationFeePercent,
      'estimatedCancellationFee': estimatedCancellationFee,
      'message': message,
    };
  }
}
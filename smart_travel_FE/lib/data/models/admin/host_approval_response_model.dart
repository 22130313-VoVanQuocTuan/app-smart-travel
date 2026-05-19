class HostApprovalResponseModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? idCardNumber;
  final String? idCardImageUrl;
  final String? ownershipDocumentUrl;
  final String? portraitUrl;
  final bool? hostVerified;
  final DateTime? createdAt;

  HostApprovalResponseModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.idCardNumber,
    this.idCardImageUrl,
    this.ownershipDocumentUrl,
    this.portraitUrl,
    this.hostVerified,
    this.createdAt,
  });

  factory HostApprovalResponseModel.fromJson(Map<String, dynamic> json) {
    return HostApprovalResponseModel(
      userId: (json['userId'] ?? json['id'] ?? 0) as int,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: json['phone']?.toString(),
      idCardNumber: json['idCardNumber']?.toString(),
      idCardImageUrl: json['idCardImageUrl']?.toString(),
      ownershipDocumentUrl: json['ownershipDocumentUrl']?.toString(),
      portraitUrl: json['portraitUrl']?.toString(),
      hostVerified: json['hostVerified'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}


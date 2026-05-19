class RegisterParams{
  final String fullName;
  final String email;
  final String? phone;
  final String password;
  final String confirmPassword;
  final String? role; // 'USER' or 'HOST'

  // Fields for homestay owner verification (optional for regular users)
  final String? idCardNumber; // CCCD
  final String? idCardImageUrl; // URL returned after upload
  final String? ownershipDocumentUrl; // Sổ hộ khẩu / Giấy tờ quyền sở hữu
  final String? portraitUrl; // Ảnh chân dung

  RegisterParams({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    this.role,
    this.idCardNumber,
    this.idCardImageUrl,
    this.ownershipDocumentUrl,
    this.portraitUrl,
  });

}
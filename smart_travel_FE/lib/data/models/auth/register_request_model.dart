
class RegisterRequestModel{
  final String fullName;
  final String email;
  final String? phone;
  final String password;
  final String confirmPassword;
  final String? role;
  final String? idCardNumber;
  final String? idCardImageUrl;
  final String? ownershipDocumentUrl;
  final String? portraitUrl;


  RegisterRequestModel({
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

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      'role': role,
      'idCardNumber': idCardNumber,
      'idCardImageUrl': idCardImageUrl,
      'ownershipDocumentUrl': ownershipDocumentUrl,
      'portraitUrl': portraitUrl,
    };
  }


  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    return RegisterRequestModel(
      fullName: json['fullName'] ,
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      confirmPassword: json['confirmPassword'],
      // Backward compatibility: optional fields
      role: json['role'],
      idCardNumber: json['idCardNumber'],
      idCardImageUrl: json['idCardImageUrl'],
      ownershipDocumentUrl: json['ownershipDocumentUrl'],
      portraitUrl: json['portraitUrl'],
    );
  }
}
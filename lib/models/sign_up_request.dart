class SignUpRequest {
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String? promoCode; // ✅ optional

  SignUpRequest({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.promoCode,
  });

  Map<String, dynamic> toJson() {
    return {
      "phoneNumber": phoneNumber,
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      if (promoCode != null && promoCode!.isNotEmpty) "promoCode": promoCode,
    };
  }
}

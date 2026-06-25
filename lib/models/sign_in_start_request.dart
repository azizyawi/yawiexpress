import 'dart:convert';

class SignInStartRequest {
  final String phoneNumber;

  const SignInStartRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }

  factory SignInStartRequest.fromMap(Map<String, dynamic> map) {
    return SignInStartRequest(phoneNumber: map['phoneNumber'] as String);
  }

  factory SignInStartRequest.fromJson(String source) {
    return SignInStartRequest.fromMap(
      json.decode(source) as Map<String, dynamic>,
    );
  }
}

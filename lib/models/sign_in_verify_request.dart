import 'dart:convert';

class SignInVerifyRequest {
  final String phoneNumber;
  final String code;
  final String session;

  const SignInVerifyRequest({
    required this.phoneNumber,
    required this.code,
    required this.session,
  });

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber, 'code': code, 'session': session};
  }

  factory SignInVerifyRequest.fromMap(Map<String, dynamic> map) {
    return SignInVerifyRequest(
      phoneNumber: map['phoneNumber'] as String,
      code: map['code'] as String,
      session: map['session'] as String,
    );
  }

  factory SignInVerifyRequest.fromJson(String source) {
    return SignInVerifyRequest.fromMap(
      json.decode(source) as Map<String, dynamic>,
    );
  }
}

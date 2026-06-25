import 'dart:convert';

class VerifyOtpRequest {
  final String phoneNumber;
  final String code;

  const VerifyOtpRequest({required this.phoneNumber, required this.code});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber, 'code': code};
  }

  factory VerifyOtpRequest.fromMap(Map<String, dynamic> map) {
    return VerifyOtpRequest(
      phoneNumber: map['phoneNumber'] as String,
      code: map['code'] as String,
    );
  }

  factory VerifyOtpRequest.fromJson(String source) {
    return VerifyOtpRequest.fromMap(
      json.decode(source) as Map<String, dynamic>,
    );
  }
}

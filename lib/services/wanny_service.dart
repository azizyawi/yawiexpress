import 'dart:convert';
import 'package:http/http.dart' as http;

class WannyChatService {
  static const String _baseUrl = 'https://orders.wanmac.ng';

  Future<WannyChatResponse> sendMessage({
    required String message,
    required String sessionId,
    String? name,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'sessionId': sessionId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      }),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Unable to contact Wanny');
    }

    return WannyChatResponse.fromJson(data);
  }
}

class WannyChatResponse {
  final String message;
  final String? action;
  final String? nextAction;
  final List<WannySuggestion> suggestions;

  WannyChatResponse({
    required this.message,
    this.action,
    this.nextAction,
    required this.suggestions,
  });

  factory WannyChatResponse.fromJson(Map<String, dynamic> json) {
    return WannyChatResponse(
      message: json['message']?.toString() ?? '',
      action: json['action']?.toString(),
      nextAction: json['nextAction']?.toString(),
      suggestions: ((json['suggestions'] as List?) ?? [])
          .map((item) => WannySuggestion.fromJson(item))
          .toList(),
    );
  }
}

class WannySuggestion {
  final String title;
  final String payload;

  WannySuggestion({required this.title, required this.payload});

  factory WannySuggestion.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;

    return WannySuggestion(
      title: map['title']?.toString() ?? '',
      payload: map['payload']?.toString() ?? '',
    );
  }
}

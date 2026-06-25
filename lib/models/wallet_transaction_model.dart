class WalletTransactionModel {
  final String title;
  final String message;
  final int amount;
  final String direction;
  final String type;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  WalletTransactionModel({
    required this.title,
    required this.message,
    required this.amount,
    required this.direction,
    required this.type,
    required this.createdAt,
    required this.metadata,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      amount: _parseAmount(json['amount']),
      direction: (json['direction'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  static int _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  bool get isCredit => direction.toLowerCase() == 'credit';
  bool get isDebit => direction.toLowerCase() == 'debit';
}

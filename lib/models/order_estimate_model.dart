class OrderEstimateModel {
  final double distanceKm;
  final int estimatedTimeMin;
  final double deliveryFee;
  final double serviceFee;
  final double amount;
  final String currency;

  const OrderEstimateModel({
    required this.distanceKm,
    required this.estimatedTimeMin,
    required this.deliveryFee,
    required this.serviceFee,
    required this.amount,
    required this.currency,
  });

  factory OrderEstimateModel.fromJson(Map<String, dynamic> json) {
    return OrderEstimateModel(
      distanceKm: (json['distanceKm'] as num).toDouble(),
      estimatedTimeMin: (json['estimatedTimeMin'] as num).toInt(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] ?? 'NGN').toString(),
    );
  }
}

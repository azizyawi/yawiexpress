class RecentActivityModel {
  final String activityId;
  final String userId;
  final String orderId;
  final String type;
  final String title;
  final String subtitle;
  final String status;
  final String createdAt;

  RecentActivityModel({
    required this.activityId,
    required this.userId,
    required this.orderId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      activityId: json['activityId'] ?? '',
      userId: json['userId'] ?? '',
      orderId: json['orderId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
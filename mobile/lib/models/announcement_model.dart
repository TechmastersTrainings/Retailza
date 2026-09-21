class AnnouncementModel {
  final int id;
  final String title;
  final String message;
  final String tag;
  final String? actionUrl;
  final bool isActive;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.tag,
    this.actionUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      tag: (json['tag'] as String?) ?? 'FEATURE',
      actionUrl: json['action_url'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'tag': tag,
      'action_url': actionUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

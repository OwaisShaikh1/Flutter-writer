class Comment {
  final int id;
  final int? remoteId;
  final int itemId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  Comment({
    required this.id,
    this.remoteId,
    required this.itemId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      remoteId: json['id'],
      itemId: json['item_id'] ?? json['itemId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      username: json['username'] ?? 'Anonymous',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remoteId': remoteId,
      'itemId': itemId,
      'userId': userId,
      'username': username,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  // Convert from Drift entity
  factory Comment.fromEntity(dynamic entity) {
    return Comment(
      id: entity.id,
      remoteId: entity.remoteId,
      itemId: entity.itemId,
      userId: entity.userId,
      username: entity.username,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
    );
  }

  Comment copyWith({
    int? id,
    int? remoteId,
    int? itemId,
    int? userId,
    String? username,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Comment(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

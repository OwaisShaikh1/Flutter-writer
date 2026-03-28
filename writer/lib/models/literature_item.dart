class LiteratureItem {
  final int id;
  final String title;
  final String author;
  final int? authorId; // User ID who created this
  final String type;
  final double rating;
  final int chapters;
  final int comments;
  final int likes;
  final bool isLikedByUser;
  final String? imageUrl;
  final String? imageLocalPath;
  final String description;
  final bool isFavorite;
  final bool isSynced;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LiteratureItem({
    required this.id,
    required this.title,
    required this.author,
    this.authorId,
    required this.type,
    required this.rating,
    required this.chapters,
    required this.comments,
    this.likes = 0,
    this.isLikedByUser = false,
    this.imageUrl,
    this.imageLocalPath,
    required this.description,
    this.isFavorite = false,
    this.isSynced = false,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory LiteratureItem.fromJson(Map<String, dynamic> json) {
    // Helper to convert int/bool to bool (MySQL returns 0/1 for booleans)
    bool toBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    int toInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double toDouble(dynamic value, {double fallback = 0.0}) {
      if (value == null) return fallback;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    String toText(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    final rawAuthorId = json['authorId'] ?? json['author_id'];

    return LiteratureItem(
      id: toInt(json['id'] ?? json['item_id']),
      title: toText(json['title'] ?? json['name']),
      author: toText(json['author'], fallback: 'Unknown Author'),
      authorId: rawAuthorId == null ? null : toInt(rawAuthorId),
      type: toText(json['type']),
      rating: toDouble(json['rating'] ?? json['review']),
      chapters: toInt(json['chapters'] ?? json['chaptersCount'] ?? json['Number_of_chapters']),
      comments: toInt(json['comments'] ?? json['commentsCount'] ?? json['comments_count']),
      likes: toInt(json['likes'] ?? json['likesCount'] ?? json['likes_count']),
      isLikedByUser: toBool(json['isLikedByUser'] ?? json['is_liked_by_user']),
      imageUrl: (json['image'] ?? json['imageUrl'] ?? json['image_path'])?.toString(),
      description: toText(json['description']),
      isFavorite: toBool(json['isFavorite']),
      isSynced: toBool(json['isSynced']),
        version: toInt(json['version'], fallback: 1),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'authorId': authorId,
      'type': type,
      'rating': rating,
      'chapters': chapters,
      'comments': comments,
      'likes': likes,
      'isLikedByUser': isLikedByUser,
      'imageUrl': imageUrl,
      'imageLocalPath': imageLocalPath,
      'description': description,
      'isFavorite': isFavorite,
      'isSynced': isSynced,
      'version': version,
    };
  }

  // Convert from Drift entity
  factory LiteratureItem.fromEntity(dynamic entity) {
    return LiteratureItem(
      id: entity.id,
      title: entity.name,
      author: entity.author,
      authorId: entity.authorId,
      type: entity.type,
      rating: entity.rating,
      chapters: entity.chaptersCount,
      comments: entity.commentsCount,
      likes: entity.likesCount,
      isLikedByUser: entity.isLikedByUser,
      imageUrl: entity.imageUrl,
      imageLocalPath: entity.imageLocalPath,
      description: entity.description,
      isFavorite: entity.isFavorite,
      isSynced: entity.isSynced,
      version: entity.version,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Convert to map (for backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'authorId': authorId,
      'type': type,
      'rating': rating,
      'chapters': chapters,
      'comments': comments,
      'likes': likes,
      'isLikedByUser': isLikedByUser,
      'image': imageUrl,
      'description': description,
    };
  }

  // CopyWith for immutability
  LiteratureItem copyWith({
    int? id,
    String? title,
    String? author,
    int? authorId,
    String? type,
    double? rating,
    int? chapters,
    int? comments,
    int? likes,
    bool? isLikedByUser,
    String? imageUrl,
    String? imageLocalPath,
    String? description,
    bool? isFavorite,
    bool? isSynced,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiteratureItem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      chapters: chapters ?? this.chapters,
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      imageUrl: imageUrl ?? this.imageUrl,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      isSynced: isSynced ?? this.isSynced,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if item is owned by a specific user
  bool isOwnedBy(int? userId) => authorId != null && authorId == userId;
}

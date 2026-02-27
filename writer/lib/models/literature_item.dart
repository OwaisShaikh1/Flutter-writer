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

    return LiteratureItem(
      id: json['id'] ?? json['item_id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      author: json['author'] ?? '',
      authorId: json['authorId'] ?? json['author_id'],
      type: json['type'] ?? '',
      rating: (json['rating'] ?? json['review'] ?? 0.0).toDouble(),
      chapters: json['chapters'] ?? json['chaptersCount'] ?? json['Number_of_chapters'] ?? 0,
      comments: json['comments'] ?? json['commentsCount'] ?? json['comments_count'] ?? 0,
      likes: json['likes'] ?? json['likesCount'] ?? json['likes_count'] ?? 0,
      isLikedByUser: toBool(json['isLikedByUser'] ?? json['is_liked_by_user']),
      imageUrl: json['image'] ?? json['imageUrl'] ?? json['image_path'],
      description: json['description'] ?? '',
      isFavorite: toBool(json['isFavorite']),
      isSynced: toBool(json['isSynced']),
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
    );
  }

  // Check if item is owned by a specific user
  bool isOwnedBy(int? userId) => authorId != null && authorId == userId;
}

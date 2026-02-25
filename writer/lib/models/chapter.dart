class Chapter {
  final int id;
  final int itemId;
  final int number;
  final String title;
  final String content;
  final bool isDownloaded;
  final DateTime? downloadedAt;
  final DateTime? createdAt;

  Chapter({
    required this.id,
    required this.itemId,
    required this.number,
    required this.title,
    required this.content,
    this.isDownloaded = false,
    this.downloadedAt,
    this.createdAt,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      itemId: json['itemId'] ?? json['item_id'] ?? json['bookId'] ?? 0,
      number: json['number'] ?? json['chapterNumber'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Chapter ${json['number'] ?? 0}',
      content: json['content'] ?? json['Text'] ?? '',
      isDownloaded: json['isDownloaded'] ?? false,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'number': number,
      'title': title,
      'content': content,
      'isDownloaded': isDownloaded,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Convert from Drift entity
  factory Chapter.fromEntity(dynamic entity) {
    return Chapter(
      id: entity.id,
      itemId: entity.itemId,
      number: entity.number,
      title: entity.title,
      content: entity.content,
      isDownloaded: entity.isDownloaded,
      downloadedAt: entity.downloadedAt,
      createdAt: entity.createdAt,
    );
  }

  Chapter copyWith({
    int? id,
    int? itemId,
    int? number,
    String? title,
    String? content,
    bool? isDownloaded,
    DateTime? downloadedAt,
    DateTime? createdAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      number: number ?? this.number,
      title: title ?? this.title,
      content: content ?? this.content,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

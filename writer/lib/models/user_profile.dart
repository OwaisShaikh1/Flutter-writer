class UserProfile {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? bio;
  final int followers;
  final int following;
  final int posts;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      posts: json['posts'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'bio': bio,
      'followers': followers,
      'following': following,
      'posts': posts,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Convert from Drift entity
  factory UserProfile.fromEntity(dynamic entity) {
    return UserProfile(
      id: entity.id,
      name: entity.name,
      username: entity.username,
      email: entity.email,
      bio: entity.bio,
      followers: entity.followers,
      following: entity.following,
      posts: entity.posts,
      createdAt: entity.createdAt,
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? bio,
    int? followers,
    int? following,
    int? posts,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

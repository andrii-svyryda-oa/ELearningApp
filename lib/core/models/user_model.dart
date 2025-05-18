class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<String> enrolledCourses;
  final Map<String, dynamic> progress;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    this.enrolledCourses = const [],
    this.progress = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      enrolledCourses: List<String>.from(json['enrolledCourses'] ?? []),
      progress: json['progress'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'enrolledCourses': enrolledCourses,
      'progress': progress,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? enrolledCourses,
    Map<String, dynamic>? progress,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      progress: progress ?? this.progress,
    );
  }
}

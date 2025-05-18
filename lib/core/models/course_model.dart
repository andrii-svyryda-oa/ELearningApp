class CourseModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String author;
  final int durationMinutes;
  final String level;
  final List<String> tags;
  final List<LessonModel> lessons;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.author,
    required this.durationMinutes,
    required this.level,
    this.tags = const [],
    this.lessons = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      author: json['author'] as String,
      durationMinutes: json['durationMinutes'] as int,
      level: json['level'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'author': author,
      'durationMinutes': durationMinutes,
      'level': level,
      'tags': tags,
      'lessons': lessons.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class LessonModel {
  final String id;
  final String title;
  final String content;
  final int order;
  final List<String> resources;
  final String? videoUrl;

  LessonModel({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    this.resources = const [],
    this.videoUrl,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
      resources: List<String>.from(json['resources'] ?? []),
      videoUrl: json['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'resources': resources,
      'videoUrl': videoUrl,
    };
  }
}

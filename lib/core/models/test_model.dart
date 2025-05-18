class TestModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final int timeLimit; // in minutes
  final List<QuestionModel> questions;
  final int passingScore;

  TestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.timeLimit,
    required this.questions,
    required this.passingScore,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      courseId: json['courseId'] as String,
      timeLimit: json['timeLimit'] as int,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      passingScore: json['passingScore'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseId': courseId,
      'timeLimit': timeLimit,
      'questions': questions.map((e) => e.toJson()).toList(),
      'passingScore': passingScore,
    };
  }
}

class QuestionModel {
  final String id;
  final String text;
  final List<AnswerModel> answers;
  final QuestionType type;
  final int points;

  QuestionModel({
    required this.id,
    required this.text,
    required this.answers,
    required this.type,
    required this.points,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => AnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${json['type']}',
        orElse: () => QuestionType.singleChoice,
      ),
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'answers': answers.map((e) => e.toJson()).toList(),
      'type': type.toString().split('.').last,
      'points': points,
    };
  }
}

class AnswerModel {
  final String id;
  final String text;
  final bool isCorrect;

  AnswerModel({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

enum QuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
}

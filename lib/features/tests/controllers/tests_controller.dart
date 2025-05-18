import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_learning_app/core/models/test_model.dart';
import 'package:e_learning_app/core/models/user_model.dart';
import 'package:e_learning_app/core/services/firebase_service.dart';
import 'package:e_learning_app/core/services/local_storage_service.dart';
import 'package:e_learning_app/features/auth/controllers/auth_controller.dart';

final testsForCourseProvider = FutureProvider.family<List<TestModel>, String>((ref, courseId) async {
  final firebaseService = FirebaseService();
  try {
    // Try to get from local storage first
    final localTests = await LocalStorageService.getTestsForCourse(courseId);
    if (localTests.isNotEmpty) {
      return localTests;
    }
    
    // If not found locally, fetch from Firebase
    return await firebaseService.getTestsForCourse(courseId);
  } catch (e) {
    return [];
  }
});

final testDetailsProvider = FutureProvider.family<TestModel?, String>((ref, testId) async {
  final firebaseService = FirebaseService();
  try {
    // Try to get from local storage first
    final localTests = await LocalStorageService.getTests();
    final localTest = localTests.firstWhere(
      (test) => test.id == testId,
      orElse: () => null as TestModel,
    );
    
    if (localTest != null) {
      return localTest;
    }
    
    // If not found locally, fetch from Firebase
    return await firebaseService.getTest(testId);
  } catch (e) {
    return null;
  }
});

final activeTestProvider = StateNotifierProvider<ActiveTestController, AsyncValue<TestSession?>>((ref) {
  final user = ref.watch(authControllerProvider);
  return ActiveTestController(user.value);
});

class TestSession {
  final TestModel test;
  final Map<String, List<String>> userAnswers;
  final DateTime startTime;
  int currentQuestionIndex;
  bool isCompleted;
  
  TestSession({
    required this.test,
    required this.startTime,
    this.userAnswers = const {},
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
  });
  
  int get totalQuestions => test.questions.length;
  
  int get answeredQuestions => userAnswers.length;
  
  bool get isLastQuestion => currentQuestionIndex == totalQuestions - 1;
  
  bool get isFirstQuestion => currentQuestionIndex == 0;
  
  Map<String, dynamic> calculateResults() {
    int correctAnswers = 0;
    int totalPoints = 0;
    int earnedPoints = 0;
    
    for (final question in test.questions) {
      totalPoints += question.points;
      
      final questionId = question.id;
      final selectedAnswers = userAnswers[questionId] ?? [];
      
      if (question.type == QuestionType.singleChoice || 
          question.type == QuestionType.trueFalse) {
        // For single choice, check if the selected answer is correct
        if (selectedAnswers.isNotEmpty) {
          final selectedAnswerId = selectedAnswers.first;
          final selectedAnswer = question.answers.firstWhere(
            (answer) => answer.id == selectedAnswerId,
            orElse: () => null as AnswerModel,
          );
          
          if (selectedAnswer != null && selectedAnswer.isCorrect) {
            correctAnswers++;
            earnedPoints += question.points;
          }
        }
      } else if (question.type == QuestionType.multipleChoice) {
        // For multiple choice, all correct answers must be selected and no incorrect ones
        final correctAnswerIds = question.answers
            .where((answer) => answer.isCorrect)
            .map((answer) => answer.id)
            .toList();
        
        final incorrectSelected = selectedAnswers.any(
          (answerId) => !correctAnswerIds.contains(answerId),
        );
        
        final allCorrectSelected = correctAnswerIds.every(
          (answerId) => selectedAnswers.contains(answerId),
        );
        
        if (allCorrectSelected && !incorrectSelected) {
          correctAnswers++;
          earnedPoints += question.points;
        }
      }
    }
    
    final percentage = totalPoints > 0 ? (earnedPoints / totalPoints) * 100 : 0;
    final isPassed = percentage >= test.passingScore;
    
    return {
      'testId': test.id,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'earnedPoints': earnedPoints,
      'totalPoints': totalPoints,
      'percentage': percentage,
      'isPassed': isPassed,
      'completedAt': DateTime.now().toIso8601String(),
    };
  }
}

class ActiveTestController extends StateNotifier<AsyncValue<TestSession?>> {
  ActiveTestController(this._user) : super(const AsyncValue.data(null));

  final UserModel? _user;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> startTest(TestModel test) async {
    state = AsyncValue.data(
      TestSession(
        test: test,
        startTime: DateTime.now(),
      ),
    );
  }

  void answerQuestion(String questionId, List<String> answerIds) {
    final currentTest = state.value;
    if (currentTest == null) return;
    
    final updatedAnswers = Map<String, List<String>>.from(currentTest.userAnswers);
    updatedAnswers[questionId] = answerIds;
    
    state = AsyncValue.data(
      TestSession(
        test: currentTest.test,
        startTime: currentTest.startTime,
        userAnswers: updatedAnswers,
        currentQuestionIndex: currentTest.currentQuestionIndex,
        isCompleted: currentTest.isCompleted,
      ),
    );
  }

  void nextQuestion() {
    final currentTest = state.value;
    if (currentTest == null || currentTest.isLastQuestion) return;
    
    state = AsyncValue.data(
      TestSession(
        test: currentTest.test,
        startTime: currentTest.startTime,
        userAnswers: currentTest.userAnswers,
        currentQuestionIndex: currentTest.currentQuestionIndex + 1,
        isCompleted: currentTest.isCompleted,
      ),
    );
  }

  void previousQuestion() {
    final currentTest = state.value;
    if (currentTest == null || currentTest.isFirstQuestion) return;
    
    state = AsyncValue.data(
      TestSession(
        test: currentTest.test,
        startTime: currentTest.startTime,
        userAnswers: currentTest.userAnswers,
        currentQuestionIndex: currentTest.currentQuestionIndex - 1,
        isCompleted: currentTest.isCompleted,
      ),
    );
  }

  Future<Map<String, dynamic>> completeTest() async {
    final currentTest = state.value;
    if (currentTest == null) return {};
    
    final results = currentTest.calculateResults();
    
    // Mark as completed
    state = AsyncValue.data(
      TestSession(
        test: currentTest.test,
        startTime: currentTest.startTime,
        userAnswers: currentTest.userAnswers,
        currentQuestionIndex: currentTest.currentQuestionIndex,
        isCompleted: true,
      ),
    );
    
    // Save results if user is logged in
    if (_user != null) {
      await _firebaseService.saveTestResult(_user!.id, currentTest.test.id, results);
      await LocalStorageService.saveTestResult(_user!.id, currentTest.test.id, results);
    }
    
    return results;
  }

  void resetTest() {
    state = const AsyncValue.data(null);
  }
}

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:e_learning_app/core/models/user_model.dart';
import 'package:e_learning_app/core/models/course_model.dart';
import 'package:e_learning_app/core/models/test_model.dart';

class LocalStorageService {
  static const String _userBox = 'userBox';
  static const String _coursesBox = 'coursesBox';
  static const String _testsBox = 'testsBox';
  static const String _progressBox = 'progressBox';
  static const String _settingsBox = 'settingsBox';

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    await Hive.openBox(_userBox);
    await Hive.openBox(_coursesBox);
    await Hive.openBox(_testsBox);
    await Hive.openBox(_progressBox);
    await Hive.openBox(_settingsBox);
  }

  // User methods
  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box(_userBox);
    await box.put('currentUser', jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final box = Hive.box(_userBox);
    final userJson = box.get('currentUser');
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  static Future<void> removeUser() async {
    final box = Hive.box(_userBox);
    await box.delete('currentUser');
  }

  // Courses methods
  static Future<void> saveCourses(List<CourseModel> courses) async {
    final box = Hive.box(_coursesBox);
    final coursesJson = courses.map((course) => jsonEncode(course.toJson())).toList();
    await box.put('allCourses', coursesJson);
  }

  static Future<List<CourseModel>> getCourses() async {
    final box = Hive.box(_coursesBox);
    final coursesJson = box.get('allCourses', defaultValue: []);
    if (coursesJson.isEmpty) return [];
    return (coursesJson as List).map((courseJson) => CourseModel.fromJson(jsonDecode(courseJson))).toList();
  }

  static Future<CourseModel?> getCourse(String courseId) async {
    final courses = await getCourses();
    return courses.firstWhere((course) => course.id == courseId, orElse: () => null as CourseModel);
  }

  // Tests methods
  static Future<void> saveTests(List<TestModel> tests) async {
    final box = Hive.box(_testsBox);
    final testsJson = tests.map((test) => jsonEncode(test.toJson())).toList();
    await box.put('allTests', testsJson);
  }

  static Future<List<TestModel>> getTests() async {
    final box = Hive.box(_testsBox);
    final testsJson = box.get('allTests', defaultValue: []);
    if (testsJson.isEmpty) return [];
    return (testsJson as List).map((testJson) => TestModel.fromJson(jsonDecode(testJson))).toList();
  }

  static Future<List<TestModel>> getTestsForCourse(String courseId) async {
    final tests = await getTests();
    return tests.where((test) => test.courseId == courseId).toList();
  }

  // Progress methods
  static Future<void> saveProgress(String userId, String courseId, Map<String, dynamic> progress) async {
    final box = Hive.box(_progressBox);
    final key = '${userId}_${courseId}';
    await box.put(key, jsonEncode(progress));
  }

  static Future<Map<String, dynamic>?> getProgress(String userId, String courseId) async {
    final box = Hive.box(_progressBox);
    final key = '${userId}_${courseId}';
    final progressJson = box.get(key);
    if (progressJson == null) return null;
    return jsonDecode(progressJson);
  }

  static Future<void> saveTestResult(String userId, String testId, Map<String, dynamic> result) async {
    final box = Hive.box(_progressBox);
    final key = '${userId}_test_${testId}';
    await box.put(key, jsonEncode(result));
  }

  static Future<Map<String, dynamic>?> getTestResult(String userId, String testId) async {
    final box = Hive.box(_progressBox);
    final key = '${userId}_test_${testId}';
    final resultJson = box.get(key);
    if (resultJson == null) return null;
    return jsonDecode(resultJson);
  }

  // Settings methods
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }
}

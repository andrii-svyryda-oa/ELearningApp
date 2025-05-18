import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_learning_app/core/models/course_model.dart';
import 'package:e_learning_app/core/models/user_model.dart';
import 'package:e_learning_app/core/services/firebase_service.dart';
import 'package:e_learning_app/core/services/local_storage_service.dart';
import 'package:e_learning_app/features/auth/controllers/auth_controller.dart';

final coursesControllerProvider = StateNotifierProvider<CoursesController, AsyncValue<List<CourseModel>>>((ref) {
  final user = ref.watch(authControllerProvider);
  return CoursesController(user.value);
});

final userCoursesProvider = StateNotifierProvider<UserCoursesController, AsyncValue<List<CourseModel>>>((ref) {
  final user = ref.watch(authControllerProvider);
  return UserCoursesController(user.value);
});

final courseDetailsProvider = FutureProvider.family<CourseModel?, String>((ref, courseId) async {
  final firebaseService = FirebaseService();
  try {
    // Try to get from local storage first
    final localCourse = await LocalStorageService.getCourse(courseId);
    if (localCourse != null) {
      return localCourse;
    }
    
    // If not found locally, fetch from Firebase
    return await firebaseService.getCourse(courseId);
  } catch (e) {
    return null;
  }
});

class CoursesController extends StateNotifier<AsyncValue<List<CourseModel>>> {
  CoursesController(this._user) : super(const AsyncValue.loading()) {
    _init();
  }

  final UserModel? _user;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      // Try to get courses from local storage first
      final localCourses = await LocalStorageService.getCourses();
      if (localCourses.isNotEmpty) {
        state = AsyncValue.data(localCourses);
      }
      
      // Fetch from Firebase to get the latest data
      final courses = await _firebaseService.getAllCourses();
      await LocalStorageService.saveCourses(courses);
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshCourses() async {
    state = const AsyncValue.loading();
    try {
      final courses = await _firebaseService.getAllCourses();
      await LocalStorageService.saveCourses(courses);
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    if (_user == null) return;
    
    try {
      await _firebaseService.enrollInCourse(_user.id, courseId);
      
      // Update local user data
      final updatedUser = _user!.copyWith(
        enrolledCourses: [..._user!.enrolledCourses, courseId],
      );
      
      await LocalStorageService.saveUser(updatedUser);
    } catch (e) {
      rethrow;
    }
  }
}

class UserCoursesController extends StateNotifier<AsyncValue<List<CourseModel>>> {
  UserCoursesController(this._user) : super(const AsyncValue.loading()) {
    if (_user != null) {
      _init();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final UserModel? _user;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _init() async {
    if (_user == null) return;
    
    state = const AsyncValue.loading();
    try {
      final courses = await _firebaseService.getUserCourses(_user!.id);
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshUserCourses() async {
    if (_user == null) return;
    
    state = const AsyncValue.loading();
    try {
      final courses = await _firebaseService.getUserCourses(_user!.id);
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

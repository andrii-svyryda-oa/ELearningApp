import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_learning_app/core/models/user_model.dart';
import 'package:e_learning_app/core/services/firebase_service.dart';
import 'package:e_learning_app/core/services/local_storage_service.dart';
import 'package:e_learning_app/features/auth/controllers/auth_controller.dart';

final profileControllerProvider = Provider<ProfileController>((ref) {
  final user = ref.watch(authControllerProvider);
  return ProfileController(ref, user.value);
});

class ProfileController {
  final Ref _ref;
  final UserModel? _user;
  final FirebaseService _firebaseService = FirebaseService();

  ProfileController(this._ref, this._user);

  Future<void> updateProfile({
    String? displayName,
    File? profileImage,
  }) async {
    if (_user == null) return;

    try {
      String? photoUrl = _user!.photoUrl;

      if (profileImage != null) {
        // Upload profile image to Firebase Storage
        final imagePath = 'profile_images/${_user!.id}.jpg';
        photoUrl = await _firebaseService.uploadFile(imagePath, profileImage);
      }

      final updatedUser = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        photoUrl: photoUrl,
      );

      await _ref.read(authControllerProvider.notifier).updateProfile(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    if (_user == null) {
      return {
        'completedCourses': 0,
        'inProgressCourses': 0,
        'completedTests': 0,
        'averageScore': 0.0,
      };
    }

    try {
      // Get enrolled courses
      final enrolledCourses = _user!.enrolledCourses.length;
      
      // Calculate completed courses from progress data
      int completedCourses = 0;
      int inProgressCourses = 0;
      
      for (final courseId in _user!.enrolledCourses) {
        final progress = await LocalStorageService.getProgress(_user!.id, courseId);
        if (progress != null) {
          final completion = progress['completion'] as double? ?? 0.0;
          if (completion >= 100) {
            completedCourses++;
          } else if (completion > 0) {
            inProgressCourses++;
          }
        }
      }
      
      // Get test results
      int completedTests = 0;
      double totalScore = 0.0;
      
      for (final courseId in _user!.enrolledCourses) {
        final tests = await LocalStorageService.getTestsForCourse(courseId);
        
        for (final test in tests) {
          final result = await LocalStorageService.getTestResult(_user!.id, test.id);
          if (result != null) {
            completedTests++;
            totalScore += result['percentage'] as double? ?? 0.0;
          }
        }
      }
      
      final averageScore = completedTests > 0 ? totalScore / completedTests : 0.0;
      
      return {
        'completedCourses': completedCourses,
        'inProgressCourses': inProgressCourses,
        'completedTests': completedTests,
        'averageScore': averageScore,
      };
    } catch (e) {
      return {
        'completedCourses': 0,
        'inProgressCourses': 0,
        'completedTests': 0,
        'averageScore': 0.0,
      };
    }
  }
}

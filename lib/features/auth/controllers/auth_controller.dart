import 'package:e_learning_app/core/models/user_model.dart';
import 'package:e_learning_app/core/services/firebase_service.dart';
import 'package:e_learning_app/core/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController() : super(const AsyncValue.loading()) {
    _init();
  }

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser != null) {
        final userModel = await _firebaseService.getUserProfile(currentUser.uid);
        if (userModel != null) {
          await LocalStorageService.saveUser(userModel);
          state = AsyncValue.data(userModel);
        } else {
          state = const AsyncValue.data(null);
        }
      } else {
        final localUser = await LocalStorageService.getUser();
        state = AsyncValue.data(localUser);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userModel = await _firebaseService.signInWithEmailAndPassword(email, password);

      if (userModel != null) {
        final updatedUser = userModel.copyWith(lastLogin: DateTime.now());

        await _firebaseService.updateUserProfile(updatedUser);
        await LocalStorageService.saveUser(updatedUser);
        state = AsyncValue.data(updatedUser);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final userModel = await _firebaseService.createUserWithEmailAndPassword(email, password);

      if (userModel != null) {
        await LocalStorageService.saveUser(userModel);
        state = AsyncValue.data(userModel);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      await LocalStorageService.removeUser();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      await _firebaseService.updateUserProfile(updatedUser);
      await LocalStorageService.saveUser(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}

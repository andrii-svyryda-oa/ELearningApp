import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_learning_app/core/models/course_model.dart';
import 'package:e_learning_app/core/models/test_model.dart';
import 'package:e_learning_app/core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          return UserModel.fromJson(userData.data()!);
        }
      }
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }

    return null;
  }

  Future<UserModel?> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Step 1: Create the Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User created");

      final user = userCredential.user;
      if (user != null) {
        try {
          // Step 2: Create a UserModel object
          final now = DateTime.now();
          final newUser = UserModel(
            id: user.uid,
            email: email,
            displayName: displayName,
            photoUrl: null,
            createdAt: now,
            lastLogin: now,
            enrolledCourses: [],
            progress: {},
          );

          // Step 3: Create the user document in Firestore
          // Convert to Map explicitly to avoid type casting issues
          final userData = {
            'id': newUser.id,
            'email': newUser.email,
            'displayName': newUser.displayName,
            'photoUrl': newUser.photoUrl,
            'createdAt': newUser.createdAt.toIso8601String(),
            'lastLogin': newUser.lastLogin.toIso8601String(),
            'enrolledCourses': [], // Empty array instead of using the model
            'progress': {}, // Empty map instead of using the model
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
          return newUser;
        } catch (firestoreError) {
          // If Firestore operation fails, delete the auth user to avoid orphaned accounts
          print('Error creating user document: $firestoreError');
          await user.delete();
          rethrow;
        }
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }

    return null;
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> createUserProfile(UserModel user) async {
    return await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> updateUserProfile(UserModel user) async {
    return await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  Future<List<CourseModel>> getAllCourses() async {
    final snapshot = await _firestore.collection('courses').get();
    print(snapshot.docs.map((doc) => doc.data()));
    return snapshot.docs.map((doc) => CourseModel.fromJson(doc.id, doc.data())).toList();
  }

  Future<CourseModel?> getCourse(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) return null;
    return CourseModel.fromJson(doc.id, doc.data()!);
  }

  Future<List<CourseModel>> getUserCourses(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;
    final enrolledCourses = List<String>.from(userData['enrolledCourses'] ?? []);

    if (enrolledCourses.isEmpty) return [];

    final coursesSnapshot =
        await _firestore
            .collection('courses')
            .where(FieldPath.documentId, whereIn: enrolledCourses)
            .get();

    return coursesSnapshot.docs.map((doc) => CourseModel.fromJson(doc.id, doc.data())).toList();
  }

  Future<void> enrollInCourse(String userId, String courseId) async {
    return await _firestore.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayUnion([courseId]),
    });
  }

  Future<List<TestModel>> getTestsForCourse(String courseId) async {
    final snapshot =
        await _firestore.collection('tests').where('courseId', isEqualTo: courseId).get();

    return snapshot.docs.map((doc) => TestModel.fromJson(doc.data())).toList();
  }

  Future<TestModel?> getTest(String testId) async {
    final doc = await _firestore.collection('tests').doc(testId).get();
    if (!doc.exists) return null;
    return TestModel.fromJson(doc.data()!);
  }

  Future<void> saveUserProgress(
    String userId,
    String courseId,
    Map<String, dynamic> progress,
  ) async {
    return await _firestore.collection('progress').doc('${userId}_$courseId').set(progress);
  }

  Future<Map<String, dynamic>?> getUserProgress(String userId, String courseId) async {
    final doc = await _firestore.collection('progress').doc('${userId}_$courseId').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> saveTestResult(String userId, String testId, Map<String, dynamic> result) async {
    return await _firestore.collection('test_results').doc('${userId}_$testId').set(result);
  }

  Future<Map<String, dynamic>?> getTestResult(String userId, String testId) async {
    final doc = await _firestore.collection('test_results').doc('${userId}_$testId').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  Future<String> uploadFile(String path, dynamic file) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}

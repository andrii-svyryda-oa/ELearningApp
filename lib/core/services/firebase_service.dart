import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:e_learning_app/core/models/user_model.dart';
import 'package:e_learning_app/core/models/course_model.dart';
import 'package:e_learning_app/core/models/test_model.dart';

class FirebaseService {
  // Use Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  


  // Authentication methods
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Convert to UserModel
      final user = userCredential.user;
      if (user != null) {
        // Fetch user data from Firestore
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

  Future<UserModel?> createUserWithEmailAndPassword(String email, String password) async {
    
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Convert to UserModel
      final user = userCredential.user;
      if (user != null) {
        final now = DateTime.now();
        final newUser = UserModel(
          id: user.uid,
          email: email,
          displayName: email.split('@')[0],
          photoUrl: null,
          createdAt: now,
          lastLogin: now,
          enrolledCourses: [],
          progress: {},
        );
        
        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
        return newUser;
      }
    } catch (e) {
      print('Error creating user: $e');
      return null;
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

  // User methods
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

  // Course methods
  Future<List<CourseModel>> getAllCourses() async {
    final snapshot = await _firestore.collection('courses').get();
    return snapshot.docs
        .map((doc) => CourseModel.fromJson(doc.data()))
        .toList();
  }

  Future<CourseModel?> getCourse(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) return null;
    return CourseModel.fromJson(doc.data()!);
  }

  Future<List<CourseModel>> getUserCourses(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];
    
    final userData = userDoc.data()!;
    final enrolledCourses = List<String>.from(userData['enrolledCourses'] ?? []);
    
    if (enrolledCourses.isEmpty) return [];
    
    final coursesSnapshot = await _firestore
        .collection('courses')
        .where(FieldPath.documentId, whereIn: enrolledCourses)
        .get();
    
    return coursesSnapshot.docs
        .map((doc) => CourseModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> enrollInCourse(String userId, String courseId) async {
    return await _firestore.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayUnion([courseId]),
    });
  }

  // Test methods
  Future<List<TestModel>> getTestsForCourse(String courseId) async {
    final snapshot = await _firestore
        .collection('tests')
        .where('courseId', isEqualTo: courseId)
        .get();
    
    return snapshot.docs
        .map((doc) => TestModel.fromJson(doc.data()))
        .toList();
  }

  Future<TestModel?> getTest(String testId) async {
    final doc = await _firestore.collection('tests').doc(testId).get();
    if (!doc.exists) return null;
    return TestModel.fromJson(doc.data()!);
  }

  // Progress methods
  Future<void> saveUserProgress(String userId, String courseId, Map<String, dynamic> progress) async {
    return await _firestore.collection('progress').doc('${userId}_${courseId}').set(progress);
  }

  Future<Map<String, dynamic>?> getUserProgress(String userId, String courseId) async {
    final doc = await _firestore.collection('progress').doc('${userId}_${courseId}').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> saveTestResult(String userId, String testId, Map<String, dynamic> result) async {
    return await _firestore.collection('test_results').doc('${userId}_${testId}').set(result);
  }

  Future<Map<String, dynamic>?> getTestResult(String userId, String testId) async {
    final doc = await _firestore.collection('test_results').doc('${userId}_${testId}').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  // Storage methods
  Future<String> uploadFile(String path, dynamic file) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}

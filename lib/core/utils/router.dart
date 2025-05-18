import 'package:e_learning_app/core/widgets/main_scaffold.dart';
import 'package:e_learning_app/features/auth/controllers/auth_controller.dart';
import 'package:e_learning_app/features/auth/views/login_screen.dart';
import 'package:e_learning_app/features/auth/views/register_screen.dart';
import 'package:e_learning_app/features/courses/views/course_details_screen.dart';
import 'package:e_learning_app/features/courses/views/courses_list_screen.dart';
import 'package:e_learning_app/features/profile/views/profile_screen.dart';
import 'package:e_learning_app/features/tests/views/test_screen.dart';
import 'package:e_learning_app/features/tests/views/tests_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/courses',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/courses';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/courses',
            builder: (context, state) => const CoursesListScreen(),
            routes: [
              GoRoute(
                path: ':courseId',
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId']!;
                  return CourseDetailsScreen(courseId: courseId);
                },
                routes: [
                  GoRoute(
                    path: 'tests',
                    builder: (context, state) {
                      final courseId = state.pathParameters['courseId']!;
                      return TestsListScreen(courseId: courseId);
                    },
                  ),
                  GoRoute(
                    path: 'tests/:testId',
                    builder: (context, state) {
                      final testId = state.pathParameters['testId']!;
                      return TestScreen(testId: testId);
                    },
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: '/tests',
            builder: (context, state) => const TestsListScreen(courseId: 'all'),
          ),

          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:e_learning_app/core/models/test_model.dart';
import 'package:e_learning_app/features/tests/controllers/tests_controller.dart';

class TestsListScreen extends ConsumerWidget {
  final String courseId;

  const TestsListScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final testsAsync = ref.watch(testsForCourseProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tests),
      ),
      body: testsAsync.when(
        data: (tests) {
          if (tests.isEmpty) {
            return Center(
              child: Text(l10n.noTestsFound),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return _buildTestCard(context, test, index);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(testsForCourseProvider(courseId)),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test, int index) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to test details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                test.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${test.timeLimit} min',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${test.questions.length} ${l10n.questions}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${test.passingScore}% ${l10n.toPass}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Start test
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(l10n.startTest),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 100 * index));
  }
}

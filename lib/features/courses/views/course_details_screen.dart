import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_app/core/models/course_model.dart';
import 'package:e_learning_app/features/courses/controllers/courses_controller.dart';
import 'package:e_learning_app/features/auth/controllers/auth_controller.dart';

class CourseDetailsScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen> {
  bool _isEnrolling = false;

  Future<void> _enrollInCourse(String courseId) async {
    setState(() {
      _isEnrolling = true;
    });

    try {
      await ref.read(coursesControllerProvider.notifier).enrollInCourse(courseId);
      await ref.read(userCoursesProvider.notifier).refreshUserCourses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully enrolled in course')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enroll: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));
    final userAsync = ref.watch(authControllerProvider);
    
    return Scaffold(
      body: courseAsync.when(
        data: (course) {
          if (course == null) {
            return Center(child: Text('Course not found'));
          }
          
          return _buildCourseDetails(context, course, userAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(courseDetailsProvider(widget.courseId)),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetails(
    BuildContext context, 
    CourseModel course,
    AsyncValue<dynamic> userAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isEnrolled = userAsync.value?.enrolledCourses.contains(course.id) ?? false;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: course.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      course.author,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${course.durationMinutes} min',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      course.level,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  l10n.courseDetails,
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  course.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: course.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
                Text(
                  'Lessons',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),
                _buildLessonsList(context, course.lessons),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isEnrolled || _isEnrolling
                        ? null
                        : () => _enrollInCourse(course.id),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isEnrolling
                        ? const CircularProgressIndicator()
                        : Text(
                            isEnrolled ? l10n.continueCourse : l10n.startCourse,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsList(BuildContext context, List<LessonModel> lessons) {
    return Column(
      children: lessons
          .asMap()
          .entries
          .map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${entry.value.order}'),
                ),
                title: Text(entry.value.title),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to lesson details
                },
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 700 + (entry.key * 100))),
          )
          .toList(),
    );
  }
}

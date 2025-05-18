import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_app/core/models/course_model.dart';
import 'package:e_learning_app/features/courses/controllers/courses_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoursesListScreen extends ConsumerStatefulWidget {
  const CoursesListScreen({super.key});

  @override
  ConsumerState<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends ConsumerState<CoursesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allCourses = ref.watch(coursesControllerProvider);
    final userCourses = ref.watch(userCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.courses),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.allCourses), Tab(text: l10n.myCourses)],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                allCourses.when(
                  data: (courses) {
                    final filteredCourses = _filterCourses(courses);
                    return _buildCoursesList(filteredCourses);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('Error: ${error.toString()}')),
                ),
                userCourses.when(
                  data: (courses) {
                    final filteredCourses = _filterCourses(courses);
                    return filteredCourses.isEmpty
                        ? Center(child: Text(l10n.noCoursesFound))
                        : _buildCoursesList(filteredCourses);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('Error: ${error.toString()}')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CourseModel> _filterCourses(List<CourseModel> courses) {
    if (_searchQuery.isEmpty) return courses;

    return courses.where((course) {
      return course.title.toLowerCase().contains(_searchQuery) ||
          course.description.toLowerCase().contains(_searchQuery) ||
          course.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Widget _buildCoursesList(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noCoursesFound));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(coursesControllerProvider.notifier).refreshCourses();
        await ref.read(userCoursesProvider.notifier).refreshUserCourses();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(course, index);
        },
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course, int index) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              // Navigate to course details
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: course.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${course.durationMinutes} min',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(course.level, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            course.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag),
                                    labelStyle: const TextStyle(fontSize: 12),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 100 * index));
  }
}

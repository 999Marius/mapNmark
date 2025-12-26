// lib/features/professor/sections/courses_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/attendance_service.dart';
import '../course_details_screen.dart';
import '../widgets/add_course_sheet.dart';
import 'package:map_n_mark/services/attendance_service.dart';

class ProfessorCoursesSection extends ConsumerWidget {
  const ProfessorCoursesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(professorCoursesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(professorCoursesProvider),
        child: coursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return ListView(children: const [SizedBox(height: 100), Center(child: Text("No courses yet. Click + to add one."))]);
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(course['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Code: ${course['code']}"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await _showDeleteConfirm(context, course['name']);
                          if (confirm) {
                            await ref.read(attendanceServiceProvider).deleteCourse(course['id']);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'delete', child: Text("Delete Course", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailsScreen(course: course))),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Error: $e")),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => const AddCourseSheet()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showDeleteConfirm(BuildContext context, String name) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Course?"),
        content: Text("This will permanently delete '$name' and ALL attendance records for it. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete")),
        ],
      ),
    ) ?? false;
  }
}
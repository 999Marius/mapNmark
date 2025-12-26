// lib/features/student/widgets/enrollment_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/attendance_service.dart'; // Add this
import '../student_course_details_screen.dart';

class EnrollmentCard extends ConsumerWidget { // Change to ConsumerWidget
  final String courseId;

  const EnrollmentCard({super.key, required this.courseId});

  // Helper function to show confirmation dialog
  Future<void> _confirmLeave(BuildContext context, WidgetRef ref, String courseName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Course?"),
        content: Text("Are you sure you want to leave '$courseName'? Your personal history for this course will be hidden from your dashboard."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(attendanceServiceProvider).leaveCourse(courseId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Left $courseName")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add ref here
    return FutureBuilder(
      future: supabase.from('courses').select().eq('id', courseId).single(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox(); // Hide if error
        if (!snapshot.hasData) return const ListTile(title: Text("Loading..."));

        final course = snapshot.data!;
        final String courseName = course['name'] ?? 'Unknown Course';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("View statistics & history"),

            // --- ADDED THE MENU BUTTON HERE ---
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'leave') {
                  _confirmLeave(context, ref, courseName);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text("Leave Course", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentCourseDetailsScreen(course: course),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
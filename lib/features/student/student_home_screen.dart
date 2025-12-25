// lib/features/student/student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'widgets/enrollment_card.dart';
import 'widgets/join_course_dialog.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enrolled Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Listen for real-time changes to enrollments for THIS student
        stream: supabase
            .from('course_enrollments')
            .stream(primaryKey: ['id'])
            .eq('student_id', userId),
        builder: (context, snapshot) {
          // 1. Handle Errors
          if (snapshot.hasError) {
            debugPrint("Supabase Stream Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 2. Handle Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final enrollments = snapshot.data ?? [];

          // 3. Handle Empty State
          if (enrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("You haven't joined any courses yet."),
                  const SizedBox(height: 8),
                  const Text("Click the button below to join one.",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. Show List of Cards
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              final courseId = enrollments[index]['course_id'];
              return EnrollmentCard(courseId: courseId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const JoinCourseDialog(),
          );
        },
        label: const Text("Join Course"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
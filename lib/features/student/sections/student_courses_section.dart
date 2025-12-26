import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/attendance_service.dart';
import '../widgets/enrollment_card.dart';
import '../widgets/join_course_dialog.dart';

class StudentCoursesSection extends ConsumerWidget {
  const StudentCoursesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(studentEnrollmentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentEnrollmentsProvider.future),
        child: enrollmentsAsync.when(
          data: (enrollments) {
            if (enrollments.isEmpty) {
              return ListView(children: const [SizedBox(height: 100), Center(child: Text("No courses joined."))]);
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: enrollments.length,
              itemBuilder: (context, index) => EnrollmentCard(
                key: ValueKey(enrollments[index]['id']),
                courseId: enrollments[index]['course_id'],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Error: $e")),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (context) => const JoinCourseDialog()),
        label: const Text("Join Course"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
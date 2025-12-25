// lib/features/professor/professor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'widgets/course_card.dart';
import 'widgets/add_course_sheet.dart';

class ProfessorHomeScreen extends ConsumerStatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  ConsumerState<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends ConsumerState<ProfessorHomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _coursesStream;

  @override
  void initState() {
    super.initState();
    _coursesStream = supabase
        .from('courses')
        .stream(primaryKey: ['id'])
        .eq('professor_id', supabase.auth.currentUser!.id)
        .order('created_at');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _coursesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final courses = snapshot.data!;

          if (courses.isEmpty) return const Center(child: Text('No courses yet.'));

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) => CourseCard(course: courses[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddCourseSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'package:map_n_mark/features/professor/generate_qr_screen.dart';

class ProfessorHomeScreen extends ConsumerStatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  ConsumerState<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends ConsumerState<ProfessorHomeScreen> {
  // We initialize the stream late to avoid accessing 'supabase' before it's ready
  late final Stream<List<Map<String, dynamic>>> _coursesStream;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser!.id;
    _coursesStream = supabase
        .from('courses')
        .stream(primaryKey: ['id'])
        .eq('professor_id', userId)
        .order('created_at');
  }

  Future<void> _addCourseDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Course Name (e.g. Math)'),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Course Code (e.g. MAT101)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && codeController.text.isNotEmpty) {
                try {
                  await supabase.from('courses').insert({
                    'professor_id': supabase.auth.currentUser!.id,
                    'name': nameController.text,
                    'code': codeController.text,
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _coursesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!;

          if (courses.isEmpty) {
            return const Center(
              child: Text('No courses yet. Add one!'),
            );
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(course['name']),
                  subtitle: Text(course['code']),
                  trailing: const Icon(Icons.qr_code),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenerateQrScreen(
                          courseId: course['id'],
                          courseName: course['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
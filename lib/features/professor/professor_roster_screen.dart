// lib/features/professor/professor_roster_screen.dart
import 'package:flutter/material.dart';
import 'package:map_n_mark/main.dart';

class ProfessorRosterScreen extends StatelessWidget {
  final String courseId;
  final String courseName;

  const ProfessorRosterScreen({super.key, required this.courseId, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$courseName: Roster")),
      body: FutureBuilder(
        future: supabase.rpc('get_course_roster_stats', params: {'input_course_id': courseId}),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final roster = snapshot.data as List<dynamic>;

          if (roster.isEmpty) {
            return const Center(child: Text("No students enrolled in this course."));
          }

          return ListView.builder(
            itemCount: roster.length,
            itemBuilder: (context, index) {
              final student = roster[index];
              final double percent = (student['attendance_percentage'] as num).toDouble();
              final isAtRisk = percent < 75.0; // Threshold for warning

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAtRisk ? Colors.red[100] : Colors.green[100],
                    child: Text(student['full_name'][0],
                        style: TextStyle(color: isAtRisk ? Colors.red : Colors.green)),
                  ),
                  title: Text(student['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${student['total_attended']} attended out of ${student['total_sessions_counted']} counted"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${percent.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isAtRisk ? Colors.red : Colors.green,
                        ),
                      ),
                      if (isAtRisk)
                        const Text("AT RISK", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
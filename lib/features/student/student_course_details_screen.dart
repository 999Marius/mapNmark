// lib/features/student/student_course_details_screen.dart
import 'package:flutter/material.dart';
import 'package:map_n_mark/main.dart';
import 'widgets/attendance_receipt_sheet.dart';

class StudentCourseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> course;

  const StudentCourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: Text(course['name'])),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Attendance History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder(
              stream: supabase.from('attendance_records').stream(primaryKey: ['id']).eq('student_id', userId).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Filter records for this course only
                return FutureBuilder(
                  future: supabase.from('sessions').select('id, name, latitude, longitude, radius_meters').eq('course_id', course['id']),
                  builder: (context, sessionSnapshot) {
                    if (!sessionSnapshot.hasData) return const SizedBox();

                    final sessionData = sessionSnapshot.data as List<dynamic>;
                    final validSessionIds = sessionData.map((s) => s['id']).toList();
                    final records = snapshot.data!.where((r) => validSessionIds.contains(r['session_id'])).toList();

                    if (records.isEmpty) return const Center(child: Text("No attendance records for this course."));

                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final r = records[index];
                        final s = sessionData.firstWhere((ses) => ses['id'] == r['session_id']);
                        final date = DateTime.parse(r['created_at']).toLocal();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.verified, color: r['status'] == 'present' ? Colors.green : Colors.orange),
                            title: Text(s['name'] ?? "Unnamed Session"),
                            subtitle: Text("${date.day}/${date.month} at ${date.hour}:${date.minute}"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => AttendanceReceiptSheet(record: r, session: s),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
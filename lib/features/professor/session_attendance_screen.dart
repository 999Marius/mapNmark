// lib/features/professor/session_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:map_n_mark/main.dart';

class SessionAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String courseId;
  final String dateLabel;

  const SessionAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.courseId,
    required this.dateLabel,
  });

  @override
  State<SessionAttendanceScreen> createState() => _SessionAttendanceScreenState();
}

class _SessionAttendanceScreenState extends State<SessionAttendanceScreen> {
  bool _isLoading = false;

  // This function handles Present, Excused, and resetting to Absent
  Future<void> _updateStudentStatus(String studentId, String? newStatus) async {
    try {
      if (newStatus == null) {
        // DELETE the record (Sets them back to Absent)
        await supabase
            .from('attendance_records')
            .delete()
            .match({'session_id': widget.sessionId, 'student_id': studentId});
      } else {
        // UPSERT the record (Present or Excused)
        await supabase.from('attendance_records').upsert({
          'session_id': widget.sessionId,
          'student_id': studentId,
          'status': newStatus,
          'distance_verified': 0, // Manual entry
        });
      }

      // Refresh the list
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Status updated"), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      print("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dateLabel)),
      body: FutureBuilder(
        // Ensure you have run the 'get_session_roster' SQL provided previously
        future: supabase.rpc('get_session_roster', params: {
          'input_session_id': widget.sessionId,
          'input_course_id': widget.courseId,
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final roster = snapshot.data as List<dynamic>;

          return ListView.builder(
            itemCount: roster.length,
            itemBuilder: (context, index) {
              final student = roster[index];
              final String status = student['attendance_status'] ?? 'absent';

              return ListTile(
                leading: CircleAvatar(child: Text(student['full_name'][0])),
                title: Text(student['full_name']),
                subtitle: Text(
                  "Status: ${status.toUpperCase()}",
                  style: TextStyle(
                    color: status == 'present' ? Colors.green : (status == 'excused' ? Colors.orange : Colors.red),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mark Present
                    IconButton(
                      icon: Icon(Icons.check_circle, color: status == 'present' ? Colors.green : Colors.grey),
                      onPressed: () => _updateStudentStatus(student['student_id'], status == 'present' ? null : 'present'),
                    ),
                    // Mark Excused
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: status == 'excused' ? Colors.orange : Colors.grey),
                      onPressed: () => _updateStudentStatus(student['student_id'], status == 'excused' ? null : 'excused'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
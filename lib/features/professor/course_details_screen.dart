// lib/features/professor/course_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_n_mark/main.dart';
import 'professor_roster_screen.dart';
import 'session_attendance_screen.dart';
import 'generate_qr_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isCodeVisible = false;

  Future<void> _deleteSession(String sessionId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Session?"),
        content: const Text("Permanently delete this session and all its records?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('sessions').delete().eq('id', sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String entryCode = widget.course['code'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text("Course Management")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.course['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- ENTRY CODE ---
            const Text("STUDENT ENTRY CODE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_isCodeVisible ? entryCode : "••••••••",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: _isCodeVisible ? 2 : 4)),
                  ),
                  IconButton(
                    icon: Icon(_isCodeVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isCodeVisible = !_isCodeVisible),
                  ),
                  if (_isCodeVisible)
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: entryCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- HISTORY HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("SESSION HISTORY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfessorRosterScreen(courseId: widget.course['id'], courseName: widget.course['name']))),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text("Roster Stats"),
                ),
              ],
            ),

            // --- SESSION LIST ---
            Expanded(
              child: StreamBuilder(
                stream: supabase.from('sessions').stream(primaryKey: ['id']).eq('course_id', widget.course['id']).order('created_at'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final sessions = snapshot.data!;

                  if (sessions.isEmpty) return const Center(child: Text("No sessions found."));

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final date = DateTime.parse(session['created_at']).toLocal();
                      final dateLabel = "${date.day}/${date.month}/${date.year}";
                      final timeLabel = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            session['is_active'] ? Icons.qr_code_scanner : Icons.history,
                            color: session['is_active'] ? Colors.green : Colors.grey,
                          ),
                          title: Text(session['name'] ?? "Lecture"),
                          subtitle: Text("$dateLabel at $timeLabel"),
                          trailing: session['is_active']
                              ? const Chip(label: Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green)
                              : IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteSession(session['id'])),
                          onTap: () {
                            if (session['is_active']) {
                              // Re-open QR Screen
                              Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateQrScreen(
                                courseId: widget.course['id'],
                                courseName: widget.course['name'],
                                customRadius: session['radius_meters'] ?? 50,
                                sessionName: session['name'] ?? "Lecture",
                                existingSessionId: session['id'], // Pass the ID
                              )));
                            } else {
                              // Go to Attendance Report
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SessionAttendanceScreen(
                                sessionId: session['id'],
                                courseId: widget.course['id'],
                                dateLabel: "$dateLabel $timeLabel",
                              )));
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/features/student/widgets/enrollment_card.dart
import 'package:flutter/material.dart';
import 'package:map_n_mark/main.dart';

class EnrollmentCard extends StatelessWidget {
  final String courseId;

  const EnrollmentCard({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supabase.from('courses').select().eq('id', courseId).single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: ListTile(title: Text("Loading course...")));
        }

        final course = snapshot.data!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: const Icon(Icons.book, color: Colors.deepPurple),
            ),
            title: Text(
              course['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: const Text("Tap to view attendance options"),
            trailing: const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
            onTap: () {
              // This is where we will go to the Scan Screen later
            },
          ),
        );
      },
    );
  }
}
// lib/features/student/student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'sections/student_courses_section.dart';
import 'sections/student_scan_section.dart';
import 'sections/student_stats_section.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _sections = [
    const StudentCoursesSection(),
    const StudentScanSection(),
    const StudentStatsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "My Enrolled Courses" : (_selectedIndex == 1 ? "Scan Attendance" : "My Statistics")),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.deepPurple,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: "My Courses"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: "Stats"),
        ],
      ),
    );
  }
}
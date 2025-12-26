// lib/features/professor/professor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'sections/course_section.dart';
import 'sections/generate_section.dart';
import 'sections/stats_section.dart';

class ProfessorHomeScreen extends ConsumerStatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  ConsumerState<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends ConsumerState<ProfessorHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _sections = [
    const ProfessorCoursesSection(),
    const ProfessorGenerateSection(),
    const ProfessorStatsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "My Courses" : (_selectedIndex == 1 ? "Start Attendance" : "Statistics")),
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
          BottomNavigationBarItem(icon: Icon(Icons.class_outlined), label: "Courses"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Generate"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: "Stats"),
        ],
      ),
    );
  }
}
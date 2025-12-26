// lib/features/professor/sections/stats_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this
import 'package:fl_chart/fl_chart.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/attendance_service.dart'; // Add this

class ProfessorStatsSection extends ConsumerStatefulWidget {
  const ProfessorStatsSection({super.key});

  @override
  ConsumerState<ProfessorStatsSection> createState() => _ProfessorStatsSectionState();
}

class _ProfessorStatsSectionState extends ConsumerState<ProfessorStatsSection> {
  String? _courseId;

  @override
  Widget build(BuildContext context) {
    // 1. Watch the global course stream
    final coursesAsync = ref.watch(professorCoursesProvider);

    return Scaffold(
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text("No courses available for statistics."));
          }

          // 2. Logic: Ensure the selected ID is still valid
          final List<String> availableIds = courses.map((e) => e['id'] as String).toList();
          if (_courseId == null || !availableIds.contains(_courseId)) {
            _courseId = availableIds[0];
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh the global provider and local FutureBuilders
              ref.refresh(professorCoursesProvider);
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // --- COURSE SELECTOR ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      value: _courseId,
                      decoration: const InputDecoration(
                          labelText: "Select Course",
                          border: OutlineInputBorder()
                      ),
                      items: courses.map((e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['name'])
                      )).toList(),
                      onChanged: (v) => setState(() => _courseId = v),
                    ),
                  ),

                  if (_courseId != null) ...[
                    const Text("Weekly Presence (Students)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),

                    // --- BAR CHART ---
                    SizedBox(
                      height: 200,
                      //padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FutureBuilder(
                        key: ValueKey("chart_$_courseId"),
                        future: supabase.rpc('get_weekly_attendance_stats',
                            params: {'input_course_id': _courseId}),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Center(child: Text("Chart error"));
                          if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());

                          final data = snapshot.data as List<dynamic>;
                          if (data.isEmpty) return const Center(child: Text("No data yet", style: TextStyle(fontSize: 12)));

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 50,
                              barGroups: data.asMap().entries.map((e) {
                                return BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (e.value['present_count'] as num).toDouble(),
                                      color: Colors.deepPurple,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text("W${value.toInt() + 1}", style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          );
                        },
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),

                    // --- ROSTER LIST ---
                    const Text("STUDENT RANKING",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),

                    FutureBuilder(
                      key: ValueKey("list_$_courseId"),
                      future: supabase.rpc('get_course_roster_stats',
                          params: {'input_course_id': _courseId}),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final list = snapshot.data as List<dynamic>;
                        list.sort((a, b) => (b['attendance_percentage'] as num)
                            .compareTo(a['attendance_percentage'] as num));

                        return ListView.builder(
                          shrinkWrap: true, // Needed inside SingleChildScrollView
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final s = list[index];
                            final double percent = (s['attendance_percentage'] as num).toDouble();
                            final int attended = (s['total_attended'] as num).toInt();
                            final int total = (s['total_sessions_counted'] as num).toInt();

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(child: Text("${index + 1}")),
                                title: Text(s['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Attended $attended / $total"),
                                trailing: Text(
                                  "${percent.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: percent < 75 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Space for FAB/BottomBar
                  ]
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
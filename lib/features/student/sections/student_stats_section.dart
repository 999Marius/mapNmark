// lib/features/student/sections/student_stats_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/attendance_service.dart';

class StudentStatsSection extends ConsumerStatefulWidget {
  const StudentStatsSection({super.key});
  @override
  ConsumerState<StudentStatsSection> createState() => _StudentStatsSectionState();
}

class _StudentStatsSectionState extends ConsumerState<StudentStatsSection> {
  String? _courseId;

  @override
  Widget build(BuildContext context) {
    final enrollAsync = ref.watch(studentEnrollmentsProvider);

    return enrollAsync.when(
      data: (list) {
        if (list.isEmpty) return const Center(child: Text("No courses joined."));
        final ids = list.map((e) => e['course_id'] as String).toList();
        if (_courseId == null || !ids.contains(_courseId)) _courseId = ids[0];

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(studentEnrollmentsProvider);
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: supabase.from('courses').select('id, name').inFilter('id', ids),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox();
                    return Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                            value: _courseId,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Performance Stats"),
                            items: snap.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                            onChanged: (v) => setState(() => _courseId = v)
                        )
                    );
                  },
                ),
                if (_courseId != null) FutureBuilder(
                    key: ValueKey(_courseId),
                    future: supabase.rpc('get_student_course_stats', params: {'input_student_id': supabase.auth.currentUser!.id, 'input_course_id': _courseId}),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();

                      final stats = snap.data[0];
                      final double attendedPct = (stats['attendance_percentage'] as num).toDouble();

                      // 1. CALCULATE BOTH PERCENTAGES
                      final double absentPct = (100 - attendedPct).clamp(0, 100);

                      return Column(children: [
                        const SizedBox(height: 20),
                        SizedBox(
                            height: 250, // Slightly taller to fit titles
                            child: PieChart(
                                PieChartData(
                                    sectionsSpace: 2, // Small gap between slices
                                    centerSpaceRadius: 40,
                                    sections: [
                                      // SECTION: ATTENDED
                                      PieChartSectionData(
                                          value: attendedPct,
                                          color: attendedPct >= 75 ? Colors.green : Colors.red,
                                          title: "${attendedPct.toStringAsFixed(1)}%",
                                          radius: 65,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                                      ),
                                      // SECTION: ABSENT (Now showing percentage)
                                      PieChartSectionData(
                                          value: absentPct,
                                          color: Colors.grey[300],
                                          title: absentPct > 0 ? "${absentPct.toStringAsFixed(1)}%" : "",
                                          radius: 55,
                                          titleStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)
                                      )
                                    ]
                                )
                            )
                        ),
                        const SizedBox(height: 20),
                        // Summary Text
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat("Attended", stats['total_attended'].toString(), Colors.green),
                              _buildMiniStat("Total Held", stats['total_sessions_counted'].toString(), Colors.blueGrey),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ]);
                    }
                )
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text("Error: $e"),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
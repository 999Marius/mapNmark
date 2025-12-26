// lib/features/professor/sections/generate_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/attendance_service.dart'; // Add this
import '../generate_qr_screen.dart';

class ProfessorGenerateSection extends ConsumerStatefulWidget {
  const ProfessorGenerateSection({super.key});

  @override
  ConsumerState<ProfessorGenerateSection> createState() => _ProfessorGenerateSectionState();
}

class _ProfessorGenerateSectionState extends ConsumerState<ProfessorGenerateSection> {
  double _radius = 50.0;
  LatLng _currentPosition = const LatLng(0, 0);
  bool _isLoadingLocation = true;
  String? _selectedCourseId;
  final MapController _mapController = MapController();
  final TextEditingController _sessionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  // Purely handles the GPS location
  Future<void> _loadLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });

      // Move map to the user
      _mapController.move(_currentPosition, 16.0);
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
      debugPrint("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the global course list
    final coursesAsync = ref.watch(professorCoursesProvider);

    return Scaffold(
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text("Create a course in the 'Courses' tab first."));
          }

          // 2. Sync Logic: Ensure selected ID is valid if courses were deleted
          final List<String> availableIds = courses.map((e) => e['id'] as String).toList();
          if (_selectedCourseId == null || !availableIds.contains(_selectedCourseId)) {
            _selectedCourseId = availableIds[0];
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh both the GPS and the Course list
              await _loadLocation();
              return ref.refresh(professorCoursesProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Select Course", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: courses.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name'])
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCourseId = v),
                  ),

                  const SizedBox(height: 16),

                  const Text("2. Session Name (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sessionNameController,
                    decoration: const InputDecoration(
                      hintText: "e.g. Week 1: Introduction",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text("3. Geofence Radius: ${_radius.toInt()}m",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                      value: _radius,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: "${_radius.toInt()}m",
                      onChanged: (v) => setState(() => _radius = v)
                  ),

                  // --- THE MAP ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 250,
                      child: _isLoadingLocation
                          ? const Center(child: CircularProgressIndicator())
                          : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition,
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.map_n_mark',
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _currentPosition,
                                radius: _radius,
                                useRadiusInMeter: true,
                                color: Colors.blue.withOpacity(0.3),
                                borderColor: Colors.blue,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedCourseId == null) return;
                        Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateQrScreen(
                          courseId: _selectedCourseId!,
                          courseName: courses.firstWhere((c) => c['id'] == _selectedCourseId)['name'],
                          customRadius: _radius.toInt(),
                          sessionName: _sessionNameController.text.trim(),
                        )));
                      },
                      icon: const Icon(Icons.qr_code, size: 28),
                      label: const Text("GENERATE ATTENDANCE QR", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 50), // Extra space for scrolling
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
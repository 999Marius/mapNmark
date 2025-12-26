import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_n_mark/main.dart';
import 'package:map_n_mark/services/attendance_service.dart';
import '../scan_qr_screen.dart';

class StudentScanSection extends ConsumerStatefulWidget {
  const StudentScanSection({super.key});
  @override
  ConsumerState<StudentScanSection> createState() => _StudentScanSectionState();
}

class _StudentScanSectionState extends ConsumerState<StudentScanSection> {
  LatLng? _userPos; // Changed to nullable to detect when ready
  LatLng? _sessionPos;
  double _radius = 0;
  String? _selectedId;
  final MapController _mapController = MapController(); // Added MapController

  @override
  void initState() {
    super.initState();
    _initLoc();
  }

  Future<void> _initLoc() async {
    try {
      // Get current position with high accuracy
      Position p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (mounted) {
        setState(() {
          _userPos = LatLng(p.latitude, p.longitude);
        });

        // MANUALLY move the map to the student's location
        _mapController.move(_userPos!, 16.0);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _checkSession(String id) async {
    final s = await supabase.from('sessions').select().eq('course_id', id).eq('is_active', true).maybeSingle();
    if (mounted) {
      setState(() {
        _sessionPos = s != null ? LatLng(s['latitude'], s['longitude']) : null;
        _radius = s != null ? (s['radius_meters'] as num).toDouble() : 0;
      });

      // If a session exists, you might want to center the map on the classroom instead
      if (_sessionPos != null) {
        _mapController.move(_sessionPos!, 16.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrollAsync = ref.watch(studentEnrollmentsProvider);

    return enrollAsync.when(
      data: (list) {
        if (list.isEmpty) return const Center(child: Text("Join a course to scan."));

        final ids = list.map((e) => e['course_id'] as String).toList();
        if (_selectedId == null || !ids.contains(_selectedId)) {
          _selectedId = ids[0];
          _checkSession(_selectedId!);
        }

        // Show a loader until the first GPS fix is found
        if (_userPos == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Locating you on the map..."),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase.from('courses').select('id, name').inFilter('id', ids),
                builder: (context, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: _selectedId,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Scan for..."),
                    items: snap.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedId = v);
                      _checkSession(v!);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController, // Connect the controller
                    options: MapOptions(
                      initialCenter: _userPos!, // Now safe to use !
                      initialZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.map_n_mark',
                      ),
                      // The Professor's Geofence Circle (Green)
                      if (_sessionPos != null)
                        CircleLayer(circles: [
                          CircleMarker(
                            point: _sessionPos!,
                            radius: _radius,
                            useRadiusInMeter: true,
                            color: Colors.green.withOpacity(0.2),
                            borderColor: Colors.green,
                            borderStrokeWidth: 2,
                          )
                        ]),
                      // Student Location Marker (Blue)
                      MarkerLayer(markers: [
                        Marker(
                            point: _userPos!,
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)
                        ),
                        // Professor's Location Marker (Red)
                        if (_sessionPos != null)
                          Marker(
                            point: _sessionPos!,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanQrScreen())),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("OPEN SCANNER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  )
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }
}
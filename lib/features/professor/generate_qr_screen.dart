import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_n_mark/main.dart';

class GenerateQrScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const GenerateQrScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String? _sessionId;
  bool _isLoading = false;
  String? _errorMessage;

  // 1. Get Location and Create Session
  Future<void> _createSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // A. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      // B. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // C. Define Expiry (e.g., this QR code is valid for 60 minutes)
      final expiryTime = DateTime
          .now()
          .add(const Duration(minutes: 60))
          .toIso8601String();

      // D. Insert into Supabase with NEW COLUMNS
      final data = await supabase
          .from('sessions')
          .insert({
        'course_id': widget.courseId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'radius_meters': 50, // NEW: Set the geofence radius
        'expires_at': expiryTime, // NEW: Set when the session ends
        'is_active': true,
      })
          .select('id')
          .single();

      if (mounted) {
        setState(() {
          _sessionId = data['id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;
    try {
      await supabase
          .from('sessions')
          .update({'is_active': false})
          .eq('id', _sessionId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error ending session: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance: ${widget.courseName}')),
      body: SingleChildScrollView( // Added scroll view to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sessionId == null && !_isLoading) ...[
                // ... (Keep your existing Start Session UI here)
                const Icon(Icons.location_on, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('Start Attendance Session',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _createSession,
                    child: const Text('Generate QR Code'),
                  ),
                ),
                if (_errorMessage != null)
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
              ]
              else
                if (_isLoading) ...[
                  const SizedBox(height: 100),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Getting location & creating session...'),
                ]
                else
                  ...[
                    // SESSION IS ACTIVE - SHOW QR AND LIVE LIST
                    const Text('Scan to Mark Attendance',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.3),
                              blurRadius: 10)
                        ],
                      ),
                      child: QrImageView(
                        data: _sessionId!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LIVE ATTENDANCE MONITOR
                    const Divider(),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('attendance_records')
                          .stream(primaryKey: ['id'])
                          .eq('session_id', _sessionId!),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Column(
                          children: [
                            Text('Students Present: $count',
                                style: const TextStyle(fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            const SizedBox(height: 12),

                            // List of recent check-ins
                            Container(
                              height: 150, // Constrain height for the list
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: snapshot.data == null ||
                                  snapshot.data!.isEmpty
                                  ? const Center(
                                  child: Text("Waiting for first student..."))
                                  : ListView.builder(
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final record = snapshot.data![index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    title: const Text("Student Checked In"),
                                    trailing: Text(
                                        "${record['distance_verified']
                                            ?.toStringAsFixed(1)}m"),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: _endSession,
                      child: const Text('End Session'),
                    ),
                  ],
            ],
          ),
        ),
      ),
    );
  }
}
// lib/features/professor/generate_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_n_mark/main.dart';

class GenerateQrScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  final int customRadius;
  final String sessionName;
  final String? existingSessionId; // New: To re-open live sessions

  const GenerateQrScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.customRadius,
    required this.sessionName,
    this.existingSessionId,
  });

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String? _sessionId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If we passed an existing ID (from History), set it immediately to show QR
    if (widget.existingSessionId != null) {
      _sessionId = widget.existingSessionId;
    }
  }

  Future<void> _createSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final expiryTime = DateTime.now()
          .add(const Duration(minutes: 60))
          .toIso8601String();

      final data = await supabase.from('sessions').insert({
        'course_id': widget.courseId,
        'name': widget.sessionName.isEmpty ? "Lecture" : widget.sessionName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'radius_meters': widget.customRadius,
        'expires_at': expiryTime,
        'is_active': true,
      }).select('id').single();

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
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('sessions')
          .update({'is_active': false})
          .eq('id', _sessionId!)
          .select();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sessionId == null && !_isLoading) ...[
                const Icon(Icons.location_on, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('Start Attendance Session',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Session: ${widget.sessionName}", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                Text("Radius: ${widget.customRadius}m", style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ] else if (_isLoading) ...[
                const SizedBox(height: 100),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Processing...'),
              ] else ...[
                Text(widget.sessionName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("Attendance is live", style: TextStyle(color: Colors.green)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: QrImageView(
                    data: _sessionId!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 24),
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: snapshot.data == null || snapshot.data!.isEmpty
                              ? const Center(child: Text("Waiting for first student..."))
                              : ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final record = snapshot.data![index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: const Text("Student Checked In"),
                                trailing: Text("${record['distance_verified']?.toStringAsFixed(1)}m"),
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
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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